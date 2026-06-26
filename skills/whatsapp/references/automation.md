# WhatsApp 自动化回复与 Webhook 集成

本文件说明如何利用 `wacli sync --webhook` 实现全自动/半自动消息处理，并与各种 AI Agent CLI 交互。

**推荐：** 我们已经实现了一个可直接运行的 Bun daemon——`services/agent-bridge/`。它封装了 webhook server、AI 调用、首次消息判断、草稿队列、SQLite 持久化，并支持编译为独立二进制。生产使用请优先参考该目录。


**核心思路：** `wacli sync` 会把 WhatsApp 事件（新消息、状态变更等）推送到你指定的本地 HTTP 端点，你在这个端点里决定：自动回复、生成草稿等待审核、还是忽略。

---

## 1. 不需要自己监听 `session.db` / `wacli.db`

`wacli` 内部使用 SQLite store，但**不推荐**直接轮询或监听数据库文件：

- DB 文件可能在写入时被锁定（`store is locked`）。
- 表结构不对外承诺稳定，升级后可能变化。
- 事件顺序、媒体下载状态等在 DB 中不一定实时可观察。

正确做法：使用 `wacli sync --webhook <URL>`。`wacli` 会在内部监听 store 变化，并按事件形式推送到你的 HTTP 服务。

---

## 2. 启动 Webhook 监听

### 2.1 先决条件

1. `wacli auth` 已完成登录。
2. `wacli --json --read-only auth status` 显示已认证。
3. 已安装一个本地 HTTP server（下面提供 Bun/Node/Python 示例）。

### 2.2 启动 wacli sync webhook 模式

```bash
wacli --json sync --webhook http://127.0.0.1:8787/whatsapp-webhook
```

默认行为：
- 持续同步（类似 `--follow`）。
- 每收到新事件就 POST 到指定 URL。
- 输出 NDJSON 到 stdout，事件流可能到 stderr（取决于版本）。

如果想同时下载媒体：

```bash
wacli --json sync --webhook http://127.0.0.1:8787/whatsapp-webhook --download-media
```

### 2.3 后台运行

使用 `systemd`、`launchd` 或 `nohup` + `&`：

```bash
nohup wacli --json sync --webhook http://127.0.0.1:8787/whatsapp-webhook > /tmp/wacli-webhook.log 2>&1 &
```

macOS 推荐用 `launchd` plist 或 `brew services`；Linux 推荐 `systemd` service。

---

## 3. 本地 Webhook Server 示例

### 3.1 Bun / Node

```typescript
// whatsapp-webhook-server.ts
import { serve } from "bun";

const PORT = 8787;

serve({
  port: PORT,
  async fetch(req) {
    if (req.method !== "POST" || new URL(req.url).pathname !== "/whatsapp-webhook") {
      return new Response("Not Found", { status: 404 });
    }

    const event = await req.json();
    console.log("Received event:", JSON.stringify(event, null, 2));

    // 只处理收到的文本消息
    if (event.type === "message" && !event.message.fromMe && event.message.type === "text") {
      const chatJID = event.message.chat || event.message.sender;
      const text = event.message.text || "";
      const sender = event.message.sender;

      // 1. 判断是否是第一次消息
      const isFirstMessage = await checkIsFirstMessage(chatJID, sender);

      // 2. 把消息交给 AI Agent 生成回复
      const reply = await generateReply(text, sender, isFirstMessage);

      // 3. 模式选择
      if (process.env.WHATSAPP_MODE === "auto") {
        // 全自动：直接发送
        await sendWhatsAppMessage(chatJID, reply);
      } else {
        // 半自动：保存草稿，等待人工审核
        await saveDraft(chatJID, reply, event.message.id);
      }
    }

    return new Response("OK", { status: 200 });
  },
});

async function checkIsFirstMessage(chatJID: string, sender: string): Promise<boolean> {
  // 方法 1：查询 wacli 本地历史
  // 如果该 chat 只有这一条消息，或没有来自该 sender 的消息，就是首次
  const result = await runCommand(
    `wacli --json --read-only messages list --chat ${chatJID} --from-them --limit 5`
  );
  const messages = JSON.parse(result);
  return messages.length <= 1;
}

async function generateReply(text: string, sender: string, isFirst: boolean): Promise<string> {
  // 调用本地 AI Agent CLI 生成回复
  // 示例：调用 kimi / claude / opencode 等
  const prompt = buildPrompt(text, sender, isFirst);
  return runCommand(`echo ${JSON.stringify(prompt)} | kimi -c "根据用户消息生成 WhatsApp 回复"`);
}

async function sendWhatsAppMessage(to: string, message: string) {
  await runCommand(`wacli --json send text --to ${to} --message ${JSON.stringify(message)}`);
}

async function saveDraft(chatJID: string, reply: string, originalMsgId: string) {
  // 保存到本地草稿文件或数据库，等待人工确认
  const draft = { chatJID, reply, originalMsgId, createdAt: new Date().toISOString() };
  await Bun.write("./drafts.jsonl", JSON.stringify(draft) + "\n", { append: true });
}

function runCommand(cmd: string): Promise<string> {
  const proc = Bun.spawn(cmd.split(" "), { stdout: "pipe" });
  return new Response(proc.stdout).text();
}

function buildPrompt(text: string, sender: string, isFirst: boolean): string {
  return `用户${isFirst ? "第一次" : ""}发来 WhatsApp 消息：\n${text}\n\n请生成一条礼貌、简洁的回复。`;
}
```

