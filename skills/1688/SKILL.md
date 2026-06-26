---
name: "1688"
description: Use when the user wants to find 1688.com suppliers, factories, or manufacturers and extract their contact information (phone, mobile, address, contact person). Triggers on mentions of 1688, Alibaba wholesale China, 1688 suppliers, 1688 factories, contact info from 1688, finding manufacturers on 1688, or sourcing from 1688.
---

# 1688 供应商搜索

通过搜索引擎定位 `www.1688.com/factory/...` 工厂黄页，提取店铺子域名，访问 `contactinfo.htm` 获取联系方式。

详细脚本和拦截检测参考 `references/` 目录：
- `references/search-engines.md` — Bing/Google 搜索与拦截检测
- `references/factory.md` — Factory 黄页子域名提取
- `references/contact.md` — Contactinfo 联系方式提取
- `references/slider-solver.md` — 1688 Slider/CAPTCHA 自动滑动方案
- `references/anti-block.md` — 反拦截与 fallback 策略

## 前置检查

每次任务开始前，先检查 Kimi WebBridge 状态：

```bash
~/.kimi-webbridge/bin/kimi-webbridge status
```

- `running: true` 且 `extension_connected: true` → 继续
- 否则 → 告知用户启动 WebBridge 后再试

## 防拦截核心原则

1688 和 Google 都有反爬/风控机制。**不要追求 100% 成功率**，但必须做到：

1. **每次遇到验证都能识别并给出可执行的绕过方案**。
2. **不追求每次请求都成功，但遇到拦截时必须让用户明确知道发生了什么、如何继续**。
3. **优先使用 Bing 搜索**（Google 更容易触发 unusual traffic）。
4. **每个页面访问后加 2-4 秒延迟**，降低被 1688 风控拦截的概率。
5. **contactinfo 页面出现 Slider/CAPTCHA 时，优先使用 `references/slider-solver.md` 中的脚本自动完成滑动；自动失败后再提示用户手动验证或跳过**。

## 核心工作流

```
Step 1: 选择搜索引擎（默认 Bing，Google 作为备选）
    ↓
Step 2: 搜索 site:1688.com/factory <产品关键词>
    ↓
Step 3: 检测搜索结果页是否被拦截
    ↓
Step 4: 提取结果中的 factory 页面 URL 列表
    ↓
Step 5: 逐个访问 factory 页面
    ↓
Step 6: 从页面提取公司名 + 店铺子域名链接
    ↓
Step 7: 构造 contactinfo URL
    ↓
Step 8: 访问 contactinfo 页面
    ↓
Step 9: 检测 contactinfo 是否被拦截（Slider/CAPTCHA/登录）
    ↓
Step 10: 提取联系方式 或 执行 fallback/人工验证
```

## Step 1 & 2: 搜索引擎选择与搜索

### 默认使用 Bing

Bing 对 `site:1688.com/factory` 的封锁概率显著低于 Google。

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "navigate",
    "args": {
      "url": "https://www.bing.com/search?q=site:1688.com/factory+<产品关键词>",
      "newTab": true,
      "group_title": "1688供应商搜索"
    },
    "session": "1688-supplier-search"
  }'
```

等待 3-4 秒让页面加载完成。

### Google 作为备选

仅当 Bing 结果明显不足或 Bing 也被拦截时才使用 Google：

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

## Step 3: 检测搜索结果页是否被拦截

访问搜索页面后，**立即运行拦截检测脚本**：

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const text = document.body.innerText; const title = document.title; const url = window.location.href; const blocked = text.includes(\"Our systems have detected unusual traffic\") || text.includes(\"unusual traffic\") || text.includes(\"reCAPTCHA\") || text.includes(\"Sorry, we have detected unusual traffic\") || url.includes(\"google.com/sorry\"); return JSON.stringify({url, title, blocked, reason: blocked ? (text.includes(\"reCAPTCHA\") ? \"reCAPTCHA\" : \"unusual traffic\") : null, preview: text.substring(0, 200)}); })()"
    },
    "session": "1688-supplier-search"
  }'
```

**如果检测到拦截：**
- 如果是 Google：切换到 Bing
- 如果是 Bing：等待 10-15 秒后重试一次；如仍被拦截，提示用户当前网络触发搜索引擎风控，建议稍后重试或更换网络

## Step 4: 提取 Factory URL 列表

### Bing 结果提取

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const results = Array.from(document.querySelectorAll(\"li.b_algo\")).map(el => { const link = el.querySelector(\"a[href]\"); const title = el.querySelector(\"h2\"); return link && title ? {title: title.innerText.trim(), href: link.href} : null; }).filter(x => x && x.href.includes(\"1688.com/factory\")); return JSON.stringify(results.slice(0, 15)); })()"
    },
    "session": "1688-supplier-search"
  }'
