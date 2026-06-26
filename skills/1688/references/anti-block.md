# 反拦截与人工验证指南

## 核心原则

1688 和搜索引擎都有反爬/风控机制。本 Skill 的设计目标是：

1. **识别每一次拦截**，并给出可执行的绕过方案。
2. **不追求 100% 成功率**，但要求每次遇到拦截都能正确处理。
3. **优先使用 Bing 搜索**，Google 仅作为备选。
4. **每个页面访问后加 3-4 秒延迟**。
5. **contactinfo 出现 Slider/CAPTCHA 时，提示用户手动完成验证**。

## 拦截类型速查

| 页面 | 拦截标志 | 类型 | 处理方式 |
|------|---------|------|---------|
| Google | "Our systems have detected unusual traffic" / "reCAPTCHA" / `google.com/sorry` | 搜索引擎风控 | 切换到 Bing |
| Bing | 页面空白/异常/无结果 | 搜索引擎风控 | 等待 10-15 秒重试；仍失败提示用户换网络 |
| 1688 factory | 重定向到 login.1688.com | 登录拦截 | 跳过 |
| 1688 contactinfo | "Please slide to verify" / "请拖动滑块" | Slider 验证 | 提示用户手动完成，完成后刷新 |
| 1688 contactinfo | "请登录" / URL 含 login.1688.com | 登录拦截 | 跳过 |
| 1688 任意页面 | "Sorry, we have detected unusual traffic" | 流量风控 | 增加延迟，等待 30-60 秒重试 |

## 延迟策略

```
搜索页面加载后：等待 3-4 秒
factory 页面加载后：等待 3-4 秒
contactinfo 页面加载后：等待 3-4 秒
同一 session 连续访问多个页面：每个页面间 3-4 秒
遇到风控后重试：等待 30-60 秒
```

批量处理建议：
- 每批 3-5 个 factory 页面
- 出现 Slider 时优先处理，不要连续跳过

## 搜索引擎拦截检测

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

## 1688 Contactinfo 拦截检测

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

  const blockType =
    text.includes("Please slide to verify") || text.includes("请拖动滑块")
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

## Slider 验证处理流程

当 contactinfo 页面检测到 Slider 时：

1. **立即停止自动提取**
2. **向用户说明情况**：
   > 当前 1688 触发了滑块验证（"Please slide to verify"）。请在浏览器中手动拖动滑块完成验证，完成后告诉我，我会继续提取联系方式。
3. **等待用户确认**
4. **刷新页面**：
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
5. **重新执行拦截检测**
6. **若验证通过，继续提取联系方式**
7. **若用户不愿验证或验证失败，跳过该店铺**

## Fallback 优先级

当某个环节失败时，按以下顺序处理：

1. **搜索引擎被拦截** → 切换 Bing/Google；仍失败提示用户稍后重试
2. **factory 页面无法打开** → 记录失败，继续下一个
3. **提取不到子域名** → 尝试从页面提取手机号；仍失败跳过
4. **contactinfo 被 Slider 拦截** → 提示用户手动验证；验证后继续
5. **contactinfo 被登录拦截** → 跳过
6. **contactinfo 信息为空** → 尝试 Bing 搜索补充；仍失败标记不可获取

## 避免触发风控的建议

- 不要连续快速访问多个页面
- 每个请求间隔 3-4 秒
- 每批处理不超过 5 个 factory
- 出现 Slider 后，验证完成前不要继续请求新页面
- 如果连续多个页面触发风控，暂停任务 1-2 分钟

## 常见误区

- ❌ 尝试自动绕过 Slider（会进一步触发风控）
- ❌ 同一 IP 快速连续请求多个 contactinfo 页面
- ❌ 忽略 Google unusual traffic 警告继续使用 Google
- ✅ 遇到 Slider 立即提示用户手动验证
- ✅ 默认使用 Bing 搜索
- ✅ 失败后优雅跳过并继续下一个
