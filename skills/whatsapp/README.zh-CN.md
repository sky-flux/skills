# WhatsApp

[English](./README.md) | **中文**

通过 WhatsApp CLI [`wacli`](https://github.com/openclaw/wacli) 发送消息、搜索聊天记录、同步历史、管理联系人/群组/频道，并下载媒体文件。

**核心理念：** 把自然语言的 WhatsApp 任务翻译为安全的 `wacli` 调用，明确区分读/写操作，并对模糊的接收方进行消歧。如需自动化，可通过 `wacli sync --webhook` 把 incoming 消息推送到本地服务，实现自动回复或 AI Agent 辅助审核。

---

## 安装

```bash
npx skills add sky-flux/skills --skill whatsapp
```

全局安装（所有项目可用）：

```bash
npx skills add sky-flux/skills --skill whatsapp -g
```

## 前提条件

- **wacli** — WhatsApp CLI 守护进程
  ```bash
  which wacli && wacli --version
  ```
  安装方式见 `references/install.md`（brew / go install / 源码编译）。

## 快速开始

直接说：

```
给妈妈发条 WhatsApp 消息，说我快到了
```

或：

```
在我的 WhatsApp 聊天记录里搜索“发票”
```

## 工作原理

1. **触发检测** — 提到 WhatsApp、wacli 或隐式消息任务时激活本 skill。
2. **安全检查** — 根据 `references/safety.md` 将每条命令归类为读或写。
3. **读操作** 自动追加 `--read-only`。
4. **写操作** 需要明确的接收方；名称模糊时使用 `--pick N` 或询问用户。
5. **默认 JSON 输出**，便于可靠解析。
6. **错误处理** 遵循 `references/error-handling.md`：认证失败运行 `wacli auth`、store 锁定用 `--lock-wait` 重试、接收方模糊时确认。

## 常用命令

```bash
# 发送消息
wacli --json send text --to "+1234567890" --message "Hello"

# 搜索消息
wacli --json --read-only messages search "meeting"

# 列出聊天
wacli --json --read-only chats list

# 一次性同步历史
wacli --json sync --once

# 下载媒体
wacli --json --read-only media download --chat "+1234567890" --id "<MSG_ID>" --output ./downloads
```

## 自动化

使用内置的 Bun daemon 构建全自动或半自动 WhatsApp 助手：

```bash
cd services/agent-bridge
bun install
export WAB_AI_PROVIDER=claude  # 或 kimi / codex / opcode / api / mock
export WAB_MODE=manual         # manual 半自动审核，auto 全自动发送
bun run dev
```

编译为独立二进制：

```bash
bun run build:bin
./bin/whatsapp-agent-bridge
```

该 daemon 会自动：
- 启动 `wacli sync --webhook`
- 判断用户是否第一次发消息
- 调用指定的 AI Agent CLI 生成回复
- 默认半自动模式（草稿等待人工审核）
- 支持白名单/黑名单和速率限制

## 参考文档

- `references/safety.md` — 读/写命令分类
- `references/install.md` — wacli 安装指南
- `references/command-index.md` — 完整命令索引
- `references/error-handling.md` — 错误码与恢复
- `references/automation.md` — Webhook 自动化、自动回复、AI Agent CLI 集成
