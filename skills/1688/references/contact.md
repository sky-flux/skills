# Contactinfo 页面 — 联系方式提取

从 `xxx.1688.com/page/contactinfo.htm` 提取公司联系方式。

## 方案 A：结构化提取（推荐）

按字段分类提取：

```javascript
(() => {
  const sections = Array.from(document.querySelectorAll("section, div, table, ul, dl"));
  let contactSection = null;
  for (const s of sections) {
    const text = s.innerText || "";
    if (text.includes("联系方式") && (text.includes("电话") || text.includes("手机"))) {
      contactSection = s;
      break;
    }
  }
  if (!contactSection) contactSection = document.body;

  const text = contactSection.innerText;
  const lines = text.split(/\n/)
    .map(l => l.trim())
    .filter(l => l.length > 0 && l.length < 200);

  const result = {
    url: window.location.href,
    company: null,
    phone: null,
    mobile: null,
    fax: null,
    address: null,
    contactPerson: null
  };

  for (const line of lines) {
    if (line.includes("电话：") || line.includes("电话:")) {
      result.phone = line.replace(/.*电话[：:]\s*/, "").trim();
    } else if (line.includes("手机：") || line.includes("手机:")) {
      result.mobile = line.replace(/.*手机[：:]\s*/, "").trim();
    } else if (line.includes("传真：") || line.includes("传真:")) {
      result.fax = line.replace(/.*传真[：:]\s*/, "").trim();
    } else if (line.includes("地址：") || line.includes("地址:")) {
      result.address = line.replace(/.*地址[：:]\s*/, "").trim();
    } else if ((line.includes("先生") || line.includes("女士")) && !line.includes("欢迎")) {
      result.contactPerson = line;
    } else if (!result.company && line.length > 4 && line.length < 50 && !line.includes(":")) {
      result.company = line;
    }
  }

  return JSON.stringify(result);
})()
```

## 方案 B：兜底全文本提取

如果结构化提取失败，返回所有含关键词的行：

```javascript
(() => {
  const text = document.body.innerText;
  const lines = text.split(/\n/)
    .map(l => l.trim())
    .filter(l => l.length > 0 && l.length < 200);
  const contactLines = lines.filter(l =>
    /电话|手机|传真|地址|联系人|公司|邮箱|Email|QQ|微信/.test(l)
  );
  return JSON.stringify({
    url: window.location.href,
    allContactLines: contactLines.slice(0, 30)
  });
})()
```

## 方案 C：正则批量匹配

用正则一次性匹配所有联系方式：

```javascript
(() => {
  const text = document.body.innerText;
  const mobiles = [...new Set(text.match(/1[3-9]\d{9}/g) || [])];
  const tels = [...new Set(text.match(/0\d{2,3}[-\s]?\d{7,8}/g) || [])];
  const emails = [...new Set(text.match(/[\w.-]+@[\w.-]+\.\w+/g) || [])];
  const qqMatches = [...new Set(text.match(/QQ[:：\s]*(\d{5,11})/gi) || [])];

  return JSON.stringify({
    url: window.location.href,
    mobiles,
    tels,
    emails,
    qq: qqMatches
  });
})()
```

## 输出示例

```json
{
  "url": "https://jtn1688.1688.com/page/contactinfo.htm",
  "company": "广州金铁牛货架有限公司",
  "phone": "86",
  "mobile": "13226677779",
  "fax": "暂无",
  "address": "广东省广州市花都区炭步镇花都大道西249号",
  "contactPerson": "王国安先生"
}
```

## 输出格式建议

最终汇总时使用 Markdown 表格：

```markdown
| 公司 | 电话 | 手机 | 地址 | 联系人 | 店铺 |
|------|------|------|------|--------|------|
| 广州金铁牛货架有限公司 | 86 | 13226677779 | 广东省广州市花都区... | 王国安先生 | jtn1688.1688.com |
```