```

### Google 结果提取

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

### 兜底提取

如果上述方案都失败，直接从所有链接中筛选：

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const links = Array.from(document.querySelectorAll(\"a[href]\")).filter(a => a.href.includes(\"1688.com/factory\")).map(a => ({text: a.innerText.trim().substring(0, 80), href: a.href})); return JSON.stringify(links.slice(0, 15)); })()"
    },
    "session": "1688-supplier-search"
  }'
```

## Step 5: 访问 Factory 页面

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

等待 3-4 秒让页面加载。

> **注意**：部分 1688 页面可能触发弹窗或重定向，导致 session tab 被关闭。如遇 `session tab was closed` 错误，重新执行一次 `navigate` 即可（使用新的 session 名如 `1688-test-2`）。

## Step 6: 提取店铺子域名

从 factory 页面提取店铺子域名链接（格式：`xxx.1688.com`）。**1688 工厂黄页的标准入口文案是"进旺铺"**，基于 accessibility 语义定位比 DOM 结构路径更稳定。

### 方案 1（推荐）：Evaluate 语义文本匹配

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

### 方案 2：链接选择器

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const links = Array.from(document.querySelectorAll(\"a[href]\")).map(a => a.href).filter(h => { const isSubdomain = /[a-zA-Z0-9_-]+\\.1688\\.com/.test(h); const isNotOfficial = ![\"www.1688.com\",\"s.1688.com\",\"detail.1688.com\",\"sale.1688.com\",\"r.1688.com\",\"cx.1688.com\",\"auth.1688.com\",\"login.1688.com\"].some(d => h.includes(d)); return isSubdomain && isNotOfficial; }); const unique = [...new Set(links)]; return JSON.stringify(unique.slice(0, 5)); })()"
    },
    "session": "1688-supplier-search"
  }'
```

### 方案 3：HTML 正则兜底

如果前两个方案都失败，从完整 HTML 源码中匹配：

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const html = document.documentElement.innerHTML; const matches = html.match(/[a-zA-Z0-9_-]+\\.1688\\.com/g); const unique = [...new Set(matches || [])].filter(d => ![\"www.1688.com\",\"s.1688.com\",\"detail.1688.com\",\"sale.1688.com\",\"r.1688.com\",\"cx.1688.com\",\"auth.1688.com\",\"login.1688.com\"].includes(d)); return JSON.stringify(unique.slice(0, 5)); })()"
    },
    "session": "1688-supplier-search"
  }'
```

## Step 7: 构造 Contactinfo URL

从子域名构造联系方式页面 URL：

```
https://<子域名>/page/contactinfo.htm
```

示例：`https://jtn1688.1688.com/page/contactinfo.htm`

## Step 8: 访问 Contactinfo 页面

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

等待 3-4 秒让页面加载。

## Step 9: 检测 Contactinfo 是否被拦截

访问 contactinfo 后**立即**运行以下检测：

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const text = document.body.innerText; const title = document.title; const url = window.location.href; const blocked = text.includes(\"Please slide to verify\") || text.includes(\"请拖动滑块\") || text.includes(\"Captcha Interception\") || text.includes(\"Sorry, we have detected unusual traffic\") || text.includes(\"请登录\") || text.includes(\"Login\") || url.includes(\"login.1688.com\"); const blockType = text.includes(\"Please slide to verify\") ? \"slider\" : text.includes(\"请登录\") || url.includes(\"login.1688.com\") ? \"login\" : text.includes(\"unusual traffic\") ? \"traffic\" : null; return JSON.stringify({url, title, blocked, blockType, preview: text.substring(0, 300)}); })()"
    },
    "session": "1688-supplier-search"
  }'
```

### 如果被 Slider 拦截

**优先自动完成滑动验证**，执行 `references/slider-solver.md` 中的脚本。该脚本要点：

- 自动定位滑块 handle (`#nc_1_n1z`) 和 track (`#nc_1_n1t`)
- 通过 `MouseEvent` 事件序列模拟人类拖动
- 整个拖动耗时在 **2-5 秒** 之间，服从随机正态分布
- 完成后返回实际耗时

完整 JS 代码见 `references/slider-solver.md`。执行后等待 2-3 秒，再运行拦截检测脚本确认是否通过。

等待 2-3 秒后，重新执行拦截检测脚本。如果仍然被拦截，刷新 contactinfo 页面并再次执行自动滑动，最多重试 5 次。5 次后仍失败则提示用户手动验证或跳过该店铺。

验证完成后刷新页面继续提取：

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

### 如果被登录拦截

> 当前 1688 需要登录才能查看联系方式。该店铺无法直接获取，尝试从 factory 黄页提取公开信息，或跳过该店铺继续处理下一家。

### 如果被流量风控拦截

