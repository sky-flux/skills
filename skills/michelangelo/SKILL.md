---
name: michelangelo
description: >
  Generate beautiful UI prototypes and production-ready React projects from natural language.
  Supports two modes: (1) React + Tailwind v4 + shadcn/ui project scaffold with real component
  files, oklch design tokens, and proper project structure; (2) self-contained HTML prototype
  with CSS custom properties, zero dependencies, opens directly in browser.
  Use for ANY UI request: "设计", "原型", "做个页面", "UI", "prototype", "landing page",
  "dashboard", "mock up", "React project", "shadcn", "Tailwind", "show me what it looks like".
  Always use this skill over ad-hoc HTML — output quality is dramatically better.
---

# Michelangelo

> "I saw the angel in the marble and carved until I set him free."

两种模式，同一套设计思维。先掌握设计原则，再写一行代码。

---

## Step 0: 判断输出模式

| 用户说 | 模式 |
|--------|------|
| "做个原型" / "preview" / "show me" / "快速看看效果" | **Mode B: HTML Prototype** |
| "生成 React 项目" / "shadcn" / "Tailwind" / "要写代码" / "真实项目" | **Mode A: React + Tailwind + shadcn** |
| 模糊不清 | 默认 **Mode B**，完成后提示可以生成 Mode A |

---

## Step 1: 设计思维（写代码前必须完成）

### 1.1 判断设计类型

| 类型 | 特征 | 画布宽度 | 内容区 | 高度 |
|------|------|---------|--------|------|
| **Landing Page** | 营销/产品介绍，需滚动 | 1440px | 1200px 居中 | 长页面，Section 间 80-96px |
| **Dashboard** | 数据/管理，侧边栏+内容区 | 1440px | 100% - sidebar(240px) | 全屏 900px |
| **Single Screen** | 单一任务：登录、表单 | 1440px (桌面) | 居中卡片 400-480px | 垂直居中 |
| **Mobile Screen** | 手机 App 页面 | **390×844** | 全宽，padding 16px | 含状态栏+安全区 |
| **Mobile (兼容)** | 兼容旧设备 | **375×812** | 全宽 | iPhone SE 基准 |
| **平板** | iPad 等 | 768-1024px | 720-960px | 响应式 |
| **小程序** | 微信小程序 | 375×812 (或 750×1624 @2x) | 全宽 | 含导航栏 88rpx |
| **邮件模板** | EDM/营销邮件 | **600px** | 600px | 1500-2000px |
| **社交图片** | 公众号/小红书/抖音 | 按平台 | 见 references/design-sizes.md | — |

详细的设备尺寸、社交媒体尺寸、组件尺寸见 `references/design-sizes.md`。

⚠️ "移动端登录页" = 390×844 的真实 App 界面，**不是**桌面页里嵌手机 Mockup 框。

### 1.2 确定设计个性 (Personality)

每个项目必须选择明确的个性方向，这决定了字体、颜色、圆角、间距的全部取值：

| 个性 | 字体 | 圆角 | 色调 | 留白 |
|------|------|------|------|------|
| **严肃/企业** | 衬线标题 + 无衬线正文 | 小 (4-8px) | 深蓝/藏青 | 宽松 |
| **友好/SaaS** | 圆润无衬线 (如 DM Sans) | 中 (8-12px) | 蓝/紫/青 | 适中 |
| **大胆/创意** | 粗重几何字体 | 大或无 (16px/0) | 高饱和对比 | 极端 |
| **优雅/奢华** | 衬线 + 细体 | 小 (4px) | 黑/金/米白 | 极宽松 |
| **活泼/年轻** | 圆体/手写感 | 大 (16-24px) | 多彩撞色 | 紧凑 |

**绝不能没有个性。** 没有明确个性的 UI = 千篇一律的 AI 风格。

### 1.3 反模式快速检查

写代码前心里过一遍（详见 `references/design-guide.md` 第 11 节）：

- ❌ 所有元素同等重要（无视觉层次）
- ❌ 过多边框分隔（应用背景色差/间距/阴影代替）
- ❌ 颜色均匀分布（应有 60-30-10 比例）
- ❌ 千篇一律的蓝色主题
- ❌ 大段 Lorem ipsum 式占位文字
- ❌ 按钮全用同一样式（缺少 primary/secondary/tertiary 层级）
- ❌ 纯白背景 + 纯黑文字（应微调色温）
- ❌ 间距随意（应基于 4px/8px 系统）
- ❌ 所有卡片完全一样大小一样样式

