---
name: 1688
description: Use when the user wants to find 1688.com suppliers, factories, or manufacturers and extract their contact information (phone, mobile, address, contact person). Triggers on mentions of 1688, Alibaba wholesale China, 1688 suppliers, 1688 factories, contact info from 1688, finding manufacturers on 1688, or sourcing from 1688.
---

# 1688 供应商搜索

通过 Google Search 定位 `www.1688.com/factory/...` 工厂黄页，提取店铺子域名，访问 `contactinfo.htm` 获取联系方式。

## 前置检查

每次任务开始前，先检查 Kimi WebBridge 状态：

```bash
~/.kimi-webbridge/bin/kimi-webbridge status
```

- `running: true` 且 `extension_connected: true` → 继续
- 否则 → 告知用户启动 WebBridge 后再试

## 核心工作流

```
Step 1: Google 搜索 site:1688.com/factory <产品关键词>
    ↓
Step 2: 提取结果中的 factory 页面 URL 列表
    ↓
Step 3: 逐个访问 factory 页面
    ↓
Step 4: 从页面提取公司名 + 店铺子域名链接
    ↓
Step 5: 构造 contactinfo URL
    ↓
Step 6: 访问 contactinfo 页面
    ↓
Step 7: 提取联系方式
```

## Step 1: Google 搜索

使用 `site:1688.com/factory` 精准定位工厂黄页，避免触发 reCAPTCHA。

**推荐搜索模板：**
- `site:1688.com/factory 轴承`
- `site:1688.com/factory 仓库货架`
- `site:1688.com/factory 五金加工`
- `site:1688.com/factory <产品关键词> <地区>`

**WebBridge 调用：**

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "navigate",
    "args": {
      "url": "https://www.google.com/search?q=site:1688.com/factory+<产品关键词>",
      "newTab": true,
      "group_title": "1688供应商搜索"
    },
    "session": "1688-supplier-search"
  }'
```

等待 2-3 秒让页面加载完成。

## Step 2: 提取 Factory URL 列表

从 Google 搜索结果中提取所有 `www.1688.com/factory/` 链接：

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const results = Array.from(document.querySelectorAll(\"div.g, div[data-ved]\")).map(el => { const link = el.querySelector(\"a[href]\"); const title = el.querySelector(\"h3\"); return link && title ? {title: title.innerText.trim(), href: link.href} : null; }).filter(x => x && x.href.includes(\"1688.com/factory\")); return JSON.stringify(results.slice(0, 15)); })()"
    },
    "session": "1688-supplier-search"
  }'
```

结果示例：
```json
[
  {"title": "山东万宇轴承有限公司-企业信息查询黄页-阿里巴巴", "href": "https://www.1688.com/factory/b2b-29294048408fb97.html"},
  {"title": "山东新派轴承制造有限公司-企业信息查询黄页-阿里巴巴", "href": "https://www.1688.com/factory/b2b-22149726270338e493.html"}
]
```

## Step 3: 访问 Factory 页面

逐个访问每个 factory URL。同一 session 下用 `newTab: true` 打开，方便后续切换。

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "navigate",
    "args": {
      "url": "https://www.1688.com/factory/b2b-xxx.html",
      "newTab": true
    },
    "session": "1688-supplier-search"
  }'
```

等待 2-3 秒让页面加载。

> **注意**：部分 1688 页面可能触发弹窗或重定向，导致 session tab 被关闭。如遇 `session tab was closed` 错误，重新执行一次 `navigate` 即可（使用新的 session 名如 `1688-test-2`）。

## Step 4: 提取店铺子域名

从 factory 页面提取店铺子域名链接（格式：`xxx.1688.com`）。**1688 工厂黄页的标准入口文案是"进旺铺"**，基于 accessibility 语义定位比 DOM 结构路径更稳定。

### 方案 1（推荐）：Evaluate 语义文本匹配

不依赖 snapshot，直接用 JS 按 `innerText` 筛选：

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const link = Array.from(document.querySelectorAll(\"a\")).find(a => a.innerText.trim().includes(\"旺铺\")); return JSON.stringify({found: !!link, href: link ? link.href : null, text: link ? link.innerText.trim() : null}); })()"
    },
    "session": "1688-supplier-search"
  }'
```

