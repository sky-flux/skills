import { config } from "./config";
import { logger } from "./logger";

function buildArgs(extra: string[] = []): string[] {
  const args = ["--json"];
  if (config.account) args.push("--account", config.account);
  if (config.store) args.push("--store", config.store);
  args.push(...extra);
  return args;
}

export async function runWacli(extra: string[], input?: string): Promise<string> {
  const args = buildArgs(extra);
  logger.debug("Running wacli:", config.wacliPath, args.join(" "));

  const proc = Bun.spawn([config.wacliPath, ...args], {
    stdin: input ? new Blob([input]) : undefined,
    stdout: "pipe",
    stderr: "pipe",
  });

  const [stdout, stderr] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
  ]);

  const exitCode = await proc.exited;
  if (exitCode !== 0) {
    logger.error(`wacli failed (${exitCode}):`, stderr || stdout);
    throw new Error(`wacli failed: ${stderr || stdout}`);
  }

  return stdout.trim();
}

export async function sendTextMessage(to: string, message: string): Promise<void> {
  await runWacli([
    "send",
    "text",
    "--to",
    to,
    "--message",
    message,
    "--timeout",
    "5m",
  ]);
}

export async function listMessagesFromThem(chatJid: string, limit: number): Promise<unknown[]> {
  const output = await runWacli([
    "--read-only",
    "messages",
    "list",
    "--chat",
    chatJid,
    "--from-them",
    "--limit",
    String(limit),
  ]);

  try {
    return JSON.parse(output) as unknown[];
  } catch {
    return [];
  }
}

export async function getContactName(jid: string): Promise<string | undefined> {
  try {
    const output = await runWacli(["--read-only", "contacts", "show", "--jid", jid]);
    const data = JSON.parse(output) as { name?: string; pushName?: string };
    return data.name || data.pushName;
  } catch {
    return undefined;
  }
}

export function startSyncWebhook(webhookUrl: string): { process: Subprocess; stop: () => void } {
  const args = buildArgs(["sync", "--webhook", webhookUrl]);
  logger.info("Starting wacli sync webhook:", config.wacliPath, args.join(" "));

  const proc = Bun.spawn([config.wacliPath, ...args], {
    stdout: "pipe",
    stderr: "pipe",
  });

  (async () => {
    for await (const line of proc.stdout) {
      logger.debug("[wacli stdout]", line);
    }
  })();

  (async () => {
    for await (const line of proc.stderr) {
      logger.debug("[wacli stderr]", line);
    }
  })();

  proc.exited.then((code) => {
    logger.warn("wacli sync exited with code:", code);
  });

  return {
    process: proc,
    stop: () => {
      proc.kill();
    },
  };
}

export interface WacliMessageEvent {
  type: "message";
  message: {
    id: string;
    chat?: string;
    sender?: string;
    fromMe?: boolean;
    type?: string;
    text?: string;
    timestamp?: string;
    [key: string]: unknown;
  };
}

export function parseWebhookEvent(body: unknown): WacliMessageEvent | null {
  if (typeof body !== "object" || body === null) return null;
  const ev = body as { type?: string; message?: unknown };
  if (ev.type !== "message" || !ev.message) return null;
  return ev as WacliMessageEvent;
}
