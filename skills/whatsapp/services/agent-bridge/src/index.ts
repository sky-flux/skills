import { config, summary } from "./config";
import { logger } from "./logger";
import { initDb, recordContact, recordMessage, incrementAutoReplyCount, getAutoReplyCountInWindow, getRecentHistory } from "./db";
import { saveDraft, listDrafts, markDraftSent } from "./drafts";
import { generateReply } from "./ai";
import {
  sendTextMessage,
  startSyncWebhook,
  parseWebhookEvent,
  getContactName,
  WacliMessageEvent,
} from "./wacli";
let wacliProc: { stop: () => void } | null = null;

async function handleWebhook(event: WacliMessageEvent): Promise<void> {
  const msg = event.message;

  // 忽略自己发出去的消息，避免循环
  if (msg.fromMe) {
    logger.debug("Ignoring message from me:", msg.id);
    return;
  }

  // 目前只处理文本消息
  if (msg.type !== "text") {
    logger.info("Ignoring non-text message:", msg.type, msg.id);
    return;
  }

  const chatJid = msg.chat || msg.sender || "unknown";
  const senderJid = msg.sender || chatJid;
  const text = msg.text || "";
  const timestamp = msg.timestamp || new Date().toISOString();

  logger.info("Incoming message:", { chatJid, senderJid, text: text.slice(0, 100) });

  // 记录联系人并判断是否是首次消息
  const contactName = await getContactName(senderJid);
  const { isFirstMessage } = recordContact(senderJid, contactName);

  if (isFirstMessage) {
    logger.info("First message from:", senderJid);
  }

  // 黑名单：直接忽略
  if (isBlacklisted(senderJid, chatJid)) {
    logger.info("Sender/chat is blacklisted, ignoring.", { senderJid, chatJid });
    recordMessage(msg.id, chatJid, senderJid, msg.type || "text", text, false, timestamp, "ignored");
    return;
  }

  // 白名单/模式决定如何处理
  const shouldAutoReply = config.mode === "auto" || isWhitelisted(senderJid, chatJid);

  try {
    // 获取最近历史作为上下文
    const history = getRecentHistory(chatJid, 10)
      .reverse()
      .map((h) => `${h.fromMe ? "Me" : "User"}: ${h.text}`)
      .join("\n");

    const reply = await generateReply({
      text,
      sender: senderJid,
      chat: chatJid,
      isFirstMessage,
      chatHistory: history,
      contactName,
    });

    if (!reply) {
      logger.warn("AI returned empty reply, using fallback.");
    }

    const finalReply = reply || config.fallbackReply;

    if (shouldAutoReply) {
      // 速率限制检查
      const recentCount = getAutoReplyCountInWindow(senderJid, 1);
      if (recentCount >= config.maxAutoRepliesPerMinute) {
        logger.warn("Rate limit exceeded for", senderJid, "saving draft instead.");
        await queueDraft(msg.id, chatJid, senderJid, text, finalReply);
        recordMessage(msg.id, chatJid, senderJid, "text", text, false, timestamp, "draft-rate-limit");
        return;
      }

      await sendTextMessage(chatJid, finalReply);
      incrementAutoReplyCount(senderJid);
      recordMessage(msg.id, chatJid, senderJid, "text", text, false, timestamp, "auto");
      logger.info("Auto-reply sent to:", senderJid);
    } else {
      await queueDraft(msg.id, chatJid, senderJid, text, finalReply);
      recordMessage(msg.id, chatJid, senderJid, "text", text, false, timestamp, "draft");
      logger.info("Draft saved for manual review:", senderJid);
    }
  } catch (err) {
    logger.error("Failed to process message:", err);
    recordMessage(msg.id, chatJid, senderJid, "text", text, false, timestamp, "error");
  }
}

