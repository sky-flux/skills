# Factory 页面 — 店铺子域名提取

从 `www.1688.com/factory/b2b-xxx.html` 页面提取店铺子域名（如 `jtn1688.1688.com`）。

## 方案 A：链接选择器（推荐）

提取页面中所有指向店铺子域名的链接：

```javascript
(() => {
  const links = Array.from(document.querySelectorAll("a[href]"))
    .map(a => a.href)
    .filter(h => {
      const isSubdomain = /[a-zA-Z0-9_-]+\.1688\.com/.test(h);
      const isNotOfficial = !h.includes("www.1688.com")
        && !h.includes("s.1688.com")
        && !h.includes("detail.1688.com")
        && !h.includes("sale.1688.com")
        && !h.includes("r.1688.com")
        && !h.includes("cx.1688.com");
      return isSubdomain && isNotOfficial;
    });
  const unique = [...new Set(links)];
  return JSON.stringify(unique.slice(0, 5));
})()
```

## 方案 B：正则匹配 HTML 源码

从完整 HTML 中匹配子域名模式：

```javascript
(() => {
  const html = document.documentElement.innerHTML;
  const matches = html.match(/[a-zA-Z0-9_-]+\.1688\.com/g);
  const exclude = [
    "www.1688.com", "s.1688.com", "detail.1688.com",
    "sale.1688.com", "r.1688.com", "cx.1688.com",
    "auth.1688.com", "login.1688.com"
  ];
  const unique = [...new Set(matches || [])]
    .filter(d => !exclude.includes(d));
  return JSON.stringify(unique.slice(0, 5));
})()
```

## 方案 C：提取公司基本信息

同时提取公司名和子域名：

```javascript
(() => {
  const html = document.documentElement.innerHTML;
  const domainMatches = html.match(/[a-zA-Z0-9_-]+\.1688\.com/g);
  const exclude = [
    "www.1688.com", "s.1688.com", "detail.1688.com",
    "sale.1688.com", "r.1688.com", "cx.1688.com"
  ];
  const domains = [...new Set(domainMatches || [])]
    .filter(d => !exclude.includes(d));

  const titleEl = document.querySelector("h1, title");
  const title = titleEl ? titleEl.innerText.trim() : "";
  const companyMatch = title.match(/^(.+?)-企业信息查询黄页/);
  const company = companyMatch ? companyMatch[1] : title;

  return JSON.stringify({ company, domains });
})()
```

## 输出示例

```json
{
  "company": "广州金铁牛货架有限公司",
  "domains": ["jtn1688.1688.com"]
}
```

## 备选：从询价表单提取手机号

部分 factory 页面的"立即询价"右侧表单会预填联系人手机号：

```javascript
(() => {
  const inputs = Array.from(document.querySelectorAll("input"));
  const phoneInput = inputs.find(i =>
    i.value && /^1[3-9]\d{9}$/.test(i.value.trim())
  );
  return JSON.stringify({
    mobile: phoneInput ? phoneInput.value.trim() : null
  });
})()
```
