import { config } from "./config";
import { logger } from "./logger";

export interface GenerateContext {
  text: string;
  sender: string;
  chat: string;
  isFirstMessage: boolean;
  chatHistory?: string;
  contactName?: string;
}

export async function generateReply(ctx: GenerateContext): Promise<string> {
  const prompt = buildPrompt(ctx);

  switch (config.aiProvider) {
    case "claude":
      return callClaude(prompt);
    case "kimi":
      return callKimi(prompt);
    case "codex":
      return callCodex(prompt);
    case "opcode":
      return callOpenCode(prompt);
    case "api":
      return callApi(prompt);
    case "mock":
    default:
      return mockReply(ctx);
  }
}

function buildPrompt(ctx: GenerateContext): string {
  const parts = [
    config.systemPrompt,
    "",
    `Sender JID: ${ctx.sender}`,
    `Chat JID: ${ctx.chat}`,
    ctx.isFirstMessage ? "This is the first message from this contact." : "This contact has messaged before.",
    ctx.contactName ? `Contact name: ${ctx.contactName}` : "",
    ctx.chatHistory ? `Recent chat history:\n${ctx.chatHistory}` : "",
    "",
    "User message:",
    ctx.text,
    "",
    "Please generate a concise, helpful reply.",
  ];
  return parts.filter(Boolean).join("\n");
}

async function runCommand(cmd: string, args: string[], input?: string): Promise<string> {
  logger.debug("Running command:", cmd, args.join(" "));
  const proc = Bun.spawn([cmd, ...args], {
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
    logger.error(`AI command failed (${exitCode}):`, stderr || stdout);
    throw new Error(`AI command failed: ${stderr || stdout}`);
  }

  return stdout.trim();
}

async function callClaude(prompt: string): Promise<string> {
  const cmd = config.aiCommand || "claude";
  // Claude Code supports `-p` for prompt mode
  return runCommand(cmd, ["-p", prompt]);
}

async function callKimi(prompt: string): Promise<string> {
  const cmd = config.aiCommand || "kimi";
  // Kimi Code CLI: pipe prompt or use -c
  return runCommand(cmd, ["-c", prompt]);
}

async function callCodex(prompt: string): Promise<string> {
  const cmd = config.aiCommand || "codex";
  // Codex CLI supports ask/quest mode
  return runCommand(cmd, ["-q", prompt]);
}

async function callOpenCode(prompt: string): Promise<string> {
  const cmd = config.aiCommand || "opencode";
  // OpenCode CLI: opencode ask "..."
  return runCommand(cmd, ["ask", prompt]);
}

async function callApi(prompt: string): Promise<string> {
  if (!config.aiApiUrl) {
    throw new Error("WAB_AI_API_URL is required when aiProvider is 'api'");
  }

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };
  if (config.aiApiKey) {
    headers["Authorization"] = `Bearer ${config.aiApiKey}`;
  }

  const body = JSON.stringify({
    model: config.aiModel || "gpt-4o",
    messages: [
      { role: "system", content: config.systemPrompt },
      { role: "user", content: prompt },
    ],
  });

  logger.debug("Calling AI API:", config.aiApiUrl);
  const res = await fetch(config.aiApiUrl, {
    method: "POST",
    headers,
    body,
  });

  if (!res.ok) {
    throw new Error(`AI API error: ${res.status} ${await res.text()}`);
  }

  const data = (await res.json()) as unknown;
  // OpenAI-compatible format
  if (typeof data === "object" && data && "choices" in data) {
    const choices = (data as { choices?: { message?: { content?: string } }[] }).choices;
    return choices?.[0]?.message?.content?.trim() || "";
  }

  // Generic { reply: string }
  if (typeof data === "object" && data && "reply" in data) {
    return String((data as { reply: string }).reply).trim();
  }

  throw new Error("Unknown AI API response format");
}

function mockReply(ctx: GenerateContext): string {
  logger.info("[mock AI] Would reply to:", ctx.text);
  return `[MOCK] Thank you for your message. This is a mock reply. Provider=${config.aiProvider}`;
}
