---
name: whatsapp
description: |
  当用户提到 WhatsApp、wacli、"发 WhatsApp 消息"、"WhatsApp CLI" 时必须使用本 skill。
  也覆盖隐式场景："给妈妈发条消息"、"搜索我的聊天记录"、"备份 WhatsApp"、"列出我的 WhatsApp 群组"、"下载 WhatsApp 媒体"。
  覆盖操作动词：发送、搜索、同步、导出、备份、列出、管理联系人/群组/频道。
  任何可通过 wacli CLI 完成的 WhatsApp 相关任务都应使用本 skill，即使用户没有明确说出 wacli。
triggers:
  - whatsapp
  - wacli
  - "send whatsapp message"
  - "whatsapp cli"
  - "发 WhatsApp"
  - "搜索我的聊天记录"
  - "备份 WhatsApp"
  - "列出 WhatsApp 群组"
  - "下载 WhatsApp 媒体"
scope: project
---

# WhatsApp Skill

本 skill 通过 [`wacli`](https://github.com/openclaw/wacli) CLI 控制 WhatsApp。所有操作必须遵守以下规则。

## 1. 执行前检查清单

每次执行 `wacli` 命令前必须运行以下检查：

1. 查阅 `references/safety.md` 中的读写分类表。未列出的命令运行 `wacli <command> --help`；如果它会向 WhatsApp 发送数据、修改本地 store DB 或拉取实时数据并更新本地 store，则归类为写操作。
2. 读操作追加 `--read-only`；写操作确保 `--read-only` 不存在。
3. 默认追加 `--json`，除非用户明确要求人类可读输出或命令是交互式（如 QR 码 `wacli auth`）。
4. 如果用户指定或之前使用过 `--account NAME` 或 `--store DIR`，则加上。
5. 所有全局标志放在 `wacli` 之后、子命令之前：顺序为 `wacli [--store DIR] [--account NAME] [--json] [--read-only] [--timeout DURATION] [--full] [--events] <subcommand> ...`。
6. 接收方是否明确？如不明确，使用 `--pick N`（N 从 1 开始）或询问用户。
7. 文件路径参数是否存在？发送前用 `ls` / `test -f` 验证。
8. `media download` 与 `--read-only` 一起使用时，必须提供 `--output <PATH>` 且路径在 store media 目录之外。
9. 网络/store 密集型写命令使用 `--timeout 5m`：`send`、`sync`、`history backfill`、`groups info/refresh`、`channels list/info`、`profile *`、`auth`、`accounts add`。轻量写命令使用 `--timeout 1m`：`messages edit/delete/revoke/forward`、`contacts refresh/import-system`、`chats archive/pin/mute`、`groups participants`、`presence`。
10. 写命令因 `store is locked` 失败时，使用 `--lock-wait 30s` 重试一次；仍失败则提示用户停止 `wacli sync` 或换 account/store。
11. 禁止臆造 `wacli --help` 或本 skill 未记录的子命令或标志。

## 2. 全局标志约定

默认排序（紧跟 `wacli` 之后）：

- `--json`：默认启用，便于解析。
- `--read-only`：读操作必须，写操作禁止。
- `--account NAME`：多账号选择。
- `--store DIR`：自定义 store 目录。
- `--timeout DURATION`：非同步命令默认 `5m`。
- `--full`：人类可读表格时禁用截断。
- `--events`：仅在用户明确要求事件流时开启，向 stderr 输出 NDJSON 生命周期事件。

## 3. 接收方解析规则

- 接受 JID（`1234567890@s.whatsapp.net`）、手机号（`+1234567890` 或格式化号码）、频道 JID（`...@newsletter`）或已同步的联系人/群组/聊天名称。
- 如果名称匹配多个结果，不得猜测。脚本中使用 `--pick N`（N 为 1-indexed，第一个匹配是 `--pick 1`）；交互场景中列出匹配项并询问用户。

## 4. 错误处理速查

遇到错误时先解析 JSON 信封中的 `error` 字段，再读取 `stderr`：

- `not authenticated` → 运行 `wacli auth`。
- `store is locked` → 等待或停止正在运行的 `wacli sync --follow`。
- `ambiguous recipient` → 使用 `--pick N` 或询问。
- `read-only mode` → 写命令移除 `--read-only`。
- `message too old to edit` → 告知用户 WhatsApp 编辑窗口已过期。
- `file not found` → 发送前验证路径。

## 5. 首次使用工作流

1. `which wacli || wacli --version` 检查安装。
2. 未安装则按 `references/install.md` 指引安装（brew → go install → source），不得静默安装。
3. 运行 `wacli auth` 进行 QR 配对，或 `wacli auth --phone <number>` 进行电话码配对。非 TTY 环境优先电话码。
4. 持续后台同步运行 `wacli sync`（默认 `--follow`）；一次性同步运行 `wacli sync --once`。
5. 用 `wacli --json --read-only auth status` 验证。

## 6. 常用命令模板

```bash
wacli --json send text --to <RECIPIENT> --message "<TEXT>"
wacli --json --read-only messages search "<QUERY>"
wacli --json --read-only messages list --chat <CHAT>
wacli --json --read-only contacts show --jid <JID>
wacli --json --read-only groups list
wacli --json groups info --jid <GID>
wacli --json --read-only polls list
wacli --json --read-only media download --chat <CHAT> --id <MSG_ID> --output <PATH>
```

完整命令列表见 `references/command-index.md`。
