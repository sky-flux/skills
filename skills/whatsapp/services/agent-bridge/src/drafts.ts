import { mkdirSync } from "fs";
import { dirname } from "path";
import { config } from "./config";
import { logger } from "./logger";

export interface Draft {
  id: string;
  chatJid: string;
  senderJid: string;
  originalMessageId: string;
  originalText: string;
  reply: string;
  createdAt: string;
  sentAt?: string;
}

function ensureDir() {
  mkdirSync(dirname(config.draftsPath), { recursive: true });
}

export async function saveDraft(draft: Draft): Promise<void> {
  ensureDir();
  await Bun.write(config.draftsPath, JSON.stringify(draft) + "\n", { append: true });
  logger.info("Draft saved:", draft.id, "for", draft.chatJid);
}

export async function listDrafts(limit = 50): Promise<Draft[]> {
  try {
    const content = await Bun.file(config.draftsPath).text();
    const lines = content.trim().split("\n").filter(Boolean);
    const drafts = lines
      .map((line) => {
        try {
          return JSON.parse(line) as Draft;
        } catch {
          return null;
        }
      })
      .filter((d): d is Draft => d !== null && !d.sentAt)
      .slice(-limit);
    return drafts.reverse();
  } catch {
    return [];
  }
}

export async function markDraftSent(id: string): Promise<void> {
  try {
    const content = await Bun.file(config.draftsPath).text();
    const lines = content.trim().split("\n").filter(Boolean);
    const updated = lines
      .map((line) => {
        try {
          const d = JSON.parse(line) as Draft;
          if (d.id === id) {
            return JSON.stringify({ ...d, sentAt: new Date().toISOString() });
          }
          return line;
        } catch {
          return line;
        }
      })
      .join("\n");
    await Bun.write(config.draftsPath, updated + "\n");
  } catch (err) {
    logger.error("Failed to mark draft sent:", err);
  }
}