> 当前 1688 检测到异常流量。建议：
> 1. 降低处理速度（增加延迟到 5-10 秒）
> 2. 等待 30-60 秒后重试
> 3. 跳过当前店铺，继续处理下一家

## Step 10: 提取联系方式

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

## Step 11: 补充工商信息（联系人/电话缺失时）

当 Step 10 提取结果中 **联系人（contactPerson）为空** 或 **电话与手机都为空** 时，按以下优先级补充：

### 1. 天眼查（仅 Kimi 且可用时）

如果你当前使用的是 Kimi，并且可以直接调用天眼查数据，**优先使用天眼查**：

- 搜索字段：公司名称（从 Step 10 的 `company` 字段获取）
- 目标字段：法定代表人、联系电话、企业地址、邮箱/官网（如有）
- 将天眼查结果回填到输出表格的“联系人 / 电话 / 地址”列

> 如果天眼查返回多个同名公司，按注册地址与 1688 店铺地址最匹配的进行选择；无法确定时询问用户。
> 如果天眼查不可用或查询失败，自动降级到搜索引擎。

### 2. Bing / Google 搜索（天眼查不可用或非 Kimi 时）

如果无法调用天眼查，或当前不是 Kimi，使用搜索引擎补充：

```bash
# 优先 Bing
https://www.bing.com/search?q=<url_encode(公司名称)>+电话+联系人
# 备选 Google
https://www.google.com/search?q=<url_encode(公司名称)>+电话+联系人
```

使用 `references/search-engines.md` 中的脚本提取搜索结果，查找与该公司名称匹配的电话和联系人信息。

### 3. 无法补充

如果天眼查和搜索引擎都得不到有效信息，在输出表格中标记为 `—`，状态列为“工商信息未找到”。

## Fallback 策略

当某个环节失败时，按以下顺序处理：

1. **搜索引擎被拦截** → 切换 Bing/Google；仍失败则提示用户稍后重试
2. **某个 factory 页面无法打开** → 记录失败，继续处理下一个 factory
3. **提取不到子域名** → 尝试从 factory 页面右侧"立即询价"表单提取手机号；仍失败则跳过
4. **contactinfo 被 Slider 拦截** → 提示用户手动完成验证，验证后继续；用户不愿验证则跳过
5. **contactinfo 被登录拦截** → 跳过该店铺，尝试下一家
6. **contactinfo 信息为空** → 优先使用天眼查（Kimi 可用时）补充工商信息；否则通过 Bing/Google 搜索 `"公司名称" 电话` 补充；仍失败则标记为信息不可获取

## 批量处理策略

- 每批处理 **3-5** 个 factory 页面（降低风控概率）
- 每个页面访问后加 **3-4 秒** 延迟
- 出现 Slider/拦截时，优先让用户完成验证，不要自动连续跳过
- 用同一 session 管理所有标签页，任务结束后可 `close_session` 清理

## 输出格式

以 Markdown 表格汇总所有提取结果。基础字段必备，无法获取的标记为 `—`：

### 基础信息表

| 公司 | 电话 | 手机 | 地址 | 联系人 | 店铺 | 状态 |
|------|------|------|------|--------|------|------|
| 邢台博扬轴承制造有限公司 | 86 0319 8568899 | 13739693628 | 河北省邢台市... | 柏天顺先生 | xybyzz.1688.com | 成功 |
| 永康市国一轴承有限公司 | — | — | — | — | shop970622u5n31i0.1688.com | Slider 验证待完成 |

## 常见问题

### Google 触发 reCAPTCHA / unusual traffic
- 默认使用 Bing 搜索
- 如 Bing 也触发，等待 10-15 秒后重试，或让用户切换网络

### 搜不到店铺子域名
- 部分 factory 页面可能没有独立的子域名店铺
- 尝试直接从 factory 页面提取电话/地址信息（右侧"立即询价"表单中常有手机号）

### Contactinfo 页面出现 Slider
- **必须提示用户手动拖动滑块完成验证**
- 验证完成后刷新页面继续提取
- 用户不愿验证则跳过该店铺

### Contactinfo 页面要求登录
- 该店铺无法直接获取联系方式
- 跳过并继续处理下一家

### 1688 检测到异常流量
- 增加延迟（5-10 秒）
- 减少每批处理数量（2-3 个）
- 等待 30-60 秒后重试

### 提取结果为空
- 1688 页面结构可能变化，尝试更通用的 evaluate 代码
- 使用 `document.body.innerText` 获取全部文本再筛选

### 联系人姓名缺失
- 部分 1688 店铺的 contactinfo 页面不展示具体联系人姓名
- **Kimi 优先调用天眼查数据**，按公司名称查询法定代表人/联系电话/企业地址
- 天眼查不可用时，通过 Bing 搜索 `"公司名称" 电话` 获取补充信息
- 非 Kimi 时直接使用 Bing/Google 搜索补充