### 1.4 选择图标库

不要每次都用 Lucide。Lucide 已成为 AI 生成 UI 的默认图标，导致产品视觉雷同。根据项目需求选择：

| 场景 | 推荐 | 包名 / CDN |
|------|------|-----------|
| shadcn/ui 默认 | **Lucide** (1,500+) | `lucide-react` · CDN: `unpkg.com/lucide@latest` |
| 需要视觉层次变化 | **Phosphor** (9,000+, 6种字重含 duotone) | `@phosphor-icons/react` · CDN: `unpkg.com/@phosphor-icons/web@latest` |
| Dashboard / 大量图标 | **Tabler** (5,900+ 免费) | `@tabler/icons-react` · CDN: `cdn.jsdelivr.net/npm/@tabler/icons@latest` |
| 想避免 "AI 味" | **Iconoir** (1,600+) 或 **Remix Icon** (2,800+ line+fill) | `iconoir-react` / `remixicon-react` |
| Tailwind 原生 | **Heroicons** (316, 小而精) | `@heroicons/react` |
| 一个包用所有库 | **Iconify** (200,000+ 跨 100+ 库) | `@iconify/react` |
| 企业/B2B 感 | **Carbon Icons** (IBM) | `@carbon/icons-react` |
| 最大多风格库 (付费) | **Hugeicons** (46,000+, 10 种风格) | `hugeicons-react` |

详见 `references/icon-libraries.md` 获取完整安装命令和用法示例。

---

## Step 2: 视觉层次体系（核心中的核心）

视觉层次是设计好坏的决定因素。不是所有元素都同等重要。

### 2.1 控制层次的三把武器

**不要只靠字号！** 同时使用：

