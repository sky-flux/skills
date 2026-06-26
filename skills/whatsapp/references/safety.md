# 安全规则与错误模式

## 读写分类表

| 命令 | 分类 | 备注 |
|------|------|------|
| `auth` | 写 | QR/电话码配对，禁止 `--read-only` |
| `auth status` | 读 | 必须 `--read-only` |
| `accounts add/remove/use <NAME>` | 写 | 禁止 `--read-only`；`NAME` 为位置参数 |
| `accounts list/show <NAME>` | 读 | 必须 `--read-only`；`NAME` 为位置参数 |
| `sync` 及所有变体 | 写 | 包括 `--follow`, `--once`, `--refresh-*`, `--download-media`, `--webhook` |
| `history coverage` | 读 | 必须 `--read-only` |
| `history fill --dry-run` | 读 | 必须 `--read-only` |
| `history backfill` / `history fill` | 写 | 禁止 `--read-only` |
| `send *` | 写 | 禁止 `--read-only` |
| `poll vote` | 写 | 禁止 `--read-only` |
| `polls list` | 读 | 必须 `--read-only` |
| `messages list/search/show/context/export/starred` | 读 | 必须 `--read-only` |
| `messages edit/delete/revoke/forward` | 写 | 禁止 `--read-only` |
| `contacts search/show` | 读 | 必须 `--read-only` |
| `contacts alias/tags/import-system/refresh` | 写 | 禁止 `--read-only` |
| `chats list/show` | 读 | 必须 `--read-only` |
| `chats archive/pin/mute/mark-read/cleanup` | 写 | 禁止 `--read-only` |
| `groups list` / `groups requests list --jid <GID>` | 读 | 必须 `--read-only` |
| `groups *` 其他 | 写 | 禁止 `--read-only`（info/refresh 更新本地 DB） |
| `channels list/info/join/leave` | 写 | list/info 更新本地 DB |
| `calls list` | 读 | 必须 `--read-only` |
| `media download` | 视情况而定 | 默认 store media 目录输出为写；显式 `--output` 外部路径为读 |
| `profile business/get-about/picture-info` | 写 | 禁止 `--read-only`（拉取实时数据） |
| `profile *` 其他 | 写 | 禁止 `--read-only` |
| `presence typing/paused` | 写 | 禁止 `--read-only` |
| `doctor` | 读 | 必须 `--read-only` |
| `doctor --connect` | 写 | 禁止 `--read-only` |
| `store stats` / `store cleanup --dry-run` | 读 | 必须 `--read-only` |
| `store cleanup` | 写 | 禁止 `--read-only` |
| `version` | 读 | 必须 `--read-only` |

## 错误模式与修复

| 错误 | 修复 |
|------|------|
| `not authenticated` | 运行 `wacli auth` |
| `store is locked` | 等待或停止 `wacli sync --follow`；写命令可重试 `--lock-wait 30s` 一次 |
| `ambiguous recipient` | 使用 `--pick N`（1-indexed）或询问用户 |
| `read-only mode` | 写命令移除 `--read-only` |
| `message too old to edit` | 告知用户 WhatsApp 编辑窗口已过期 |
| `file not found` | 发送前用 `test -f <PATH>` 验证 |

## 全局标志顺序

```
wacli [--json] [--read-only] [--account NAME] [--store DIR] [--timeout DURATION] [--full] [--events] <subcommand> ...
```

## 禁止事项

- 不得臆造子命令或标志。
- 不得在写命令上使用 `--read-only`。
- 不得在读命令上省略 `--read-only`。
- 不得用位置参数代替 `--to` / `--jid` / `--chat` / `--id`（`accounts show/add` 和 `profile set-picture` 除外）。
- 不得对默认 store media 目录输出的 `media download` 使用 `--read-only`。