典型结果：`{"found": true, "href": "https://shop47qv684964q21.1688.com/?spm=..."}`

### 方案 2：HTML 正则兜底

如果前两个方案都失败，从完整 HTML 源码中匹配：

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const html = document.documentElement.innerHTML; const matches = html.match(/[a-zA-Z0-9_-]+\\.1688\\.com/g); const unique = [...new Set(matches || [])].filter(d => ![\"www.1688.com\", \"s.1688.com\", \"detail.1688.com\", \"sale.1688.com\", \"r.1688.com\", \"cx.1688.com\"].includes(d)); return JSON.stringify(unique.slice(0, 5)); })()"
    },
    "session": "1688-supplier-search"
  }'
```

## Step 5: 构造 Contactinfo URL

从子域名构造联系方式页面 URL：

```
https://<子域名>/page/contactinfo.htm
```

示例：`https://jtn1688.1688.com/page/contactinfo.htm`

## Step 6: 访问 Contactinfo 页面

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "navigate",
    "args": {
      "url": "https://<子域名>.1688.com/page/contactinfo.htm",
      "newTab": true
    },
    "session": "1688-supplier-search"
  }'
```

等待 2 秒让页面加载。

## Step 7: 提取联系方式

> **JSON 转义注意**：evaluate 代码中 `\n` 在 JSON 字符串中需写成 `\\n`，在 curl 的 `-d` 参数中又需额外转义。最稳妥的方式是将代码写成一个无反斜杠的 IIFE，或把复杂正则放到 reference 脚本中引用。

结构化提取 contactinfo 页面信息：

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const sections = Array.from(document.querySelectorAll(\"section, div, table, ul, dl\")); let contactSection = null; for (const s of sections) { if (s.innerText && s.innerText.includes(\"联系方式\") && (s.innerText.includes(\"电话\") || s.innerText.includes(\"手机\"))) { contactSection = s; break; } } if (!contactSection) contactSection = document.body; const text = contactSection.innerText; const lines = text.split(String.fromCharCode(10)).map(l => l.trim()).filter(l => l.length > 0 && l.length < 200); const result = {url: window.location.href, company: null, phone: null, mobile: null, fax: null, address: null, contactPerson: null}; const extract = (line, prefix) => { const idx = line.indexOf(prefix); return idx >= 0 ? line.slice(idx + prefix.length).trim() : null; }; for (const line of lines) { if (line.includes(\"电话：\") || line.includes(\"电话:\")) result.phone = extract(line, line.includes(\"电话：\") ? \"电话：\" : \"电话:\"); else if (line.includes(\"手机：\") || line.includes(\"手机:\")) result.mobile = extract(line, line.includes(\"手机：\") ? \"手机：\" : \"手机:\"); else if (line.includes(\"传真：\") || line.includes(\"传真:\")) result.fax = extract(line, line.includes(\"传真：\") ? \"传真：\" : \"传真:\"); else if (line.includes(\"地址：\") || line.includes(\"地址:\")) result.address = extract(line, line.includes(\"地址：\") ? \"地址：\" : \"地址:\"); else if (line.includes(\"联系人：\") || line.includes(\"联系人:\")) result.contactPerson = extract(line, line.includes(\"联系人：\") ? \"联系人：\" : \"联系人:\"); else if (/^(.*先生|.*女士|.*经理|.*厂长)$/.test(line) && !line.includes(\"欢迎\") && !line.includes(\"问题\")) { result.contactPerson = line; } else if (!result.company && line.length > 4 && line.length < 50 && !line.includes(\":\")) { result.company = line; } } return JSON.stringify(result); })()"
    },
    "session": "1688-supplier-search"
  }'
```

