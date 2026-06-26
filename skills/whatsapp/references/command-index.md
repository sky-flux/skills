# wacli 命令索引

本文件是 `wacli` 子命令的唯一真实来源。当 `wacli --help` 输出变化时，必须先更新本文件。

## 格式说明

每行格式：`subcommand [flags]` | 分类 | 参考文件 | 备注

## 索引

| 命令 | 分类 | 参考文件 | 备注 |
|------|------|----------|------|
| `auth` | 写 | `auth-sync.md` | 交互式，不加 `--json` |
| `auth --phone <NUMBER>` | 写 | `auth-sync.md` | 电话码配对 |
| `auth status` | 读 | `auth-sync.md` | `--read-only` |
| `auth logout` | 写 | `auth-sync.md` | |
| `accounts list` | 读 | `auth-sync.md` | `--read-only` |
| `accounts show <NAME>` | 读 | `auth-sync.md` | `--read-only`；`NAME` 位置参数 |
| `accounts add <NAME> [--store <DIR>]` | 写 | `auth-sync.md` | `NAME` 位置参数 |
| `accounts remove <NAME>` | 写 | `auth-sync.md` | |
| `accounts use <NAME>` | 写 | `auth-sync.md` | |
| `sync` | 写 | `auth-sync.md` | 默认 `--follow` |
| `sync --once` | 写 | `auth-sync.md` | |
| `sync --refresh-contacts` | 写 | `auth-sync.md` | |
| `sync --refresh-groups` | 写 | `auth-sync.md` | |
| `sync --refresh-channels` | 写 | `auth-sync.md` | |
| `sync --download-media` | 写 | `auth-sync.md` | |
| `sync --webhook <URL>` | 写 | `auth-sync.md` | |
| `history coverage --chat <CHAT>` | 读 | `auth-sync.md` | `--read-only` |
| `history fill --chat <CHAT> --dry-run` | 读 | `auth-sync.md` | `--read-only` |
| `history backfill --chat <CHAT>` | 写 | `auth-sync.md` | `--timeout 5m` |
| `history fill --chat <CHAT>` | 写 | `auth-sync.md` | `--timeout 5m` |
| `send text --to <RECIPIENT> --message <TEXT>` | 写 | `send.md` | `--timeout 5m` |
| `send file --to <RECIPIENT> --file <PATH>` | 写 | `send.md` | 发送前验证文件 |
| `send sticker --to <RECIPIENT> --file <PATH>` | 写 | `send.md` | |
| `send voice --to <RECIPIENT> --file <PATH>` | 写 | `send.md` | |
| `send react --to <RECIPIENT> --id <MSG_ID> --reaction <EMOJI>` | 写 | `send.md` | |
| `send poll --to <RECIPIENT> --question <QUESTION> --option <OPTION>...` | 写 | `send.md` | 重复 `--option` |
| `send status --text <TEXT>` / `--file <PATH>` | 写 | `send.md` | |
| `send select --to <RECIPIENT> --id <MSG_ID> --label <TEXT>` | 写 | `send.md` | 也可用 `--button-id` 或 `--index` |
| `poll vote --to <CHAT> --id <MSG_ID> --option <OPTION>` | 写 | `send.md` | |
| `polls list` | 读 | `send.md` | `--read-only`；无 `--to` |
| `messages search <QUERY>` | 读 | `messages.md` | `--read-only` |
| `messages list` | 读 | `messages.md` | `--read-only` |
| `messages show --chat <CHAT> --id <MSG_ID>` | 读 | `messages.md` | `--read-only` |
| `messages context --chat <CHAT> --id <MSG_ID>` | 读 | `messages.md` | `--read-only` |
| `messages export [--chat <CHAT>] --output <PATH>` | 读 | `messages.md` | `--read-only` |
| `messages starred` | 读 | `messages.md` | `--read-only` |
| `messages edit --chat <CHAT> --id <MSG_ID> --message <TEXT>` | 写 | `messages-mutate.md` | |
| `messages delete --chat <CHAT> --id <MSG_ID>` | 写 | `messages-mutate.md` | |
| `messages revoke --chat <CHAT> --id <MSG_ID>` | 写 | `messages-mutate.md` | |
| `messages forward --chat <CHAT> --id <MSG_ID> --to <RECIPIENT>` | 写 | `messages-mutate.md` | |
| `contacts search <QUERY>` | 读 | `addressbook.md` | `--read-only` |
| `contacts show --jid <JID>` | 读 | `addressbook.md` | `--read-only` |
| `contacts alias set/rm --jid <JID>` | 写 | `addressbook.md` | |
| `contacts tags add/rm --jid <JID> --tag <TAG>` | 写 | `addressbook.md` | `--tag` singular |
| `contacts import-system` | 写 | `addressbook.md` | |
| `contacts refresh` | 写 | `addressbook.md` | |
| `chats list` | 读 | `addressbook.md` | `--read-only` |
| `chats show --jid <CHAT>` | 读 | `addressbook.md` | `--read-only` |
| `chats archive/unarchive --chat <CHAT>` | 写 | `addressbook.md` | |
| `chats pin/unpin --chat <CHAT>` | 写 | `addressbook.md` | |
| `chats mute/unmute --chat <CHAT>` | 写 | `addressbook.md` | |
| `chats mark-read/mark-unread --chat <CHAT>` | 写 | `addressbook.md` | |
| `chats cleanup --chat <CHAT>` | 写 | `addressbook.md` | |
| `groups list` | 读 | `addressbook.md` | `--read-only` |
| `groups requests list --jid <GID>` | 读 | `addressbook.md` | `--read-only` |
| `groups create/rename/topic/description/announce-only/locked` | 写 | `addressbook.md` | |
| `groups participants add/remove/promote/demote --jid <GID> --user <JID>` | 写 | `addressbook.md` | `--user` singular |
| `groups requests approve/reject --jid <GID> --user <JID>` | 写 | `addressbook.md` | |
| `groups invite link get/revoke --jid <GID>` | 写 | `addressbook.md` | |
| `groups join/leave/prune/refresh/info` | 写 | `addressbook.md` | `--jid` |
| `channels list/info/join/leave` | 写 | `addressbook.md` | `--jid` |
| `calls list` | 读 | `calls.md` | `--read-only` |
| `media download --chat <CHAT> --id <MSG_ID> --output <PATH>` | 读 | `send.md` / `messages.md` | 显式 `--output` 外部路径为读 |
| `media download --chat <CHAT> --id <MSG_ID>` | 写 | `send.md` / `messages.md` | 默认 store media 目录输出 |
| `profile business/get-about/picture-info --jid <JID>` | 写 | `profile-presence.md` | 禁止 `--read-only` |
| `profile remove-picture` | 写 | `profile-presence.md` | |
| `profile set-about --about <TEXT>` | 写 | `profile-presence.md` | |
| `profile set-name --name <NAME>` | 写 | `profile-presence.md` | |
| `profile set-picture <PATH>` | 写 | `profile-presence.md` | `<PATH>` 位置参数 |
| `presence typing/paused --to <RECIPIENT>` | 写 | `profile-presence.md` | |
| `doctor` | 读 | `profile-presence.md` | `--read-only` |
| `doctor --connect` | 写 | `profile-presence.md` | |
| `store stats` | 读 | `profile-presence.md` | `--read-only` |
| `store cleanup --dry-run` | 读 | `profile-presence.md` | `--read-only` |
| `store cleanup` | 写 | `profile-presence.md` | |
| `version` | 读 | `profile-presence.md` | `--read-only` |

## 维护检查清单

每次 `wacli` 发版后：

1. 运行 `wacli --help` 并导出。
2. 与本索引逐行对比。
3. 更新新增、删除、标志变化的条目。
4. 同步更新对应 `references/*.md` 文件。
