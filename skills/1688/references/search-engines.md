# 搜索引擎与拦截检测

## 默认策略

**优先使用 Bing**，仅在 Bing 失败或结果不足时回退到 Google。

| 搜索引擎 | 优点 | 缺点 |
|---------|------|------|
| Bing | 对 1688 factory 页面索引好，触发风控概率低 | 部分长尾词结果少于 Google |
| Google | 覆盖广 | 极易触发 unusual traffic / reCAPTCHA |

## Bing 搜索

### URL 模板

```
https://www.bing.com/search?q=site:1688.com/factory+<关键词>
```

示例：
- `site:1688.com/factory 轴承`
- `site:1688.com/factory 仓库货架`
- `site:1688.com/factory 五金加工 浙江`

### 结果提取

```javascript
(() => {
  const results = Array.from(document.querySelectorAll("li.b_algo"))
    .map(el => {
      const link = el.querySelector("a[href]");
      const title = el.querySelector("h2");
      return link && title
        ? { title: title.innerText.trim(), href: link.href }
        : null;
    })
    .filter(x => x && x.href.includes("1688.com/factory"));
  return JSON.stringify(results.slice(0, 15));
})()
```

## Google 搜索

### URL 模板

```
https://www.google.com/search?q=site:1688.com/factory+<关键词>
```

### 结果提取

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

## 拦截检测脚本

每次访问搜索页面后必须立即执行：

```javascript
(() => {
  const text = document.body.innerText;
  const title = document.title;
  const url = window.location.href;

  const blocked =
    text.includes("Our systems have detected unusual traffic") ||
    text.includes("unusual traffic") ||
    text.includes("reCAPTCHA") ||
    text.includes("Sorry, we have detected unusual traffic") ||
    url.includes("google.com/sorry");

  const reason = blocked
    ? text.includes("reCAPTCHA") ? "recaptcha" : "unusual_traffic"
    : null;

  return JSON.stringify({
    url,
    title,
    blocked,
    reason,
    preview: text.substring(0, 200)
  });
})()
```

### 处理策略

| 检测结果 | 处理方式 |
|---------|---------|
| Google blocked | 切换到 Bing |
| Bing blocked | 等待 10-15 秒重试；仍失败则提示用户更换网络或稍后重试 |
| 两者均 blocked | 暂停任务，提示用户当前网络触发搜索引擎风控 |

## 兜底提取

如果标准结果选择器失效，直接从页面所有链接中筛选：

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