如果结构化提取失败，兜底提取所有含关键词的行：

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const text = document.body.innerText; const lines = text.split(String.fromCharCode(10)).map(l => l.trim()).filter(l => l.length > 0 && l.length < 200); const keywords = [\"电话\",\"手机\",\"传真\",\"地址\",\"联系人\",\"公司名称\",\"邮箱\",\"QQ\",\"微信\"]; const contactLines = lines.filter(l => keywords.some(k => l.includes(k))); return JSON.stringify({url: window.location.href, allContactLines: contactLines.slice(0, 30)}); })()"
    },
    "session": "1688-supplier-search"
  }'
```

## Step 8: 补充工商信息（可选）

当 contactinfo 页面**联系人缺失**或**信息不完整**时，通过 Google 搜索补充工商注册信息。

搜索：`"公司名称" 电话 工商`

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "navigate",
    "args": {
      "url": "https://www.google.com/search?q=\"公司名称\"+电话+工商",
      "newTab": true
    },
    "session": "1688-supplier-search"
  }'
```

从搜索结果中提取：法定代表人、注册资本、成立日期、邮箱等。

**为什么有效：** 1688 工厂黄页页面的电话常被隐藏（需点击"联系工厂"按钮），但 Google 搜索企业工商信息能直接获取公开登记的联系方式。Baseline 测试证明此策略可获取法定代表人姓名、注册资本、成立日期、邮箱等补充信息。

## 输出格式

以 Markdown 表格汇总所有提取结果。基础字段必备，补充字段（Step 8）有则填：

### 基础信息表（Step 1-7）

| 公司 | 电话 | 手机 | 地址 | 联系人 | 店铺 |
|------|------|------|------|--------|------|
| 邢台博扬轴承制造有限公司 | 86 0319 8568899 | 13739693628 | 河北省邢台市... | 柏天顺先生 | xybyzz.1688.com |
| 山东达星轴承有限公司 | 86 0635 13963549362 | 13963549362 | 山东聊城... | — | shop47qv684964q21.1688.com |

### 补充信息（Step 8 工商搜索）

| 公司 | 法定代表人 | 注册资本 | 成立日期 | 邮箱 | 主营产品 |
|------|-----------|---------|---------|------|---------|
| 山东达星轴承有限公司 | 赵宗兴 | 500万元 | 2020-02-20 | 331364177@qq.com | 圆锥滚子轴承、汽车轮毂轴承... |

## 批量处理策略

当搜索结果较多时，建议分批处理：
- 每批处理 5-10 个 factory 页面
- 每访问一个页面后加 1-2 秒延迟
- 用同一 session 管理所有标签页，任务结束后可 `close_session` 清理

## 常见问题

### Google 触发 reCAPTCHA
- 使用 `site:1688.com/factory` 而非 `site:1688.com inurl:contactinfo`
- 避免短时间内高频搜索
- 如仍触发，需要用户在浏览器中手动点击验证

### 搜不到店铺子域名
- 部分 factory 页面可能没有独立的子域名店铺
- 尝试直接从 factory 页面提取电话/地址信息（右侧"立即询价"表单中常有手机号）

### Contactinfo 页面加载失败
- 确认子域名正确（从 factory 页面源码提取）
- 部分店铺可能关闭了 contactinfo 页面访问

### 提取结果为空
- 1688 页面结构可能变化，尝试更通用的 evaluate 代码
- 使用 `document.body.innerText` 获取全部文本再筛选

### 联系人姓名缺失
- 部分 1688 店铺的 contactinfo 页面不展示具体联系人姓名
- **解决方案**：执行 Step 8，通过 Google 搜索 `"公司名称" 电话 工商` 获取法定代表人信息

### JSON 转义导致 evaluate 失败
- evaluate 代码中的 `\n`、`\d`、`\.` 等正则转义在 JSON 字符串中需要额外一层转义
- **解决方案**：将复杂正则逻辑放到 `references/` 下的 JS 文件中，通过 `evaluate` 读取文件内容执行；或简化正则避免多层转义

### 1688 工厂黄页电话保护机制
- 部分 factory 页面（`www.1688.com/factory/...`）默认隐藏电话号码，需点击"联系工厂"按钮才能显示
- **为什么 skill 能绕过**：skill 的链路不依赖 factory 页面的电话显示，而是跳转子域名的 contactinfo 页面提取，该页面通常直接展示联系方式