| 维度 | 主要信息 | 次要信息 | 辅助信息 |
|------|---------|---------|---------|
| **字号** | 大 (20-48px) | 中 (14-16px) | 小 (12-13px) |
| **字重** | Bold/Semibold (600-700) | Medium (500) | Regular (400) |
| **颜色明度** | 深色 (#0F172A) | 中灰 (#64748B) | 浅灰 (#94A3B8) |

**关键：弱化次要信息比强化主要信息更有效。**

### 2.2 按钮层级

每个页面最多 1 个 primary action，几个 secondary，其余 tertiary：

```css
.btn-primary { background: var(--color-primary); color: white; font-weight: 600; }
.btn-secondary { background: transparent; color: var(--color-primary);
  border: 1.5px solid var(--color-primary); }
.btn-tertiary { background: none; color: var(--color-primary); text-decoration: underline; }
/* 破坏性操作不是 primary 时用 secondary 样式；只在确认弹窗中用红色 primary */
```

### 2.3 标签弱化

能不用标签就不用。数据格式本身能说明含义时直接展示值。
必须用标签时，弱化标签（浅色/小字），强调值。

---

## Step 3: 色彩系统

> 详细的色彩系统架构、工具清单、预设方案见 `references/color-system.md`

### 3.1 完整色板

每个语义色需 8-10 级色阶。5 个 hex 不够用。

### 3.2 品牌色（不要每次用蓝色！）

| 行业 | 色 | Hex |
|------|---|-----|
| 科技/SaaS | 蓝 | #2563EB |
| 创意/设计 | 橙 | #F97316 |
| 金融/企业 | 深蓝 | #0F4C81 |
| 健康/医疗 | 青 | #0D9488 |
| 教育 | 紫 | #7C3AED |
| 电商 | 玫红 | #E11D48 |
| 环保 | 绿 | #16A34A |
| 暗黑主题 | — | bg #0F172A + accent #60A5FA |

### 3.3 灰色带色温

冷灰 (#64748B 带蓝) → 科技感 · 暖灰 (#78716C 带棕) → 友好感

### 3.4 色彩比例 60-30-10

60% 主背景 · 30% 辅助面 · 10% 强调色

### 3.5 无障碍

正文 4.5:1 · 大标题 3:1 · 不在彩色背景上用灰色文字

---

## Step 4: 布局与间距

### 4.1 间距系统 (4px grid)

```css
--sp-1:4px; --sp-2:8px; --sp-3:12px; --sp-4:16px; --sp-5:20px; --sp-6:24px;
--sp-8:32px; --sp-10:40px; --sp-12:48px; --sp-16:64px; --sp-20:80px; --sp-24:96px;
```

**从"太多留白"开始，然后逐步减少。**

### 4.2 间距表达归属

相关元素靠近 (8-12px)，不相关元素拉远 (24-48px)。标题紧跟下方内容。

### 4.3 内容宽度

文字行宽 45-75 字符 (max-width: 65ch)。内容区 max-width 1200px。不要填满屏幕。

---

## Step 5: 排版进阶

> 按项目个性分类的字体配对方案（含 Google Fonts import 代码）见 `references/css-recipes.md` 第 3 节

### 5.1 字体选择

**字重 ≥ 5 的字体通常更精良。**

| 用途 | Latin | CJK |
|------|-------|-----|
| 标题 | Space Grotesk, DM Sans, Outfit, Sora, Manrope | Noto Sans SC Medium/Bold |
| 正文 | Inter, Source Sans 3, IBM Plex Sans | Noto Sans SC Regular |

**CJK 文字绝不用 Space Grotesk 等拉丁 display 字体。**

### 5.2 行高随字号变化

大标题 1.1-1.2 · 中标题 1.2-1.3 · 正文 1.5-1.6 · CJK 标题 1.3-1.4 · CJK 正文 1.6-1.8

### 5.3 字间距

大标题 -0.5px · 全大写 +1px 且 font-size 缩 15% · CJK 绝不用负值

### 5.4 文案长度

Hero 2-6 词 · 副标题 ≤15 词 · Feature ≤20 词 · 按钮 1-3 词 · 不写 3 句以上段落

---

## Step 6: 深度与阴影

### 6.1 双层阴影

```css
--shadow-sm: 0 1px 3px rgba(0,0,0,.06), 0 1px 2px rgba(0,0,0,.04);
--shadow-md: 0 4px 6px -1px rgba(0,0,0,.07), 0 2px 4px -2px rgba(0,0,0,.05);
--shadow-lg: 0 10px 15px -3px rgba(0,0,0,.08), 0 4px 6px -4px rgba(0,0,0,.05);
--shadow-xl: 0 20px 25px -5px rgba(0,0,0,.10), 0 8px 10px -6px rgba(0,0,0,.05);
```

### 6.2 边框替代

优先用：背景色差 · 阴影 · 间距 · accent border (border-left: 3px solid)

---

## Step 7: 精修技法

> 更多 CSS 效果代码（毛玻璃/噪点/光晕/动画渐变/骨架屏）、字体配对方案、Landing Page Section 模板见 `references/css-recipes.md`

### 7.1 Accent Borders

```css
.card-accent { border-left: 4px solid var(--color-primary); }
```

### 7.2 背景装饰（纯色背景太平）

```css
/* 渐变网格 */
.hero-bg {
  background:
    radial-gradient(at 20% 80%, oklch(0.75 0.15 250 / 0.3) 0, transparent 50%),
    radial-gradient(at 80% 20%, oklch(0.80 0.12 300 / 0.2) 0, transparent 50%),
    var(--color-bg);
}
/* 噪点纹理 */
.textured {
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.04'/%3E%3C/svg%3E");
}
```

也可用 HeroPatterns.com 的 SVG pattern · 倾斜 clip-path 色块

### 7.3 空状态

空状态 = 图标 + 说明文字 + 行动按钮

### 7.4 交互状态

每个可交互元素必须有 hover/focus/active：
```css
.btn:hover { transform: translateY(-1px); box-shadow: var(--shadow-md); }
.card:hover { box-shadow: var(--shadow-lg); transform: translateY(-2px); }
.btn:focus-visible { outline: 2px solid var(--color-primary); outline-offset: 2px; }
```

---

## Step 8: 动效与动画

### 8.1 动效哲学

- 一个精心编排的页面加载 + staggered reveals (animation-delay) 比满页散落的 hover 微交互更有记忆点
- 动效服务于内容，不是装饰。每个动效必须有存在理由
- 使用 spring physics 替代 linear/ease：更自然，有弹性感

### 8.2 CSS 动效（Mode B 首选）

```css
/* Staggered reveal */
@keyframes fadeUp {
  from { opacity: 0; transform: translateY(20px); }
  to   { opacity: 1; transform: translateY(0); }
}
.reveal { animation: fadeUp 0.5s ease forwards; opacity: 0; }
.reveal:nth-child(2) { animation-delay: 0.1s; }
.reveal:nth-child(3) { animation-delay: 0.2s; }

/* Spring-like bounce (CSS 近似) */
@keyframes springIn {
  0%   { transform: scale(0.85); opacity: 0; }
  60%  { transform: scale(1.05); }
  100% { transform: scale(1);    opacity: 1; }
}
```

### 8.3 React 动效（Mode A）

```
pnpm add motion
```

```jsx
import { motion } from 'motion/react'

// 列表 staggered
const container = { hidden: {}, show: { transition: { staggerChildren: 0.1 } } }
const item = { hidden: { opacity: 0, y: 20 }, show: { opacity: 1, y: 0 } }

<motion.ul variants={container} initial="hidden" animate="show">
  {items.map(i => <motion.li key={i} variants={item}>{i}</motion.li>)}
</motion.ul>

// Spring 物理
<motion.div whileHover={{ scale: 1.03 }} transition={{ type: 'spring', stiffness: 300, damping: 20 }} />
```

### 8.4 禁止

- ❌ 每个元素都加 transition（视觉噪音）
- ❌ duration > 600ms（感觉卡顿）
- ❌ 纯装饰性无限循环动画
- ❌ 在不支持 prefers-reduced-motion 的情况下强制动画

---

## Mode A: React + Tailwind v4 + shadcn/ui

```
Vite + React 19 + TypeScript | Tailwind CSS v4 (@theme) | shadcn/ui (oklch) | 图标库 (见 Step 1.4)
```

默认 Lucide (shadcn 内置)，如需差异化可换 Phosphor/Tabler/Iconoir：
```bash
# 默认
pnpm add lucide-react
# 或替代
pnpm add @phosphor-icons/react    # 6 种字重，视觉层次最强
pnpm add @tabler/icons-react      # 5900+ 最大免费集
pnpm add iconoir-react             # 极简优雅，避免 AI 味
```

```bash
pnpm create vite@latest my-app -- --template react-ts && cd my-app && pnpm install
pnpm dlx shadcn@latest init -t vite
pnpm dlx shadcn@latest add button card input sidebar
```

### Tailwind v4

```css
@import "tailwindcss";
@theme { --color-brand-500: oklch(0.62 0.19 250); }
```

### shadcn oklch 变量

```css
:root {
  --background: oklch(1 0 0); --foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0); --primary-foreground: oklch(0.985 0 0);
  --muted: oklch(0.97 0 0); --muted-foreground: oklch(0.556 0 0);
  --border: oklch(0.922 0 0); --radius: 0.625rem;
}
.dark {
  --background: oklch(0.145 0 0); --foreground: oklch(0.985 0 0);
  --primary: oklch(0.922 0 0); --primary-foreground: oklch(0.205 0 0);
}
```

### 文件结构

```
src/ app.css · main.tsx · App.tsx
  components/ ui/ (shadcn) · layout/ (sidebar, topbar) · pages/ (dashboard)
  lib/ utils.ts (cn())
```

### CVA 组件变体模式

```bash
pnpm add class-variance-authority
```
```tsx
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const button = cva(
  'inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2',
  {
    variants: {
      variant: {
        primary:   'bg-[--color-primary] text-white hover:bg-[--color-primary-hover]',
        secondary: 'border border-[--color-primary] text-[--color-primary] hover:bg-[--color-primary-light]',
        ghost:     'hover:bg-[--color-surface-2] text-[--color-muted]',
      },
      size: {
        sm: 'h-8 px-3 text-sm',
        md: 'h-10 px-4 text-sm',
        lg: 'h-12 px-6 text-base',
      },
    },
    defaultVariants: { variant: 'primary', size: 'md' },
  }
)

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement>, VariantProps<typeof button> {}

export function Button({ variant, size, className, ...props }: ButtonProps) {
  return <button className={cn(button({ variant, size }), className)} {...props} />
}
```
> CVA 解决 boolean prop 爆炸问题：不再写 `isPrimary isLarge isGhost` 三个 prop

### color-mix() 透明度变体

```css
/* Tailwind v4 中用 color-mix 生成透明变体，无需定义额外变量 */
.bg-primary-10 { background: color-mix(in oklch, var(--color-primary) 10%, transparent); }
.bg-primary-20 { background: color-mix(in oklch, var(--color-primary) 20%, transparent); }

/* 或直接在 class 中内联 */
/* bg-[color-mix(in_oklch,var(--color-primary)_15%,transparent)] */
```

### Container Queries

```css
/* @theme 中定义 */
@theme {
  --breakpoint-sm: 640px;
}

/* 组件级响应式，比全局 breakpoint 更精准 */
@container (min-width: 400px) {
  .card-content { flex-direction: row; }
}
```
```html
<div class="@container">
  <div class="@sm:flex-row flex-col">...</div>
</div>
```

---

## Mode B: Pure HTML Prototype

单个 `.html`，零依赖，浏览器直接打开。

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>[名称] — Prototype</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Space+Grotesk:wght@500;600;700&display=swap" rel="stylesheet">
  <!-- 图标 CDN (选一个，见 Step 1.4) -->
  <script src="https://unpkg.com/lucide@latest"></script>
  <!-- 或 Phosphor: <script src="https://unpkg.com/@phosphor-icons/web@latest"></script> -->
  <!-- 或 Iconify: <script src="https://code.iconify.design/3/3.1.0/iconify.min.js"></script> -->
  <style>
    :root {
      --color-primary:#2563EB; --color-primary-hover:#1D4ED8;
      --color-primary-light:#EFF6FF; --color-primary-text:#1E40AF;
      --color-bg:#F8FAFC; --color-surface:#FFFFFF; --color-surface-2:#F1F5F9;
      --color-border:#E2E8F0; --color-text:#0F172A;
      --color-muted:#64748B; --color-subtle:#94A3B8;
      --success:#10B981; --warning:#F59E0B; --error:#EF4444;
      --sp-1:4px; --sp-2:8px; --sp-3:12px; --sp-4:16px;
      --sp-6:24px; --sp-8:32px; --sp-12:48px; --sp-16:64px;
      --font-sans:'Inter',system-ui,sans-serif;
      --font-display:'Space Grotesk','Inter',sans-serif;
      --radius-sm:4px; --radius-md:8px; --radius-lg:12px;
      --shadow-sm:0 1px 3px rgba(0,0,0,.06),0 1px 2px rgba(0,0,0,.04);
      --shadow-md:0 4px 6px -1px rgba(0,0,0,.07),0 2px 4px -2px rgba(0,0,0,.05);
      --shadow-lg:0 10px 15px -3px rgba(0,0,0,.08),0 4px 6px -4px rgba(0,0,0,.05);
      --ease:150ms ease;
    }
    /* ② Reset · ③ Layout · ④ Components · ⑤ Page */
  </style>
</head>
<body><!-- content --><script>lucide.createIcons();</script></body>
</html>
```

---

## 质量 Checklist

**通用：**
- [ ] 有明确设计个性（非通用蓝色主题）
- [ ] 视觉层次清晰
- [ ] 按钮 primary/secondary/tertiary 层级
- [ ] 色彩 60-30-10
- [ ] 边框克制
- [ ] 4px/8px 间距系统，间距表达归属
- [ ] 标题 letter-spacing 收紧
- [ ] 行高随字号变化
- [ ] 背景非纯白，文字非纯黑
- [ ] 字体非禁用列表（非 Inter/Roboto/Arial/Space Grotesk）
- [ ] hover/focus 状态
- [ ] 可交互元素 touch target ≥ 44px（移动端）
- [ ] Focus ring 可见（`focus-visible:outline`），不仅依赖颜色传达状态
- [ ] 空状态有设计
- [ ] 有背景装饰
- [ ] 动效：页面加载有 staggered reveal，duration ≤ 500ms
- [ ] 遵循 `prefers-reduced-motion`

**Mode A 追加：** oklch 品牌色 · shadcn 组件 · 语义 Tailwind 类 · .dark 模式 · CVA 管理组件变体（非手写 className 拼接） · 使用 container queries 替代仅靠全局 breakpoint
**Mode B 追加：** 全部 CSS 变量 · display/CJK 字体 · 自包含文件 · 含 `@media (prefers-reduced-motion: reduce)` 覆盖动画

---

## References

- `references/design-guide.md` — 设计思维总纲：视觉层次、排版、间距、色彩、动效、组件模式、反模式自检清单
- `references/color-system.md` — 色彩系统实战：Radix 12级/shadcn oklch 变量/Tailwind 色板/7 套预设方案/工具链
- `references/design-sizes.md` — 尺寸速查：设备视口、断点、组件尺寸、社交媒体尺寸、项目类型画布
- `references/icon-libraries.md` — 图标库速查：10+ 库的安装命令、CDN、React import 示例
- `references/css-recipes.md` — CSS 效果食谱：背景效果/微交互/字体配对/Landing Page Section 模式/Tailwind 速写
