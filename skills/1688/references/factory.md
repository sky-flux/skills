# Factory 黄页信息提取

## 页面特征

1688 factory 黄页 URL 格式：

```
https://www.1688.com/factory/b2b-<id>.html
```

示例：
- `https://www.1688.com/factory/b2b-2206824085.html`

## 访问前检查

```bash
~/.kimi-webbridge/bin/kimi-webbridge status
```

## 提取店铺子域名

Factory 页面本身通常不直接展示完整联系方式，但可以提取店铺子域名，然后跳转到 `contactinfo.htm`。

### 方案 1：语义文本匹配（推荐）

1688 工厂黄页的标准入口文案是 **"进旺铺"**，基于 accessibility 语义定位比 DOM 结构路径更稳定。

```javascript
(() => {
  const link = Array.from(document.querySelectorAll("a"))
    .find(a => a.innerText.trim().includes("旺铺"));

  return JSON.stringify({
    found: !!link,
    href: link ? link.href : null,
    text: link ? link.innerText.trim() : null
  });
})()
```

典型结果：

```json
{
  "found": true,
  "href": "https://shop47qv684964q21.1688.com/?spm=...",
  "text": "进旺铺"
}
```

### 方案 2：子域名链接筛选

```javascript
(() => {
  const officialDomains = [
    "www.1688.com",
    "s.1688.com",
    "detail.1688.com",
    "sale.1688.com",
    "r.1688.com",
    "cx.1688.com",
    "auth.1688.com",
    "login.1688.com"
  ];

  const links = Array.from(document.querySelectorAll("a[href]"))
    .map(a => a.href)
    .filter(h => {
      const isSubdomain = /[a-zA-Z0-9_-]+\.1688\.com/.test(h);
      const isNotOfficial = !officialDomains.some(d => h.includes(d));
      return isSubdomain && isNotOfficial;
    });

  const unique = [...new Set(links)];
  return JSON.stringify(unique.slice(0, 5));
})()
```

### 方案 3：HTML 源码正则兜底

```javascript
(() => {
  const officialDomains = [
    "www.1688.com",
    "s.1688.com",
    "detail.1688.com",
    "sale.1688.com",
    "r.1688.com",
    "cx.1688.com",
    "auth.1688.com",
    "login.1688.com"
  ];

  const html = document.documentElement.innerHTML;
  const matches = html.match(/[a-zA-Z0-9_-]+\.1688\.com/g);
  const unique = [...new Set(matches || [])]
    .filter(d => !officialDomains.includes(d));

  return JSON.stringify(unique.slice(0, 5));
})()
```

## 提取主营产品

在 factory 黄页或旺铺首页提取 `mainProducts`，用于产品匹配评分和供应商数据库建设。

### 方案 1：页面文本匹配（推荐）

```javascript
(() => {
  const text = document.body.innerText;
  const lines = text.split(String.fromCharCode(10))
    .map(l => l.trim())
    .filter(l => l.length > 0 && l.length < 100);

  const patterns = [
    /主营产品[：:]\s*(.+)/,
    /主营[：:]\s*(.+)/,
    /主营行业[：:]\s*(.+)/,
    /产品分类[：:]\s*(.+)/,
    /主要产品[：:]\s*(.+)/
  ];

  const products = [];
  for (const p of patterns) {
    for (const line of lines) {
      const m = line.match(p);
      if (m && m[1]) {
        products.push(...m[1].split(/[,，、;；]/).map(s => s.trim()).filter(s => s.length > 1));
      }
    }
  }

  const unique = [...new Set(products)].slice(0, 20);
  return JSON.stringify({ url: window.location.href, mainProducts: unique });
})()
```

### 方案 2：从分类/标签区提取

```javascript
(() => {
  const selectors = [
    '[class*="category"]',
    '[class*="fenlei"]',
    '[class*="product-type"]',
    '[class*="main-product"]'
  ];
  const products = [];
  for (const s of selectors) {
    document.querySelectorAll(s).forEach(el => {
      const t = el.innerText.trim();
      if (t && t.length < 50) products.push(t);
    });
  }

  const links = Array.from(document.querySelectorAll('a'))
    .map(a => a.innerText.trim())
    .filter(t => /主营|产品|分类/.test(t) && t.length < 50);
  products.push(...links);

  const unique = [...new Set(products)].slice(0, 20);
  return JSON.stringify({ url: window.location.href, mainProducts: unique });
})()
```

**输出示例：**

```json
{
  "url": "https://www.1688.com/factory/b2b-xxx.html",
  "mainProducts": ["轴承", "深沟球轴承", "圆锥滚子轴承", "汽车轴承"]
}
```

提取到的 `mainProducts` 需持久化到供应商数据库，作为后续检索、分类和二次筛选字段。

## 提取公司公开信息

如果无法获取子域名，尝试从 factory 页面右侧"立即询价"表单提取公开手机号：

```javascript
(() => {
  const text = document.body.innerText;
  const lines = text.split(String.fromCharCode(10))
    .map(l => l.trim())
    .filter(l => l.length > 0);

  const phoneRegex = /1[3-9]\d{9}/g;
  const phones = [];
  for (const line of lines) {
    const matches = line.match(phoneRegex);
    if (matches) phones.push(...matches);
  }

  const unique = [...new Set(phones)];
  return JSON.stringify({
    url: window.location.href,
    mobileFromPage: unique.slice(0, 3)
  });
})()
```

## 构造 Contactinfo URL

从子域名构造联系方式页面 URL：

```
https://<子域名>/page/contactinfo.htm
```

例如子域名为 `jtn1688.1688.com`，则：

```
https://jtn1688.1688.com/page/contactinfo.htm
```

## 常见问题

### 页面无法打开或 tab 被关闭
部分 1688 页面会触发弹窗或重定向，导致 session tab 被关闭。如遇 `session tab was closed` 错误，重新执行一次 `navigate` 即可（建议使用新的 session 名）。

### 找不到"旺铺"链接
- 该 factory 可能没有独立旺铺
- 使用方案 2 或方案 3 从所有链接/源码中匹配
- 仍失败则跳过该 factory

### 页面被重定向到登录
- 跳过该 factory
- 继续处理下一个
