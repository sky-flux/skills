# CSS 效果食谱 & 组件模式

> Claude 生成 UI 代码时可直接复制的 CSS 片段、字体配对和页面 Section 模式。

---

## 1. 背景效果 (Background Effects)

### 1.1 渐变网格 (Mesh Gradient)

```css
.mesh-gradient {
  background:
    radial-gradient(at 0% 0%, oklch(0.75 0.18 250 / 0.3) 0, transparent 50%),
    radial-gradient(at 100% 0%, oklch(0.80 0.15 300 / 0.2) 0, transparent 50%),
    radial-gradient(at 80% 100%, oklch(0.70 0.12 180 / 0.15) 0, transparent 50%),
    var(--color-bg);
}
/* 暗色版 */
.mesh-gradient-dark {
  background:
    radial-gradient(at 20% 80%, oklch(0.35 0.15 250 / 0.4) 0, transparent 50%),
    radial-gradient(at 80% 20%, oklch(0.30 0.12 300 / 0.3) 0, transparent 50%),
    #0F172A;
}
```

### 1.2 噪点纹理 (Grain Texture)

```css
.grain {
  position: relative;
}
.grain::after {
  content: "";
  position: absolute; inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.04'/%3E%3C/svg%3E");
  pointer-events: none;
  z-index: 1;
}
```

### 1.3 毛玻璃 (Glassmorphism)

```css
.glass {
  background: rgba(255,255,255,0.15);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255,255,255,0.2);
  border-radius: var(--radius-lg);
  box-shadow: 0 4px 30px rgba(0,0,0,0.08);
}
/* 暗色版 */
.glass-dark {
  background: rgba(15,23,42,0.6);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(255,255,255,0.08);
}
/* 导航栏毛玻璃 */
.nav-glass {
  background: rgba(255,255,255,0.8);
  backdrop-filter: blur(12px) saturate(180%);
  border-bottom: 1px solid rgba(0,0,0,0.05);
}
```

### 1.4 斑点/圆形装饰 (Blob)

```css
.blob-bg {
  position: relative; overflow: hidden;
}
.blob-bg::before, .blob-bg::after {
  content: "";
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.5;
  z-index: 0;
}
.blob-bg::before {
  width: 400px; height: 400px;
  background: var(--color-primary);
  top: -100px; left: -100px;
  opacity: 0.15;
}
.blob-bg::after {
  width: 300px; height: 300px;
  background: oklch(0.7 0.15 300);
  bottom: -80px; right: -80px;
  opacity: 0.12;
}
```

### 1.5 网格点阵 (Dot Grid)

```css
.dot-grid {
  background-image: radial-gradient(circle, var(--color-border) 1px, transparent 1px);
  background-size: 24px 24px;
}
```

### 1.6 倾斜分割 (Slant Divider)

```css
.slant { clip-path: polygon(0 0, 100% 0, 100% 85%, 0 100%); }
.slant-reverse { clip-path: polygon(0 0, 100% 0, 100% 100%, 0 85%); }
```

### 1.7 动画渐变 (Animated Gradient)

```css
.animated-gradient {
  background: linear-gradient(-45deg, #ee7752, #e73c7e, #23a6d5, #23d5ab);
  background-size: 400% 400%;
  animation: gradientShift 12s ease infinite;
}
@keyframes gradientShift {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}
```

### 1.8 光晕效果 (Glow)

```css
.glow-primary {
  box-shadow: 0 0 20px oklch(0.55 0.22 250 / 0.3),
              0 0 60px oklch(0.55 0.22 250 / 0.1);
}
.glow-text {
  text-shadow: 0 0 10px oklch(0.55 0.22 250 / 0.5),
               0 0 40px oklch(0.55 0.22 250 / 0.2);
}
```

---

## 2. 微交互 (Micro-Interactions)

### 2.1 按钮 hover 升起

```css
.btn-lift {
  transition: all 150ms ease;
}
.btn-lift:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
}
.btn-lift:active {
  transform: translateY(0);
  box-shadow: var(--shadow-sm);
}
```

### 2.2 卡片 hover 浮起

```css
.card-hover {
  transition: all 200ms cubic-bezier(.4,0,.2,1);
}
.card-hover:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-xl);
}
```

### 2.3 入场动画 (Fade Up + Stagger)

```css
.fade-up {
  opacity: 0;
  transform: translateY(24px);
  animation: fadeUp 600ms cubic-bezier(.4,0,.2,1) forwards;
}
@keyframes fadeUp {
  to { opacity: 1; transform: translateY(0); }
}
.fade-up:nth-child(1) { animation-delay: 0ms; }
.fade-up:nth-child(2) { animation-delay: 100ms; }
.fade-up:nth-child(3) { animation-delay: 200ms; }
.fade-up:nth-child(4) { animation-delay: 300ms; }
```

