# 自动滑块验证（Slider/CAPTCHA）解决方案

## 适用场景

当访问 1688 `contactinfo.htm` 页面时出现以下拦截：

- 页面标题为 "Captcha Interception"
- 页面文本包含 "Please slide to verify" / "请拖动滑块"
- 页面文本包含 "Sorry, we have detected unusual traffic from your network"

## 实现原理

通过 `evaluate` 在页面内直接触发原生 `MouseEvent` 事件序列（`mousedown` → 多个 `mousemove` → `mouseup`），模拟人类拖动滑块。

关键要点：
- 事件必须**直接 dispatch 在滑块 handle 元素**上（`#nc_1_n1z` / `.btn_slide`）
- 使用 ease-in-out 缓动 + 随机噪声，模拟人类移动轨迹
- 从检测到滑块到完成滑动释放的**总操作时间**控制在 **2-5 秒** 之间，服从随机正态分布（不能 < 2 秒）
  - 其中大部分时间为"人类反应/观察时间"（页面检测到滑块后等待 2-5 秒再开始拖动）
  - 实际拖动过程保持快速连续，以通过 1688 滑块校验
- 50 步左右的移动步数

## 自动滑动脚本

```javascript
(async () => {
  const handle = document.querySelector('#nc_1_n1z, .btn_slide');
  const track = document.querySelector('#nc_1_n1t, .nc_scale');

  if (!handle || !track) {
    return JSON.stringify({ success: false, error: 'slider elements not found' });
  }

  const hRect = handle.getBoundingClientRect();
  const tRect = track.getBoundingClientRect();
  const startX = hRect.left + hRect.width / 2;
  const startY = hRect.top + hRect.height / 2;
  const endX = tRect.left + tRect.width - hRect.width / 2;
  const distance = endX - startX;

  function sendEvent(type, x, y) {
    const event = new MouseEvent(type, {
      bubbles: true,
      cancelable: true,
      view: window,
      clientX: x,
      clientY: y,
      screenX: x + window.screenX,
      screenY: y + window.screenY,
      button: 0,
      buttons: type === 'mouseup' ? 0 : 1
    });
    handle.dispatchEvent(event);
  }

  function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // Box-Muller transform for normal distribution
  function randNormal(mean, stdDev) {
    let u = 0, v = 0;
    while (u === 0) u = Math.random();
    while (v === 0) v = Math.random();
    const z = Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v);
    return z * stdDev + mean;
  }

  // Total operation time from detection to completion: 2-5 seconds
  const minDuration = 2000;
  const maxDuration = 5000;
  let totalDuration = Math.round(randNormal(3500, 600));
  totalDuration = Math.max(minDuration, Math.min(maxDuration, totalDuration));

  // Human reaction time: wait before starting the slide
  const waitBefore = Math.round(totalDuration * 0.75);
  await sleep(waitBefore);

  // Execute the slide quickly and continuously
  const slideStart = Date.now();
  sendEvent('mousedown', startX, startY);

  const steps = 50;
  for (let i = 0; i <= steps; i++) {
    const t = i / steps;
    // easeInOutCubic
    const progress = t < 0.5
      ? 4 * t * t * t
      : 1 - Math.pow(-2 * t + 2, 3) / 2;
    const x = startX + distance * progress + (Math.random() - 0.5) * 2;
    const y = startY + (Math.random() - 0.5) * 3;
    sendEvent('mousemove', x, y);
  }

  sendEvent('mouseup', endX, startY);
  const slideTime = Date.now() - slideStart;

  return JSON.stringify({
    success: true,
    totalDuration,
    waitBefore,
    slideTime,
    startX: Math.round(startX),
    startY: Math.round(startY),
    endX: Math.round(endX),
    distance: Math.round(distance)
  });
})()
```

## 执行流程

1. 访问 contactinfo 页面后等待 3-4 秒
2. 执行拦截检测脚本
3. 如果检测到 Slider，执行上述自动滑动脚本
4. 等待 2-3 秒让页面刷新/跳转
5. 重新执行拦截检测脚本
6. 如果仍然被拦截，**刷新 contactinfo 页面并再次执行自动滑动脚本**（最多 5 次）
7. 如果 5 次后仍然失败，提示用户手动完成验证；用户不愿或无法验证则跳过该店铺

## 重试脚本

```javascript
(() => {
  const text = document.body.innerText;
  const blocked = text.includes("Please slide to verify") ||
                  text.includes("请拖动滑块") ||
                  text.includes("Captcha Interception");
  return JSON.stringify({ blocked });
})()
```

## 自动重试流程示例

```
for attempt in 1..5:
    执行 slider solver
    等待 2-3 秒
    检测是否仍被拦截
    if 通过:
        提取联系方式
        break
    else:
        if attempt < 5:
            刷新 contactinfo 页面
            等待 3-4 秒
        else:
            提示用户手动验证或跳过
```

## 注意事项

- 单次自动滑动成功率约 40-60%，通过 5 次重试可大幅提高整体通过率。
- 连续多次失败后建议暂停 30-60 秒再继续。
- 如果 1688 更新滑块实现（如更换 class name），需要同步更新 selector。
- 自动滑动仍可能失败，必须保留"提示用户手动验证"的 fallback。

## 备用 selector

如果默认 selector 失效，尝试：

```javascript
document.querySelector('#nc_1_n1z, .btn_slide, .nc_iconfont, [class*="slide"]')
document.querySelector('#nc_1_n1t, .nc_scale, [class*="scale"]')
```
