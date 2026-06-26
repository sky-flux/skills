import { Database } from "bun:sqlite";
import { mkdirSync } from "fs";
import { dirname } from "path";
import { config } from "./config";
import { logger } from "./logger";

let db: Database | null = null;

export function initDb(): Database {
  if (db) return db;

  mkdirSync(dirname(config.dbPath), { recursive: true });
  db = new Database(config.dbPath);
  db.exec("PRAGMA journal_mode = WAL;");

  db.exec(`
    CREATE TABLE IF NOT EXISTS contacts (
      jid TEXT PRIMARY KEY,
      first_seen_at TEXT NOT NULL,
      last_message_at TEXT,
      contact_name TEXT,
      is_first_message INTEGER DEFAULT 0,
      auto_reply_count INTEGER DEFAULT 0,
      last_auto_reply_at TEXT
    );
  `);

  db.exec(`
    CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      chat_jid TEXT NOT NULL,
      sender_jid TEXT NOT NULL,
      message_type TEXT,
      text TEXT,
      from_me INTEGER DEFAULT 0,
      timestamp TEXT,
      processed_at TEXT NOT NULL,
      reply_mode TEXT
    );
  `);

  db.exec(`
    CREATE INDEX IF NOT EXISTS idx_messages_chat ON messages(chat_jid);
    CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_jid);
  `);

  logger.info("Database initialized:", config.dbPath);
  return db;
}

export function getDb(): Database {
  if (!db) return initDb();
  return db;
}

export function recordContact(jid: string, contactName?: string): { isFirstMessage: boolean } {
  const db = getDb();
  const now = new Date().toISOString();

  const existing = db.query<{ first_seen_at: string }, [string]>(
    "SELECT first_seen_at FROM contacts WHERE jid = ?"
  ).get(jid);

  if (existing) {
    db.query(
      "UPDATE contacts SET last_message_at = ?, contact_name = COALESCE(?, contact_name) WHERE jid = ?"
    ).run(now, contactName || null, jid);
    return { isFirstMessage: false };
  }

  db.query(
    "INSERT INTO contacts (jid, first_seen_at, last_message_at, contact_name, is_first_message) VALUES (?, ?, ?, ?, ?)"
  ).run(jid, now, now, contactName || null, 1);

  return { isFirstMessage: true };
}

export function recordMessage(
  id: string,
  chatJid: string,
  senderJid: string,
  type: string,
  text: string,
  fromMe: boolean,
  timestamp: string,
  replyMode?: string
): void {
  const db = getDb();
  db.query(
    "INSERT OR IGNORE INTO messages (id, chat_jid, sender_jid, message_type, text, from_me, timestamp, processed_at, reply_mode) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
  ).run(
    id,
    chatJid,
    senderJid,
    type,
    text,
    fromMe ? 1 : 0,
    timestamp,
    new Date().toISOString(),
    replyMode || null
  );
}

export function incrementAutoReplyCount(jid: string): void {
  const db = getDb();
  const now = new Date().toISOString();
  db.query(
    "UPDATE contacts SET auto_reply_count = auto_reply_count + 1, last_auto_reply_at = ? WHERE jid = ?"
  ).run(now, jid);
}

export function getAutoReplyCountInWindow(jid: string, minutes: number): number {
  const db = getDb();
  const since = new Date(Date.now() - minutes * 60 * 1000).toISOString();
  const row = db.query<{ count: number }, [string, string]>(
    "SELECT COUNT(*) as count FROM messages WHERE sender_jid = ? AND reply_mode = 'auto' AND processed_at > ?"
  ).get(jid, since);
  return row?.count || 0;
}

export function getRecentHistory(chatJid: string, limit: number): { text: string; fromMe: boolean; timestamp: string }[] {
  const db = getDb();
  return db.query<{ text: string; from_me: number; timestamp: string }, [string, number]>(
    "SELECT text, from_me, timestamp FROM messages WHERE chat_jid = ? ORDER BY timestamp DESC LIMIT ?"
  ).all(chatJid, limit).map((r) => ({
    text: r.text,
    fromMe: r.from_me === 1,
    timestamp: r.timestamp,
  }));
}