### 2.4 Focus Ring

```css
:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}
```

### 2.5 Skeleton Loading

```css
.skeleton {
  background: linear-gradient(90deg, var(--color-surface-2) 25%, var(--color-surface) 50%, var(--color-surface-2) 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: var(--radius-md);
}
@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

---

## 3. 字体配对 (Font Pairings)

根据项目个性选择。每对都标注了 Google Fonts import URL。

### 3.1 现代/SaaS (最常用)

| 标题 | 正文 | 感觉 |
|------|------|------|
| **Inter** (600) | **Inter** (400) | 中性、专业、安全 |
| **Manrope** (700) | **Inter** (400) | 稍有个性的现代 |
| **DM Sans** (700) | **DM Sans** (400) | 圆润友好 |
| **Plus Jakarta Sans** (700) | **Inter** (400) | 几何但温暖 |

```html
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@500;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
```

### 3.2 大胆/创意

| 标题 | 正文 | 感觉 |
|------|------|------|
| **Space Grotesk** (700) | **Inter** (400) | 科技大胆 |
| **Sora** (700) | **DM Sans** (400) | 未来感 |
| **Outfit** (800) | **Source Sans 3** (400) | 几何力量 |

```html
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
```

### 3.3 优雅/editorial

| 标题 | 正文 | 感觉 |
|------|------|------|
| **Playfair Display** (700) | **Lato** (400) | 经典优雅 |
| **Cormorant Garamond** (600) | **Raleway** (400) | 文艺高端 |
| **DM Serif Display** (400) | **Nunito** (400) | 现代衬线 |

```html
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Lato:wght@400;700&display=swap" rel="stylesheet">
```

### 3.4 企业/严肃

| 标题 | 正文 | 感觉 |
|------|------|------|
| **IBM Plex Sans** (600) | **IBM Plex Sans** (400) | 企业级 |
| **Montserrat** (700) | **Source Sans 3** (400) | 经典商务 |

```html
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
```

### 3.5 活泼/年轻

| 标题 | 正文 | 感觉 |
|------|------|------|
| **Poppins** (700) | **Poppins** (400) | 圆润几何 |
| **Quicksand** (700) | **Nunito** (400) | 柔软亲切 |

```html
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
```

### 3.6 CJK (中文) 配对

标题和正文都用 Noto Sans SC，用字重区分层次。英文部分用拉丁 display 字体。

```html
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400;500;700&family=Space+Grotesk:wght@500;700&display=swap" rel="stylesheet">
```
```css
body { font-family: 'Noto Sans SC', 'PingFang SC', 'Microsoft YaHei', sans-serif; }
h1, h2, .heading-en { font-family: 'Space Grotesk', 'Noto Sans SC', sans-serif; }
```

---

## 4. Landing Page Section 食谱

一个完整 Landing Page 的标准 section 组合及关键 CSS 结构。

### 4.1 标准 Section 顺序

```
1. Nav (毛玻璃 sticky)
2. Hero (大标题 + 副标题 + CTA + 背景装饰)
3. Logo Cloud (合作客户/信任标识)
4. Feature Grid (3-4 列图标+标题+描述)
5. Bento Grid (大小不一的功能卡片)
6. Stats (大数字统计)
7. Testimonials (用户评价)
8. Pricing (价格方案对比)
9. FAQ (折叠问答)
10. CTA Section (行动号召)
11. Footer (链接+版权)
```

### 4.2 Pricing Section 结构

```html
<!-- 三列定价，中间突出 -->
<div class="pricing-grid" style="display:grid; grid-template-columns:repeat(3,1fr); gap:24px; align-items:center;">
  <!-- 普通方案 -->
  <div class="card" style="padding:32px; border:1px solid var(--color-border); border-radius:var(--radius-lg);">
    <p class="overline">Basic</p>
    <p style="font-size:var(--text-4xl); font-weight:700;">¥29<span style="font-size:var(--text-sm); color:var(--color-muted);">/月</span></p>
    <ul><!-- features --></ul>
    <button class="btn-secondary">选择方案</button>
  </div>
  <!-- 推荐方案 (突出) -->
  <div class="card" style="padding:40px 32px; background:var(--color-primary); color:white; border-radius:var(--radius-lg); transform:scale(1.05); box-shadow:var(--shadow-xl);">
    <span class="badge">最受欢迎</span>
    <p class="overline" style="color:rgba(255,255,255,0.7);">Pro</p>
    <p style="font-size:var(--text-4xl); font-weight:700;">¥79<span style="font-size:var(--text-sm); opacity:0.7;">/月</span></p>
    <ul><!-- features --></ul>
    <button style="background:white; color:var(--color-primary);">选择方案</button>
  </div>
  <!-- 高级方案 -->
  <div class="card"><!-- 同 Basic 结构 --></div>