async function queueDraft(
  originalMessageId: string,
  chatJid: string,
  senderJid: string,
  originalText: string,
  reply: string
): Promise<void> {
  await saveDraft({
    id: `draft-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    chatJid,
    senderJid,
    originalMessageId,
    originalText,
    reply,
    createdAt: new Date().toISOString(),
  });
}

function isWhitelisted(senderJid: string, chatJid: string): boolean {
  return config.autoReplyWhitelist.some((entry) => senderJid.includes(entry) || chatJid.includes(entry));
}

function isBlacklisted(senderJid: string, chatJid: string): boolean {
  return config.autoReplyBlacklist.some((entry) => senderJid.includes(entry) || chatJid.includes(entry));
}

function startServer() {
  const server = Bun.serve({
    port: config.port,
    async fetch(req) {
      const url = new URL(req.url);
      const path = url.pathname;

      // Health / status
      if (path === "/health" || path === "/") {
        return Response.json({
          ok: true,
          service: "whatsapp-agent-bridge",
          version: "1.0.0",
          mode: config.mode,
          wacliConnected: wacliProc !== null,
          config: summary(),
        });
      }

      // Webhook endpoint
      if (path === config.webhookPath && req.method === "POST") {
        try {
          const body = (await req.json()) as unknown;
          logger.debug("Webhook received:", JSON.stringify(body));
          const event = parseWebhookEvent(body);
          if (event) {
            // 异步处理，不阻塞 webhook 响应
            handleWebhook(event).catch((err) => logger.error("Webhook handler error:", err));
          }
          return new Response("OK", { status: 200 });
        } catch (err) {
          logger.error("Invalid webhook payload:", err);
          return new Response("Bad Request", { status: 400 });
        }
      }

      // List drafts
      if (path === "/drafts" && req.method === "GET") {
        const drafts = await listDrafts();
        return Response.json({ drafts });
      }

      // Send a draft
      if (path === "/drafts/send" && req.method === "POST") {
        try {
          const body = (await req.json()) as { draftId?: string; reply?: string; chatJid?: string };
          const { draftId, reply, chatJid } = body;
          if (!draftId || !reply || !chatJid) {
            return Response.json({ error: "draftId, reply, chatJid required" }, { status: 400 });
          }
          await sendTextMessage(chatJid, reply);
          await markDraftSent(draftId);
          return Response.json({ ok: true });
        } catch (err) {
          logger.error("Failed to send draft:", err);
          return Response.json({ error: String(err) }, { status: 500 });
        }
      }

      // Stats
      if (path === "/stats" && req.method === "GET") {
        const db = initDb();
        const contacts = db.query<{ count: number }, []>("SELECT COUNT(*) as count FROM contacts").get();
        const messages = db.query<{ count: number }, []>("SELECT COUNT(*) as count FROM messages").get();
        const autoCount = db.query<{ count: number }, []>(
          "SELECT COUNT(*) as count FROM messages WHERE reply_mode = 'auto'"
        ).get();
        const draftCount = db.query<{ count: number }, []>(
          "SELECT COUNT(*) as count FROM messages WHERE reply_mode = 'draft'"
        ).get();
        return Response.json({
          contacts: contacts?.count || 0,
          messages: messages?.count || 0,
          autoReplies: autoCount?.count || 0,
          draftsPending: draftCount?.count || 0,
        });
      }

      return new Response("Not Found", { status: 404 });
    },
  });

  logger.info(`WhatsApp Agent Bridge listening on http://127.0.0.1:${config.port}`);
  logger.info(`Webhook endpoint: http://127.0.0.1:${config.port}${config.webhookPath}`);
  logger.info(`Mode: ${config.mode}`);

  return server;
}

function startDaemon() {
  initDb();
  const server = startServer();
  const webhookUrl = `http://127.0.0.1:${config.port}${config.webhookPath}`;
  wacliProc = startSyncWebhook(webhookUrl);

  const shutdown = () => {
    logger.info("Shutting down...");
    if (wacliProc) {
      wacliProc.stop();
      wacliProc = null;
    }
    server.stop();
    process.exit(0);
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

function printHelp() {
  console.log(`
WhatsApp Agent Bridge

Usage: whatsapp-agent-bridge [options]

Options:
  --help, -h       Show this help message
  --version, -v    Show version
  --daemon, -d     Run as background daemon (detached)

Environment variables:
  WAB_MODE                    auto | manual (default: manual)
  WAB_AI_PROVIDER             claude | kimi | codex | opcode | api | mock
  WAB_AI_COMMAND              Custom AI CLI path
  WAB_AI_API_URL              API endpoint for api provider
  WAB_AI_API_KEY              API key for api provider
  WAB_PORT                    HTTP port (default: 8787)
  WAB_AUTO_REPLY_WHITELIST    Comma-separated JID keywords
  WAB_AUTO_REPLY_BLACKLIST    Comma-separated JID keywords
  WAB_DB_PATH                 SQLite path
  WAB_DRAFTS_PATH             Drafts queue path
  WAB_LOG_LEVEL               debug | info | warn | error
`);
}

function printVersion() {
  console.log("whatsapp-agent-bridge v1.0.0");
}

function runAsDaemon() {
  const proc = Bun.spawn([process.execPath, process.argv[1]], {
    detached: true,
    stdout: "inherit",
    stderr: "inherit",
  });
  logger.info("Daemon started with PID:", proc.pid);
  process.exit(0);
}

function main() {
  const args = process.argv.slice(2);

  for (const arg of args) {
    if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    }
    if (arg === "--version" || arg === "-v") {
      printVersion();
      process.exit(0);
    }
    if (arg === "--daemon" || arg === "-d") {
      runAsDaemon();
    }
  }

  startDaemon();
}

main();
