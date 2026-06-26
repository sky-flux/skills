# WhatsApp

**English** | [中文](./README.zh-CN.md)

Send messages, search chats, sync history, manage contacts/groups/channels, and download media through the WhatsApp CLI via [`wacli`](https://github.com/openclaw/wacli).

**Core idea:** Natural-language WhatsApp tasks are translated into safe `wacli` invocations, with clear read/write separation and recipient disambiguation.

---

## Installation

```bash
npx skills add sky-flux/skills --skill whatsapp
```

Install globally (available across all projects):

```bash
npx skills add sky-flux/skills --skill whatsapp -g
```

## Prerequisites

- **wacli** — WhatsApp CLI daemon
  ```bash
  which wacli && wacli --version
  ```
  See `references/install.md` for brew / go install / source build instructions.

## Quick Start

Just ask:

```
Send a WhatsApp message to Mom saying I'm on my way
```

Or:

```
Search my WhatsApp chats for "invoice"
```

## How It Works

1. **Trigger detection** — Mentions of WhatsApp, wacli, or implicit messaging tasks activate the skill.
2. **Safety check** — Every command is classified as read or write per `references/safety.md`.
3. **Read operations** automatically append `--read-only`.
4. **Write operations** require a clear recipient; ambiguous names are resolved with `--pick N` or by asking you.
5. **JSON output** is used by default for reliable parsing.
6. **Error handling** follows `references/error-handling.md`: auth failures run `wacli auth`, locked stores retry with `--lock-wait`, ambiguous recipients are confirmed.

## Common Commands

```bash
# Send a message
wacli --json send text --to "+1234567890" --message "Hello"

# Search messages
wacli --json --read-only messages search "meeting"

# List chats
wacli --json --read-only chats list

# Sync history once
wacli --json sync --once

# Download media
wacli --json --read-only media download --chat "+1234567890" --id "<MSG_ID>" --output ./downloads
```

## References

- `references/safety.md` — Read/write command classification
- `references/install.md` — wacli installation guide
- `references/command-index.md` — Full command reference
- `references/error-handling.md` — Error codes and recovery
