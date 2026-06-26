# Contactinfo 页面联系方式提取

## 页面 URL

```
https://<子域名>.1688.com/page/contactinfo.htm
```

示例：
- `https://jtn1688.1688.com/page/contactinfo.htm`
- `https://shop970622u5n31i0.1688.com/page/contactinfo.htm`

## 访问前检查

每次访问 contactinfo 前，先确认 WebBridge 状态正常：

```bash
~/.kimi-webbridge/bin/kimi-webbridge status
```

## 拦截检测（必须先执行）

访问 contactinfo 后，**立即执行以下检测脚本**，判断页面是否被风控：

```javascript
(() => {
  const text = document.body.innerText;
  const title = document.title;
  const url = window.location.href;

  const blocked =
    text.includes("Please slide to verify") ||
    text.includes("请拖动滑块") ||
    text.includes("Captcha Interception") ||
    text.includes("Sorry, we have detected unusual traffic") ||
    text.includes("请登录") ||
    text.includes("Login") ||
    url.includes("login.1688.com");

  const blockType = text.includes("Please slide to verify") || text.includes("请拖动滑块")
    ? "slider"
    : text.includes("请登录") || url.includes("login.1688.com")
    ? "login"
    : text.includes("unusual traffic")
    ? "traffic"
    : null;

  return JSON.stringify({
    url,
    title,
    blocked,
    blockType,
    preview: text.substring(0, 300)
  });
})()
```

### 检测结果处理

| 状态 | 处理 |
|------|------|
| `blocked: false` | 继续提取联系方式 |
| `blockType: "slider"` | 提示用户手动拖动滑块验证，完成后刷新页面 |
| `blockType: "login"` | 跳过该店铺，继续下一家 |
| `blockType: "traffic"` | 增加延迟，等待 30-60 秒后重试；仍失败则跳过 |

## 结构化提取

```javascript
(() => {
  const sections = Array.from(document.querySelectorAll("section, div, table, ul, dl"));
  let contactSection = null;

  for (const s of sections) {
    if (s.innerText && s.innerText.includes("联系方式") &&
        (s.innerText.includes("电话") || s.innerText.includes("手机"))) {
      contactSection = s;
      break;
    }
  }

  if (!contactSection) contactSection = document.body;

  const text = contactSection.innerText;
  const lines = text.split(String.fromCharCode(10))
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

  const extract = (line, prefix) => {
    const idx = line.indexOf(prefix);
    return idx >= 0 ? line.slice(idx + prefix.length).trim() : null;
  };

  for (const line of lines) {
    if (line.includes("电话：") || line.includes("电话:")) {
      result.phone = extract(line, line.includes("电话：") ? "电话：" : "电话:");
    } else if (line.includes("手机：") || line.includes("手机:")) {
      result.mobile = extract(line, line.includes("手机：") ? "手机：" : "手机:");
    } else if (line.includes("传真：") || line.includes("传真:")) {
      result.fax = extract(line, line.includes("传真：") ? "传真：" : "传真:");
    } else if (line.includes("地址：") || line.includes("地址:")) {
      result.address = extract(line, line.includes("地址：") ? "地址：" : "地址:");
    } else if (line.includes("联系人：") || line.includes("联系人:")) {
      result.contactPerson = extract(line, line.includes("联系人：") ? "联系人：" : "联系人:");
    } else if (/^(.*先生|.*女士|.*经理|.*厂长)$/.test(line) &&
               !line.includes("欢迎") && !line.includes("问题")) {
      result.contactPerson = line;
    } else if (!result.company && line.length > 4 && line.length < 50 && !line.includes(":")) {
      result.company = line;
    }
  }

  return JSON.stringify(result);
})()
```

## 兜底提取

如果结构化提取没有命中，提取所有含联系方式关键词的行：

```javascript
(() => {
  const text = document.body.innerText;
  const lines = text.split(String.fromCharCode(10))
    .map(l => l.trim())
    .filter(l => l.length > 0 && l.length < 200);

  const keywords = ["电话", "手机", "传真", "地址", "联系人", "公司名称", "邮箱", "QQ", "微信"];
  const contactLines = lines.filter(l => keywords.some(k => l.includes(k)));

  return JSON.stringify({
    url: window.location.href,
    allContactLines: contactLines.slice(0, 30)
  });
})()
```

## 常见字段说明

| 字段 | 说明 | 示例 |
|------|------|------|
| 公司名称 | 页面顶部或联系信息区 | 邢台博扬轴承制造有限公司 |
| 电话 | 固定电话 | 86 0319 8568899 |
| 手机 | 手机号码 | 13739693628 |
| 传真 | 传真号码 | 86 0319 8568899 |
| 地址 | 公司地址 | 河北省邢台市临西县... |
| 联系人 | 姓名/称谓 | 柏天顺先生 |

## 已知问题

1. **部分店铺不展示具体联系人姓名** → 标记为 `—`
2. **Slider 验证** → 必须人工完成
3. **登录拦截** → 无法绕过，跳过
4. **部分字段缺失** → 用兜底提取补充
