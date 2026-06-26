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
- `references/logistics-airports.md` — 主要空运口岸（机场海关）
- `references/logistics-seaports.md` — 主要海运口岸（港口海关）
- `references/logistics-land-ports.md` — 主要陆运口岸（边境/跨境关口）
- `references/logistics-scoring.md` — 基于口岸距离的工厂物流评分
- `references/factory-scoring.md` — 工厂综合评分与排序指南（信息完整度、工商可信度、规模、成立年限、产品匹配度、活跃度、合作伙伴、资质、风险）

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
Step 6: 提取公司名 + 店铺子域名链接 + 主营产品
    ↓
Step 7: 构造 contactinfo URL
    ↓
Step 8: 访问 contactinfo 页面
    ↓
Step 9: 检测 contactinfo 是否被拦截（Slider/CAPTCHA/登录）
    ↓
Step 10: 提取联系方式 或 执行 fallback/人工验证
    ↓
Step 11: 补充工商信息（天眼查优先，Bing/Google 备选）
    ↓
Step 12: 物流评分（计算到最近空/海/陆口岸距离）
    ↓
Step 13: 综合评分与排序（多维度打分，按总分降序）
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

## Step 6: 提取店铺子域名与主营产品

从 factory 页面提取两部分信息：
1. **店铺子域名链接**（格式：`xxx.1688.com`），用于构造 contactinfo URL。
2. **主营产品列表**，用于后续产品匹配评分和供应商数据库建设。

### 6.1 提取店铺子域名

**1688 工厂黄页的标准入口文案是"进旺铺"**，基于 accessibility 语义定位比 DOM 结构路径更稳定。

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

### 6.2 提取主营产品

在 factory 黄页或旺铺首页提取主营产品/主营类目，用于产品匹配评分和供应商数据库归档。

**方案 1：页面文本匹配（推荐）**

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const text = document.body.innerText; const lines = text.split(String.fromCharCode(10)).map(l => l.trim()).filter(l => l.length > 0 && l.length < 100); const patterns = [/主营产品[：:]\s*(.+)/, /主营[：:]\s*(.+)/, /主营行业[：:]\s*(.+)/, /产品分类[：:]\s*(.+)/, /主要产品[：:]\s*(.+)/]; const products = []; for (const p of patterns) { for (const line of lines) { const m = line.match(p); if (m && m[1]) { products.push(...m[1].split(/[,，、;；]/).map(s => s.trim()).filter(s => s.length > 1)); } } } const unique = [...new Set(products)].slice(0, 20); return JSON.stringify({url: window.location.href, mainProducts: unique}); })()"
    },
    "session": "1688-supplier-search"
  }'
```

**方案 2：从分类/标签区提取**

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "evaluate",
    "args": {
      "code": "(() => { const selectors = ['[class*=\"category\"]', '[class*=\"fenlei\"]', '[class*=\"product-type\"]', '[class*=\"main-product\"]']; const products = []; for (const s of selectors) { document.querySelectorAll(s).forEach(el => { const t = el.innerText.trim(); if (t && t.length < 50) products.push(t); }); } const links = Array.from(document.querySelectorAll('a')).map(a => a.innerText.trim()).filter(t => /主营|产品|分类/.test(t) && t.length < 50); products.push(...links); const unique = [...new Set(products)].slice(0, 20); return JSON.stringify({url: window.location.href, mainProducts: unique}); })()"
    },
    "session": "1688-supplier-search"
  }'
```

**输出示例：**

```json
{
  "url": "https://www.1688.com/factory/b2b-xxx.html",
  "mainProducts": ["轴承", "深沟球轴承", "圆锥滚子轴承", "汽车轴承"]
}
```

提取到的 `mainProducts` 需持久化到供应商数据库，作为后续检索、分类和二次筛选字段。

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

## Step 12: 物流评分（距离空/海/陆口岸）

对每个成功提取到地址的工厂，计算其到最近出口口岸的距离，作为工厂优先级的一个维度。

### 12.1 确定运输方式

| 用户明确需求 | 选用参考表 |
|-------------|-----------|
| 海运 / FCL / LCL / 大批量 / 低货值 | `references/logistics-seaports.md` |
| 空运 / 快递 / 高货值 / 急单 | `references/logistics-airports.md` |
| 陆运 / 中亚 / 俄罗斯 / 东南亚陆路 / 中欧班列 | `references/logistics-land-ports.md` |
| 未指定 | 同时计算三种方式，取最高口岸距离分 |

### 12.2 解析工厂地址

从 Step 10 的 `address` 字段提取：
- 省份/直辖市/自治区
- 城市/地级市（如有）

### 12.3 计算距离分

根据 `references/logistics-scoring.md`：

```
若工厂经纬度已知：
  distance_km ≈ sqrt((dLat * 111)^2 + (dLon * 111 * cos(lat * π/180))^2)
  按距离区间映射 0-10 分

若只有省份：
  同省/同城市 → 8-10 分
  邻近省份 → 4-6 分
  较远省份 → 1-3 分
  无法解析 → 0 分
```

