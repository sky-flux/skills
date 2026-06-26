#!/usr/bin/env python3
"""Deterministic wacli shim for evals.

Reads $MOCK_WACLI_STATE (defaults to 'authenticated') and $MOCK_WACLI_LOCK (defaults to 'unlocked').
Validates flag semantics and returns realistic JSON envelopes.
"""
import json
import os
import sys

STATE = os.environ.get("MOCK_WACLI_STATE", "authenticated")
LOCK = os.environ.get("MOCK_WACLI_LOCK", "unlocked")

READONLY_OK = {
    "messages list", "messages search", "messages show", "messages context",
    "messages export", "messages starred",
    "contacts search", "contacts show",
    "chats list", "chats show",
    "groups list", "groups requests list",
    "calls list",
    "polls list",
    "history coverage", "history fill --dry-run",
    "auth status", "accounts list", "accounts show", "version",
    "doctor", "store stats", "store cleanup --dry-run",
    "media download --output",
}
WRITE_NEVER_READONLY = {
    "send", "poll vote",
    "messages edit", "messages delete", "messages revoke", "messages forward",
    "contacts alias set", "contacts alias rm", "contacts tags",
    "contacts import-system", "contacts refresh",
    "media download",
    "chats archive", "chats unarchive", "chats pin", "chats unpin", "chats mute", "chats unmute",
    "chats mark-read", "chats mark-unread", "chats cleanup",
    "groups info", "groups refresh", "groups create", "groups rename", "groups topic",
    "groups description", "groups announce-only", "groups locked", "groups participants",
    "groups requests approve", "groups requests reject", "groups invite link get",
    "groups invite link revoke", "groups join", "groups leave", "groups prune",
    "channels list", "channels info", "channels join", "channels leave",
    "history backfill", "history fill",
    "sync", "auth", "auth logout", "auth --phone", "accounts add", "accounts remove", "accounts use",
    "presence typing", "presence paused",
    "profile business", "profile get-about", "profile picture-info", "profile remove-picture",
    "profile set-about", "profile set-name", "profile set-picture",
    "doctor --connect", "store cleanup",
}


def fail(error: str):
    print(json.dumps({"success": False, "error": error}))
    sys.exit(1)


def success(data=None):
    print(json.dumps({"success": True, "data": data or {}}))


def parse_args(argv):
    globals_flags = []
    subcommand_parts = []
    read_only = False
    use_json = False
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--json":
            use_json = True
            globals_flags.append(arg)
            i += 1
        elif arg == "--read-only":
            read_only = True
            globals_flags.append(arg)
            i += 1
        elif arg in ("--account", "--store", "--timeout"):
            globals_flags.extend([arg, argv[i + 1]])
            i += 2
        elif arg in ("--full", "--events"):
            globals_flags.append(arg)
            i += 1
        elif arg == "--version":
            success({"version": "0.11.0"})
            sys.exit(0)
        elif not arg.startswith("-"):
            subcommand_parts = argv[i:]
            break
        else:
            subcommand_parts = argv[i:]
            break
    return globals_flags, subcommand_parts, read_only, use_json


def classify(parts):
    if not parts:
        return "unknown"
    base = parts[0]
    if base == "messages" and len(parts) > 1:
        base = f"messages {parts[1]}"
    elif base == "contacts" and len(parts) > 1:
        if parts[1] == "tags" and len(parts) > 2:
            base = f"contacts tags {parts[2]}"
        elif parts[1] == "alias" and len(parts) > 2:
            base = f"contacts alias {parts[2]}"
        else:
            base = f"contacts {parts[1]}"
    elif base == "chats" and len(parts) > 1:
        base = f"chats {parts[1]}"
    elif base == "groups" and len(parts) > 1:
        if parts[1] == "participants" and len(parts) > 2:
            base = f"groups participants"
        elif parts[1] == "requests" and len(parts) > 2:
            base = f"groups requests {parts[2]}"
        elif parts[1] == "invite" and len(parts) > 3:
            base = f"groups invite link {parts[3]}"
        else:
            base = f"groups {parts[1]}"
    elif base == "channels" and len(parts) > 1:
        base = f"channels {parts[1]}"
    elif base == "history" and len(parts) > 1:
        base = f"history {parts[1]}"
        if "--dry-run" in parts:
            base += " --dry-run"
    elif base == "auth" and len(parts) > 1:
        base = f"auth {parts[1]}"
    elif base == "accounts" and len(parts) > 1:
        base = f"accounts {parts[1]}"
    elif base == "profile" and len(parts) > 1:
        base = f"profile {parts[1]}"
    elif base == "presence" and len(parts) > 1:
        base = f"presence {parts[1]}"
    elif base == "store" and len(parts) > 1:
        base = f"store {parts[1]}"
        if "--dry-run" in parts:
            base += " --dry-run"
    elif base == "doctor" and "--connect" in parts:
        base = "doctor --connect"
    elif base == "media" and len(parts) > 1:
        base = f"media {parts[1]}"
        if "--output" in parts:
            base += " --output"
    if base in READONLY_OK:
        return "read"
    if base in WRITE_NEVER_READONLY:
        return "write"
    return "unknown"


def main():
    globals_flags, parts, read_only, use_json = parse_args(sys.argv[1:])

    if not parts:
        fail("missing subcommand")

    kind = classify(parts)

    if STATE != "authenticated" and parts[0] != "auth":
        fail("not authenticated")

    if LOCK == "locked" and parts[0] not in ("sync", "auth"):
        fail("store is locked")

    if kind == "read" and not read_only:
        fail("read-only mode required for query")

    if kind == "write" and read_only:
        fail("read-only mode")

    success({"subcommand": " ".join(parts), "globals": globals_flags})


if __name__ == "__main__":
    main()
