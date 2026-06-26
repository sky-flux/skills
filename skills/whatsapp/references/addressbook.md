# 联系人、聊天、群组、频道

## 联系人

读操作：

```bash
wacli --json --read-only contacts search "<QUERY>"
wacli --json --read-only contacts show --jid <JID>
```

写操作：

```bash
wacli --json contacts alias set --jid <JID> --alias "<ALIAS>"
wacli --json contacts alias rm --jid <JID>
wacli --json contacts tags add --jid <JID> --tag "<TAG>"
wacli --json contacts tags rm --jid <JID> --tag "<TAG>"
wacli --json contacts import-system
wacli --json contacts refresh
```

## 聊天

读操作：

```bash
wacli --json --read-only chats list [--limit <N>] [--archived] [--pinned]
wacli --json --read-only chats show --jid <CHAT>
```

写操作：

```bash
wacli --json chats archive --chat <CHAT>
wacli --json chats unarchive --chat <CHAT>
wacli --json chats pin --chat <CHAT>
wacli --json chats unpin --chat <CHAT>
wacli --json chats mute --chat <CHAT> [--duration <DURATION>]
wacli --json chats unmute --chat <CHAT>
wacli --json chats mark-read --chat <CHAT>
wacli --json chats mark-unread --chat <CHAT>
wacli --json chats cleanup --chat <CHAT>
```

## 群组

读操作：

```bash
wacli --json --read-only groups list
wacli --json --read-only groups requests list --jid <GID>
```

写操作：

```bash
wacli --json groups create --name "<NAME>" --user <JID1> --user <JID2>
wacli --json groups info --jid <GID>
wacli --json groups refresh --jid <GID>
wacli --json groups rename --jid <GID> --name "<NEW_NAME>"
wacli --json groups topic --jid <GID> --text "<TOPIC>"
wacli --json groups description --jid <GID> --description "<DESC>"
wacli --json groups announce-only --jid <GID> [--enable|--disable]
wacli --json groups locked --jid <GID> [--enable|--disable]
wacli --json groups participants add --jid <GID> --user <JID>
wacli --json groups participants remove --jid <GID> --user <JID>
wacli --json groups participants promote --jid <GID> --user <JID>
wacli --json groups participants demote --jid <GID> --user <JID>
wacli --json groups requests approve --jid <GID> --user <JID>
wacli --json groups requests reject --jid <GID> --user <JID>
wacli --json groups invite link get --jid <GID>
wacli --json groups invite link revoke --jid <GID>
wacli --json groups join --link "<INVITE_LINK>"
wacli --json groups leave --jid <GID>
wacli --json groups prune --jid <GID>
```

## 频道

写操作（list/info 也会更新本地 DB）：

```bash
wacli --json channels list
wacli --json channels info --jid <NEWSLETTER_JID>
wacli --json channels join --jid <NEWSLETTER_JID>
wacli --json channels leave --jid <NEWSLETTER_JID>
```
