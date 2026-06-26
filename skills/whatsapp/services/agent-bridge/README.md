# WhatsApp Agent Bridge

一个基于 Bun 的本地 daemon，把 `wacli sync --webhook` 事件桥接到 AI Agent CLI，实现 WhatsApp 自动回复 / 半自动审核回复。

运行模式类似 **Kimi WebBridge**：启动后常驻后台，监听 incoming WhatsApp 消息，交给 AI 生成回复，再根据配置自动发送或保存草稿等待人工确认。

---

## 功能

- ✅ 启动本地 HTTP server 接收 `wacli` webhook 事件
- ✅ 自动启动并管理 `wacli sync --webhook` 子进程
- ✅ 判断用户是否第一次发消息
- ✅ 支持多种 AI Agent CLI：Claude、Kimi、Codex、OpenCode
- ✅ 支持直接调用 OpenAI-compatible API
- ✅ 默认半自动模式：AI 生成草稿 → 人工审核后发送
- ✅ 可选全自动模式：AI 生成回复 → 直接发送
- ✅ 白名单/黑名单控制
- ✅ 速率限制：同一联系人 1 分钟内最多自动回复 N 条
- ✅ SQLite 持久化：联系人、消息历史、首次标记
- ✅ JSONL 草稿队列
- ✅ 可编译为独立二进制（`bun build --compile`）

---

## 目录结构

```
services/agent-bridge/
├── src/
│   ├── index.ts        # daemon 入口 + HTTP server
│   ├── config.ts       # 环境变量配置
│   ├── logger.ts       # 日志
│   ├── wacli.ts        # wacli 命令封装 + webhook 事件解析
│   ├── ai.ts           # AI Agent CLI / API 调用
│   ├── db.ts           # SQLite 持久化
│   └── drafts.ts       # 草稿队列
├── package.json
├── tsconfig.json
└── README.md
```

---

## 安装

```bash
cd skills/whatsapp/services/agent-bridge
bun install
```

---

## 配置

全部通过环境变量配置：

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `WAB_PORT` | HTTP server 端口 | `8787` |
| `WAB_WEBHOOK_PATH` | Webhook 路径 | `/whatsapp-webhook` |
| `WAB_MODE` | `auto` 全自动 / `manual` 半自动 | `manual` |
| `WAB_WACLI_PATH` | wacli 可执行文件路径 | `wacli` |
| `WAB_ACCOUNT` | wacli 账号名（可选） | - |
| `WAB_STORE` | wacli store 目录（可选） | - |
| `WAB_AI_PROVIDER` | `claude` / `kimi` / `codex` / `opcode` / `api` / `mock` | `mock` |
| `WAB_AI_COMMAND` | AI CLI 自定义命令路径 | - |
| `WAB_AI_API_URL` | API 模式下的接口地址 | - |
| `WAB_AI_API_KEY` | API 模式下的密钥 | - |
| `WAB_AI_MODEL` | API 模式下的模型 | `gpt-4o` |
| `WAB_AUTO_REPLY_WHITELIST` | 强制自动回复的 JID 关键词，逗号分隔 | - |
| `WAB_AUTO_REPLY_BLACKLIST` | 忽略名单的 JID 关键词，逗号分隔 | - |
| `WAB_MAX_AUTO_REPLIES_PER_MINUTE` | 单联系人每分钟最大自动回复数 | `3` |
| `WAB_DB_PATH` | SQLite 数据库路径 | `~/.whatsapp-agent-bridge/bridge.db` |
| `WAB_DRAFTS_PATH` | 草稿队列文件路径 | `~/.whatsapp-agent-bridge/drafts.jsonl` |
| `WAB_LOG_LEVEL` | `debug` / `info` / `warn` / `error` | `info` |
| `WAB_SYSTEM_PROMPT` | AI 系统提示词 | 内置客服提示 |
| `WAB_FALLBACK_REPLY` | AI 失败时的兜底回复 | 内置英文回复 |

### 示例：半自动 + Claude

```bash
export WAB_MODE=manual
export WAB_AI_PROVIDER=claude
export WAB_AI_COMMAND=claude
export WAB_LOG_LEVEL=info

bun run src/index.ts
```

### 示例：全自动 + Kimi（仅白名单联系人）

```bash
export WAB_MODE=auto
export WAB_AI_PROVIDER=kimi
export WAB_AI_COMMAND=kimi
export WAB_AUTO_REPLY_WHITELIST="+86138,+86139"
export WAB_AUTO_REPLY_BLACKLIST="group-spam"

bun run src/index.ts
```

### 示例：API 模式（OpenAI-compatible）

```bash
export WAB_AI_PROVIDER=api
export WAB_AI_API_URL=https://api.openai.com/v1/chat/completions
export WAB_AI_API_KEY=sk-xxx
export WAB_AI_MODEL=gpt-4o

bun run src/index.ts
```

---

## 运行

### 开发模式

```bash
bun run dev
```

### 直接运行（需要 Bun）

仓库已提供一个启动脚本 `bin/whatsapp-agent-bridge`，它会在本地调用 `bun run src/index.ts`：

```bash
./bin/whatsapp-agent-bridge
```

**注意：** 此脚本依赖 Bun 运行时，不需要每次重新编译。

### 编译为独立二进制（可选，约 60MB）

如果你需要一台没有安装 Bun 的机器也能运行，可以编译成独立二进制：

```bash
bun run build:bin
```

输出：`bin/whatsapp-agent-bridge`（会被 `.gitignore` 忽略，不建议提交到 git）

直接运行：

```bash
./bin/whatsapp-agent-bridge
```

> 独立二进制大小约 60MB，因为它内嵌了整个 Bun Runtime。`--minify` 对体积影响极小。

### 后台运行（macOS / Linux）

```bash
nohup ./bin/whatsapp-agent-bridge > /tmp/whatsapp-agent-bridge.log 2>&1 &
```

---

## HTTP API

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/` / `/health` | 健康检查 + 配置摘要 |
| POST | `/whatsapp-webhook` | wacli 推送事件 |
| GET | `/drafts` | 列出待审核草稿 |
| POST | `/drafts/send` | 发送草稿 `{ draftId, chatJid, reply }` |
| GET | `/stats` | 统计信息 |

### 发送草稿示例

```bash
curl -X POST http://127.0.0.1:8787/drafts/send \
  -H 'Content-Type: application/json' \
  -d '{
    "draftId": "draft-xxx",
    "chatJid": "1234567890@s.whatsapp.net",
    "reply": "审核后的回复内容"
  }'
```

---

## 首次消息判断

1. 收到消息后，查询 SQLite `contacts` 表。
2. 如果 sender JID 不存在 → 标记为首次消息，并插入记录。
3. 如果已存在 → 不是首次消息，更新 `last_message_at`。

也可以通过 `wacli messages list --chat <JID> --from-them --limit 5` 交叉验证。

---

## 安全建议

- Webhook 只监听 `127.0.0.1`，不要暴露到公网。
- 生产环境建议用 `launchd` / `systemd` 管理 daemon。
- 自动回复前务必设置白名单或关键词过滤，避免误发。
- AI 生成的回复建议先从半自动模式开始，验证稳定后再切全自动。

---

## 与 wacli 的关系

这个 bridge **不直接监听** `wacli` 的 SQLite 数据库文件。它通过官方支持的 `wacli sync --webhook` 接收事件，因此：

- 不会触发 `store is locked`
- 不依赖内部表结构
- 事件顺序由 wacli 保证
