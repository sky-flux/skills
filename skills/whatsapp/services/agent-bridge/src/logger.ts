import { config } from "./config";

const levels = { debug: 0, info: 1, warn: 2, error: 3 };

function log(level: keyof typeof levels, ...args: unknown[]) {
  if (levels[level] < levels[config.logLevel]) return;
  const ts = new Date().toISOString();
  console[level === "debug" ? "log" : level](`[${ts}] [${level.toUpperCase()}]`, ...args);
}

export const logger = {
  debug: (...args: unknown[]) => log("debug", ...args),
  info: (...args: unknown[]) => log("info", ...args),
  warn: (...args: unknown[]) => log("warn", ...args),
  error: (...args: unknown[]) => log("error", ...args),
};