运行：

```bash
bun run whatsapp-webhook-server.ts
```

### 3.2 Python

```python
# whatsapp_webhook_server.py
import json
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = 8787
MODE = "auto"  # "auto" 或 "manual"

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/whatsapp-webhook":
            self.send_response(404)
            self.end_headers()
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        event = json.loads(body)

        print("Received:", json.dumps(event, indent=2))

        if event.get("type") == "message" and not event["message"].get("fromMe"):
            chat = event["message"].get("chat") or event["message"].get("sender")
            text = event["message"].get("text", "")
            sender = event["message"].get("sender")

            is_first = check_is_first_message(chat, sender)
            reply = generate_reply(text, sender, is_first)

            if MODE == "auto":
                send_message(chat, reply)
            else:
                save_draft(chat, reply, event["message"].get("id"))

        self.send_response(200)
        self.end_headers()

def check_is_first_message(chat, sender):
    result = subprocess.run(
        ["wacli", "--json", "--read-only", "messages", "list", "--chat", chat, "--from-them", "--limit", "5"],
        capture_output=True, text=True
    )
    try:
        messages = json.loads(result.stdout)
        return len(messages) <= 1
    except:
        return False

def generate_reply(text, sender, is_first):
    prompt = f"用户{'第一次' if is_first else ''}发来 WhatsApp 消息：\n{text}\n\n请生成一条礼貌、简洁的回复。"
    # 调用 kimi / claude / opencode
    result = subprocess.run(["kimi", "-c", prompt], capture_output=True, text=True)
    return result.stdout.strip()

def send_message(to, message):
    subprocess.run([
        "wacli", "--json", "send", "text", "--to", to, "--message", message
    ])

def save_draft(chat, reply, original_id):
    with open("drafts.jsonl", "a") as f:
        f.write(json.dumps({
            "chatJID": chat,
            "reply": reply,
            "originalMsgId": original_id,
            "createdAt": __import__("datetime").datetime.now().isoformat()
        }) + "\n")

if __name__ == "__main__":
    print(f"Listening on http://127.0.0.1:{PORT}/whatsapp-webhook")
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
```

运行：

```bash
python3 whatsapp_webhook_server.py
```

---

## 4. 判断“用户第一次发消息”

`wacli` 事件本身通常不会告诉你这是不是第一次。推荐以下判断方法：

### 方法 1：查询历史消息数（推荐）

```bash
wacli --json --read-only messages list --chat <CHAT_JID> --from-them --limit 5
```

- 返回 0 条：绝对是首次。
- 返回 1 条（就是当前这条）：首次。
- 返回 >1 条：不是首次。

### 方法 2：维护一个“已接触”联系人表

你的 Webhook server 自己维护一个简单 JSON/CSV：

```json
{
  "1234567890@s.whatsapp.net": { "firstContactAt": "2026-06-26T10:00:00Z" },
  "group-xxxx@g.us": { "firstContactAt": "2026-06-26T11:00:00Z" }
}
```

新消息 sender 不在表中 → 首次。

