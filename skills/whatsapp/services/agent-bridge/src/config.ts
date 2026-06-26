import { homedir } from "os";
import { join } from "path";

export type Mode = "auto" | "manual";

export interface Config {
  port: number;
  webhookPath: string;
  mode: Mode;
  wacliPath: string;
  account?: string;
  store?: string;
  aiProvider: "claude" | "kimi" | "codex" | "opcode" | "api" | "mock";
  aiCommand?: string;
  aiApiUrl?: string;
  aiApiKey?: string;
  aiModel?: string;
  autoReplyWhitelist: string[];
  autoReplyBlacklist: string[];
  maxAutoRepliesPerMinute: number;
  dbPath: string;
  draftsPath: string;
  logLevel: "debug" | "info" | "warn" | "error";
  systemPrompt: string;
  fallbackReply: string;
}

function envBool(key: string, def: boolean): boolean {
  const v = process.env[key];
  if (v === undefined) return def;
  return v === "1" || v === "true" || v === "yes";
}

function envNumber(key: string, def: number): number {
  const v = process.env[key];
  if (v === undefined) return def;
  const n = Number(v);
  return Number.isNaN(n) ? def : n;
}

function envString(key: string, def: string): string {
  return process.env[key] || def;
}

function envArray(key: string): string[] {
  const v = process.env[key];
  if (!v) return [];
  return v.split(",").map((s) => s.trim()).filter(Boolean);
}

const dataDir = envString("WAB_DATA_DIR", join(homedir(), ".whatsapp-agent-bridge"));

export const config: Config = {
  port: envNumber("WAB_PORT", 8787),
  webhookPath: envString("WAB_WEBHOOK_PATH", "/whatsapp-webhook"),
  mode: (envString("WAB_MODE", "manual") as Mode) === "auto" ? "auto" : "manual",
  wacliPath: envString("WAB_WACLI_PATH", "wacli"),
  account: process.env.WAB_ACCOUNT,
  store: process.env.WAB_STORE,
  aiProvider: (envString("WAB_AI_PROVIDER", "mock") as Config["aiProvider"]),
  aiCommand: process.env.WAB_AI_COMMAND,
  aiApiUrl: process.env.WAB_AI_API_URL,
  aiApiKey: process.env.WAB_AI_API_KEY,
  aiModel: process.env.WAB_AI_MODEL,
  autoReplyWhitelist: envArray("WAB_AUTO_REPLY_WHITELIST"),
  autoReplyBlacklist: envArray("WAB_AUTO_REPLY_BLACKLIST"),
  maxAutoRepliesPerMinute: envNumber("WAB_MAX_AUTO_REPLIES_PER_MINUTE", 3),
  dbPath: envString("WAB_DB_PATH", join(dataDir, "bridge.db")),
  draftsPath: envString("WAB_DRAFTS_PATH", join(dataDir, "drafts.jsonl")),
  logLevel: (envString("WAB_LOG_LEVEL", "info") as Config["logLevel"]),
  systemPrompt: envString(
    "WAB_SYSTEM_PROMPT",
    "You are a helpful WhatsApp assistant. Reply in the same language as the user. Keep replies concise, polite, and professional."
  ),
  fallbackReply: envString(
    "WAB_FALLBACK_REPLY",
    "Thanks for your message. We've received it and will get back to you shortly."
  ),
};

export function summary(): Record<string, unknown> {
  return {
    port: config.port,
    webhookPath: config.webhookPath,
    mode: config.mode,
    wacliPath: config.wacliPath,
    aiProvider: config.aiProvider,
    aiCommand: config.aiCommand,
    aiApiUrl: config.aiApiUrl ? "***set***" : undefined,
    aiApiKey: config.aiApiKey ? "***set***" : undefined,
    aiModel: config.aiModel,
    autoReplyWhitelist: config.autoReplyWhitelist,
    autoReplyBlacklist: config.autoReplyBlacklist,
    maxAutoRepliesPerMinute: config.maxAutoRepliesPerMinute,
    dbPath: config.dbPath,
    draftsPath: config.draftsPath,
    logLevel: config.logLevel,
  };
}
