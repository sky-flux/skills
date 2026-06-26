# WhatsApp

[English](./README.md) | **中文**

通过 WhatsApp CLI [`wacli`](https://github.com/openclaw/wacli) 发送消息、搜索聊天记录、同步历史、管理联系人/群组/频道，并下载媒体文件。

**核心理念：** 把自然语言的 WhatsApp 任务翻译为安全的 `wacli` 调用，明确区分读/写操作，并对模糊的接收方进行消歧。

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

## 参考文档

- `references/safety.md` — 读/写命令分类
- `references/install.md` — wacli 安装指南
- `references/command-index.md` — 完整命令索引
- `references/error-handling.md` — 错误码与恢复