### 方法 3：结合 1688 / CRM 数据

如果你有外部 CRM 或客户数据库，按手机号/JID 查询是否已有记录。

---

## 5. 全自动 vs 半自动模式

### 5.1 全自动模式

配置：

```bash
export WHATSAPP_MODE=auto
```

流程：

```
新消息 → Webhook Server → AI Agent 生成回复 → wacli send text → 发送
```

适用场景：
- 常见 FAQ
- 非工作时间的自动应答
- 已训练好的客服 Agent

风险：
- AI 可能生成不合适的回复。
- 建议设置“自动回复白名单”或“关键词黑名单”。

### 5.2 半自动模式（推荐用于重要客户）

配置：

```bash
export WHATSAPP_MODE=manual
```

流程：

```
新消息 → Webhook Server → AI Agent 生成回复草稿 → 保存到 drafts.jsonl
→ 人工审核 → 确认后调用 wacli send text
```

审核命令示例：

```bash
# 列出待审核草稿
cat drafts.jsonl | tail -n 10

# 发送某条草稿（按 originalMsgId 或行号）
wacli --json send text --to <CHAT_JID> --message "审核后的回复内容"
```

---

## 6. 与 AI Agent CLI 集成

Webhook server 里可以通过子进程调用任意 AI Agent CLI：

| Agent CLI | 调用示例 |
|---------|---------|
| Kimi Code CLI | `echo "prompt" \| kimi -c "..."` |
| Claude Code | `claude -p "..."` |
| OpenCode | `opencode ask "..."` |
| Cursor / Warp 等 | 通过各自的 CLI 或 MCP 接口 |

更稳定的方案：让 AI Agent 以 **MCP server** 或 **HTTP API** 形式暴露，Webhook server 直接发 HTTP 请求，而不是每次 spawn 子进程。

---

## 7. 安全与边界

1. **Webhook 只监听 127.0.0.1**，不要暴露到公网。
2. **自动回复前校验 sender**：避免给自己或群聊发送循环消息。
3. **忽略 fromMe=true 的消息**：否则可能自循环。
4. **设置速率限制**：同一 chat 1 分钟内最多自动回复 3 条。
5. **处理媒体消息**：非文本消息先保存，提示人工处理。
6. **异常时降级**：AI 生成失败时发送兜底回复“我们已收到，稍后人工回复”。

---

## 8. 事件格式参考（以 wacli 实际输出为准）

典型消息事件：

```json
{
  "type": "message",
  "message": {
    "id": "msg_xxx",
    "chat": "1234567890@s.whatsapp.net",
    "sender": "1234567890@s.whatsapp.net",
    "fromMe": false,
    "type": "text",
    "text": "你好，请问这款产品多少钱？",
    "timestamp": "2026-06-26T10:00:00Z"
  }
}
```

> 实际字段名和结构取决于 `wacli` 版本。启动 webhook 后先观察日志确认。

---

## 9. 推荐架构

```
┌─────────────┐     WebSocket/HTTP      ┌──────────────┐
│  WhatsApp   │ ◄──────────────────────► │    wacli     │
│   Server    │                         │  sync mode   │
└─────────────┘                         └──────┬───────┘
                                               │ POST events
                                               ▼
                                      ┌─────────────────┐
                                      │  Local Webhook  │
                                      │    Server       │
                                      └────────┬────────┘
                                               │
                          ┌────────────────────┼────────────────────┐
                          ▼                    ▼                    ▼
                   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
                   │ Auto Reply  │     │ Draft Queue │     │ AI Agent    │
                   │  (全自动)    │     │  (半自动)    │     │  CLI/API    │
                   └─────────────┘     └─────────────┘     └─────────────┘
```

---

## 10. 命令速查

```bash
# 启动 webhook 同步
wacli --json sync --webhook http://127.0.0.1:8787/whatsapp-webhook

# 后台运行
nohup wacli --json sync --webhook http://127.0.0.1:8787/whatsapp-webhook > /tmp/wacli-webhook.log 2>&1 &

# 检查是否在线
wacli --json --read-only auth status

# 查询某 chat 历史
wacli --json --read-only messages list --chat <CHAT_JID> --from-them --limit 5

# 发送自动回复
wacli --json send text --to <CHAT_JID> --message "回复内容"
```