### 12.4 目标市场加权（可选）

若用户指定目标市场，匹配对应方向的口岸，得分 × 1.2（上限 10）：

| 目标市场 | 优先方向 |
|---------|---------|
| 欧美/中东/非洲 | 海运/空运 |
| 中亚/俄罗斯 | 陆运口岸（阿拉山口、霍尔果斯、二连浩特、满洲里） |
| 东南亚 | 海运/陆运（凭祥、东兴、磨憨） |
| 日韩 | 海运/空运 |
| 南亚 | 陆运（红其拉甫、吉隆） |

### 12.5 输出字段

在结果表格中增加以下列：

| 列名 | 说明 |
|------|------|
| `省份` | 工厂所在省份 |
| `最近口岸` | 距离最近的口岸名称 |
| `运输方式` | air / sea / land |
| `物流距离分` | 0-10 |
| `物流优先级` | 高（8-10）/ 中（4-7）/ 低（0-3） |

### 12.6 物流分的用途

物流距离分（0-10）作为工厂综合评分的一个维度输入，详见 Step 13。

## Step 13: 综合评分与排序

对每家工厂按 `references/factory-scoring.md` 进行多维度打分，最终按总分降序输出。

### 13.1 评分维度与默认权重

| 维度 | 权重 | 关键数据来源 |
|------|------|-------------|
| 信息完整度 | 18.5% | 1688 contactinfo / 店铺页（电话、手机、地址、联系人、邮箱等） |
| 企业官网 | 1.5% | 1688 店铺页 / 搜索引擎 / 天眼查（独立官网、可访问性、内容丰富度） |
| 域名注册时间 | 1% | WHOIS / 域名注册信息 |
| 工商可信度 | 15% | 天眼查（Kimi）/ Google / Bing（存续状态、注册资本、法人、参保人数、交叉验证） |
| 公司规模与实力 | 15% | 天眼查 / 1688 店铺页（参保人数、注册资本、厂房面积、年营业额） |
| 工厂成立时长 | 10% | 天眼查成立日期 |
| 1688 店铺开店时长 | 5% | 1688 店铺页开店时间 |
| 产品匹配度 | 15% | 1688 factory 页与搜索关键词匹配程度 |
| 物流距离 | 15% | Step 12 计算的口岸距离分 |
| 1688 活跃度 | 5% | 店铺等级、响应率、近 90 天成交、回头率 |
| 合作伙伴/客户背书 | 3% | 是否给大牌代工、自主品牌、出口经验、客户案例 |
| 资质认证 | 1% | ISO、CE、FDA、SGS 等证书 |
| 风险扣分 | - | 经营异常、司法诉讼、行政处罚、失信记录、交叉验证矛盾等 |

### 13.2 关键区别

- **工厂成立时长**：企业工商注册成立时间，反映公司历史和稳定性。
- **1688 店铺开店时长**：在 1688 平台开店的年限，反映线上运营经验和平台信誉。
- **域名注册时间**：官网域名注册年限，反映线上品牌沉淀时间。
- **企业官网**：是否有独立官网、官网质量，用于判断企业实力和正规程度。
- **合作伙伴关系**：给大牌代工、有自主品牌、出口大客户经验等，均属于客户背书。
- **Google/Bing 交叉验证**：通过搜索引擎验证公司名、电话、地址、官网是否一致，发现矛盾信息则降权。

### 13.3 最终排序规则

1. 按 **最终总分降序**。
2. 总分相同：
   - 产品匹配度高的优先
   - 物流距离分高的优先
   - 信息完整度高的优先
   - 工厂成立时间长的优先
3. 用户明确偏好时，按 `references/factory-scoring.md` 调整权重后再排序。

### 13.4 输出字段

在结果表格中增加：

| 列名 | 说明 |
|------|------|
| `产品匹配` | 0-10 |
| `工商可信` | 0-10 |
| `规模` | 0-10 |
| `成立` | 0-10 |
| `1688店龄` | 0-10 |
| `物流` | 0-10 |
| `活跃` | 0-10 |
| `合作背书` | 0-10 |
| `官网` | 0-10 |
| `域名` | 0-10 |
| `风险扣分` | 负分 |
| `总分` | 0-10 |
| `优先级` | 高 / 中 / 低 |

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

| 公司 | 主营产品 | 电话 | 手机 | 地址 | 联系人 | 店铺 | 最近口岸 | 运输方式 | 物流分 | 状态 |
|------|---------|------|------|------|--------|------|---------|---------|--------|------|
| 邢台博扬轴承制造有限公司 | 轴承、深沟球轴承 | 86 0319 8568899 | 13739693628 | 河北省邢台市... | 柏天顺先生 | xybyzz.1688.com | 天津港 | 海运 | 6 | 成功 |
| 永康市国一轴承有限公司 | 滚子轴承 | — | — | — | — | shop970622u5n31i0.1688.com | — | — | 0 | Slider 验证待完成 |

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
