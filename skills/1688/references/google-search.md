# Google 搜索结果提取 — 1688 Factory URL

从 Google 搜索结果页面提取所有 `www.1688.com/factory/` 链接。

## 方案 A：精准提取（推荐）

匹配 Google 搜索结果卡片，提取标题和链接：

```javascript
(() => {
  const results = Array.from(document.querySelectorAll("div.g, div[data-ved]"))
    .map(el => {
      const link = el.querySelector("a[href]");
      const title = el.querySelector("h3");
      return link && title
        ? { title: title.innerText.trim(), href: link.href }
        : null;
    })
    .filter(x => x && x.href.includes("1688.com/factory"));
  return JSON.stringify(results.slice(0, 15));
})()
```

## 方案 B：兜底提取

如果页面结构变化，直接从所有链接中筛选：

```javascript
(() => {
  const links = Array.from(document.querySelectorAll("a[href]"))
    .filter(a => a.href.includes("1688.com/factory"))
    .map(a => ({
      text: a.innerText.trim().substring(0, 80),
      href: a.href
    }));
  return JSON.stringify(links.slice(0, 15));
})()
```

## 方案 C：含分页翻页

提取当前页结果 + 下一页链接：

```javascript
(() => {
  const results = Array.from(document.querySelectorAll("div.g, div[data-ved]"))
    .map(el => {
      const link = el.querySelector("a[href]");
      const title = el.querySelector("h3");
      return link && title
        ? { title: title.innerText.trim(), href: link.href }
        : null;
    })
    .filter(x => x && x.href.includes("1688.com/factory"));

  const nextPage = Array.from(document.querySelectorAll("a[href]"))
    .find(a => a.innerText.includes("下一页") || a.innerText.includes("Next"));

  return JSON.stringify({
    results: results.slice(0, 15),
    nextPage: nextPage ? nextPage.href : null
  });
})()
```

## 输出示例

```json
[
  {
    "title": "山东万宇轴承有限公司-企业信息查询黄页-阿里巴巴",
    "href": "https://www.1688.com/factory/b2b-29294048408fb97.html"
  },
  {
    "title": "山东新派轴承制造有限公司-企业信息查询黄页-阿里巴巴",
    "href": "https://www.1688.com/factory/b2b-22149726270338e493.html"
  }
]
```