</div>
```

### 4.3 Testimonial Section 结构

```html
<div style="display:grid; grid-template-columns:repeat(3,1fr); gap:24px;">
  <div class="card" style="padding:24px;">
    <p style="color:var(--color-muted); font-style:italic; line-height:1.6;">
      "产品体验非常流畅，团队效率提升了 40%。"
    </p>
    <div style="display:flex; align-items:center; gap:12px; margin-top:16px;">
      <div style="width:40px; height:40px; border-radius:50%; background:var(--color-primary-light);"></div>
      <div>
        <p style="font-weight:600; font-size:14px;">张明</p>
        <p style="color:var(--color-muted); font-size:13px;">CTO, 某科技公司</p>
      </div>
    </div>
  </div>
</div>
```

### 4.4 FAQ Section (折叠)

```html
<details style="border-bottom:1px solid var(--color-border); padding:16px 0;">
  <summary style="font-weight:600; cursor:pointer; list-style:none; display:flex; justify-content:space-between; align-items:center;">
    你们支持退款吗？
    <i data-lucide="chevron-down" style="width:20px;"></i>
  </summary>
  <p style="margin-top:12px; color:var(--color-muted); line-height:1.6;">
    购买后 14 天内可无条件退款。
  </p>
</details>
```

### 4.5 Stats Section

```html
<div style="display:grid; grid-template-columns:repeat(4,1fr); gap:32px; text-align:center;">
  <div>
    <p style="font-size:var(--text-4xl); font-weight:700; color:var(--color-text);">12,847</p>
    <p style="font-size:var(--text-sm); color:var(--color-muted);">活跃用户</p>
  </div>
  <div>
    <p style="font-size:var(--text-4xl); font-weight:700;">99.9%</p>
    <p style="font-size:var(--text-sm); color:var(--color-muted);">正常运行时间</p>
  </div>
  <!-- ... -->
</div>
```

### 4.6 Footer 结构

```
┌─────────────────────────────────────────┐
│  Logo + 一句品牌描述                      │
│                                         │
│  产品      公司      资源      法律       │
│  功能1     关于      博客      隐私       │
│  功能2     团队      文档      条款       │
│  定价      招聘      帮助      Cookie    │
│                                         │
│  ─────────────────────────────────────  │
│  © 2026 品牌名         社交图标 row       │
└─────────────────────────────────────────┘
```

4 列链接网格 + 底部版权行 + 社交图标。背景用 surface-2 或深色。

---

## 5. Tailwind CSS 速写模式

常用 Tailwind 类组合（给 Mode A 参考）：

```
/* 卡片 */
rounded-xl border bg-card p-6 shadow-sm hover:shadow-lg transition-shadow

/* 按钮 primary */
inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90

/* 按钮 secondary */
inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium hover:bg-accent

/* 按钮 ghost */
inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium hover:bg-accent hover:text-accent-foreground

/* 输入框 */
flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring

/* Badge */
inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold

/* 导航栏 */
sticky top-0 z-50 w-full border-b bg-background/80 backdrop-blur-sm

/* Section 容器 */
mx-auto max-w-7xl px-6 py-24 lg:px-8

/* 标题组 */
mx-auto max-w-2xl text-center
text-4xl font-bold tracking-tight sm:text-5xl
mt-4 text-lg text-muted-foreground
```

---

## 6. SVG 内联 Pattern (Hero Patterns 替代)

可直接内联到 CSS background-image 的 SVG pattern：

### 6.1 微点

```css
background-image: url("data:image/svg+xml,%3Csvg width='20' height='20' viewBox='0 0 20 20' xmlns='http://www.w3.org/2000/svg'%3E%3Ccircle cx='1' cy='1' r='1' fill='%23e2e8f0'/%3E%3C/svg%3E");
```

### 6.2 十字

```css
background-image: url("data:image/svg+xml,%3Csvg width='40' height='40' viewBox='0 0 40 40' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M20 18v4M18 20h4' stroke='%23e2e8f0' stroke-width='1' fill='none'/%3E%3C/svg%3E");
```

### 6.3 对角线

```css
background-image: url("data:image/svg+xml,%3Csvg width='6' height='6' viewBox='0 0 6 6' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M0 6L6 0' stroke='%23e2e8f0' stroke-width='0.5' fill='none'/%3E%3C/svg%3E");
```
