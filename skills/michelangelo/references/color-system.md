# 色彩资源与工具速查

> 从色彩理论到实战工具，一站式参考。

---

## 1. 色彩系统架构对比

### 1.1 Radix Colors — 12 级功能色阶

Radix 的核心创新：**每一级色阶都有明确的 UI 用途**。

| 色阶 | 用途 | 示例 |
|------|------|------|
| **1-2** | 背景 (App/subtle background) | 页面背景、卡片底色 |
| **3-5** | 交互组件 (hover/active 背景) | 按钮 hover、输入框 focus |
| **6-7** | 边框与分隔线 | subtle border / 明确 border |
| **8** | 实心色 (Solid colors) | 按钮背景、badge |
| **9-10** | 实心色 hover/active | 按钮 hover 态 |
| **11** | 低对比文字 | 次要文字、placeholder |
| **12** | 高对比文字 | 标题、正文 |

**关键特性：**
- 每色 30 种变体 (light/dark × 实色/alpha)
- Alpha 透明版本用于混合在彩色背景上
- APCA 对比度算法（比 WCAG AA 更准确）
- P3 广色域支持
- 亮暗模式只需切换一个 class

可用灰色系列（每种都带不同色温）：Gray / Mauve (紫灰) / Slate (蓝灰) / Sage (绿灰) / Olive (黄灰) / Sand (暖灰)

### 1.2 shadcn/ui — oklch 语义变量系统

shadcn 使用 **background + foreground 约定**：每个角色色都有配套的文字色。

```css
:root {
  --background: oklch(1 0 0);           /* 页面背景 */
  --foreground: oklch(0.145 0 0);       /* 页面文字 */
  --card: oklch(1 0 0);                 /* 卡片背景 */
  --card-foreground: oklch(0.145 0 0);
  --popover: oklch(1 0 0);             /* 弹出层 */
  --primary: oklch(0.205 0 0);         /* 主操作 */
  --primary-foreground: oklch(0.985 0 0);
  --secondary: oklch(0.97 0 0);        /* 次要操作 */
  --muted: oklch(0.97 0 0);            /* 弱化区域 */
  --muted-foreground: oklch(0.556 0 0); /* 弱化文字 */
  --accent: oklch(0.97 0 0);           /* 强调 */
  --destructive: oklch(0.577 0.245 27.325); /* 破坏性 */
  --border: oklch(0.922 0 0);
  --input: oklch(0.922 0 0);
  --ring: oklch(0.708 0 0);            /* focus ring */
  --radius: 0.625rem;
  /* Sidebar 专用 */
  --sidebar: oklch(0.985 0 0);
  --sidebar-primary: oklch(0.205 0 0);
  /* Chart 配色 */
  --chart-1: oklch(0.646 0.222 41.116);  /* 橙 */
  --chart-2: oklch(0.6 0.118 184.704);   /* 青 */
  --chart-3: oklch(0.398 0.07 227.392);  /* 深蓝 */
  --chart-4: oklch(0.828 0.189 84.429);  /* 黄 */
  --chart-5: oklch(0.769 0.188 70.08);   /* 金 */
}
```

**新增自定义色的方法：**
```css
:root { --warning: oklch(0.84 0.16 84); --warning-foreground: oklch(0.28 0.07 46); }
.dark { --warning: oklch(0.41 0.11 46); --warning-foreground: oklch(0.99 0.02 95); }
@theme inline {
  --color-warning: var(--warning);
  --color-warning-foreground: var(--warning-foreground);
}
```

**可选基础灰色：** Neutral / Stone / Zinc / Mauve / Olive / Mist / Taupe

### 1.3 Tailwind CSS v4 色板

22 种颜色 × 11 级色阶 (50-950)，共 242 种颜色。
v4 使用 oklch 格式。所有颜色可在 ui.shadcn.com/colors 查看并复制。

完整色板：neutral / stone / zinc / slate / gray / red / orange / amber / yellow / lime / green / emerald / teal / cyan / sky / blue / indigo / violet / purple / fuchsia / pink / rose

### 1.4 Apple HIG 色彩体系

**系统色 (System Colors)：** Blue / Green / Indigo / Orange / Pink / Purple / Red / Teal / Yellow
- 自动适配亮暗模式
- 每种有默认和 Accessible 增强版本

**语义色 (Semantic Colors)：**
- **Label 层次:** label (主文字) / secondaryLabel / tertiaryLabel / quaternaryLabel
- **背景层次:** systemBackground / secondarySystemBackground / tertiarySystemBackground
- **分组背景:** systemGroupedBackground / secondary / tertiary
- **Fill:** systemFill / secondarySystemFill / tertiarySystemFill / quaternarySystemFill
- **Separator:** separator / opaqueSeparator

**关键原则：**
- 用语义色而非硬编码色值
- 选一个 accent color 贯穿表示"可交互"
- 不要让相同颜色既表示可交互又表示不可交互
- 不要仅靠颜色传达信息

---

## 2. 色彩工具清单

### 2.1 生成器 & 调色盘

| 工具 | URL | 特点 |
|------|-----|------|
| **Coolors** | coolors.co | 最受欢迎的调色盘生成器 (8M+ 用户)，空格键随机生成 |
| ↳ Palette Generator | coolors.co/generate | 空格键随机，锁定喜欢的色继续迭代 |
| ↳ Explore Palettes | coolors.co/palettes | 1000 万+ 调色盘，按风格/主题/颜色搜索 |
| ↳ Image Picker | coolors.co/image-picker | 从图片提取色彩 |
| ↳ Contrast Checker | coolors.co/contrast-checker | WCAG 对比度检查 |
| ↳ Palette Visualizer | coolors.co/visualizer | 在真实 UI 上实时预览配色 |
| ↳ Tailwind Colors | coolors.co/tailwind | 预览 Tailwind 颜色在真实 UI 中的效果 |
| ↳ Color Bot | coolors.co/color-bot | AI 配色助手 |
| ↳ Gradient Maker | coolors.co/gradient-maker | 渐变生成器 |
| ↳ Gradient Palette | coolors.co/gradient-palette | 两色之间生成渐变色阶 |
| ↳ Free Fonts | coolors.co/fonts | 精选免费字体库 |
| **UI Colors** | uicolors.app | 输入色值生成 Tailwind 11 级色阶 (oklch/hex/hsl) |
| **Radix Custom** | radix-ui.com/colors/custom | 自定义品牌色生成 12 级 Radix 色阶 |
| **shadcn Colors** | ui.shadcn.com/colors | Tailwind 全色板一键复制 |
| **shadcn Themes** | ui.shadcn.com/themes | 可视化主题预览 + globals.css 生成 |
| **Flat UI Colors** | flatuicolors.com | 14 套精选调色盘 (280 色)，按国家/风格分类 |
| **Figma Color Combos** | figma.com/resource-library/color-combinations | 100 种配色方案 + 色彩理论教程 |
| **Realtime Colors** | realtimecolors.com | 实时在 UI 模板上预览色彩搭配 |
| **Huemint** | huemint.com | AI 品牌配色生成 |
| **Material Theme Builder** | material-foundation.github.io/material-theme-builder | M3 动态色彩 |

### 2.2 无障碍检查

| 工具 | 用途 |
|------|------|
| **Coolors Contrast Checker** | coolors.co/contrast-checker — 可视化 WCAG 检查 |
| **WebAIM Contrast Checker** | webaim.org/resources/contrastchecker |
| **Stark (Figma Plugin)** | Figma 内检查对比度 + 色盲模拟 |
| **APCA Calculator** | 现代 APCA 算法 (Radix 使用) |

### 2.3 设计灵感资源 (来自 Figma Resource Library)

| 资源 | URL | 内容 |
|------|-----|------|
| **100 Color Combinations** | figma.com/resource-library/color-combinations | 色轮/色彩和谐/色彩心理学 + 100 组配色 |
| **Typography Guide** | figma.com/resource-library/typography-in-design | 字体选择/层级/行高/字间距/对齐完整指南 |
| **Typography Anatomy** | figma.com/resource-library/typography-anatomy | 字体解剖学 (衬线/x-height/基线等) |
| **Visual Hierarchy** | figma.com/resource-library/what-is-visual-hierarchy | 8 个视觉层次原则 (对齐/色彩/对比/接近性) |
| **UI Design Principles** | figma.com/resource-library/ui-design-principles | 7 个 UI 设计原则 + 实战技巧 |
| **Graphic Design Principles** | figma.com/resource-library/graphic-design-principles | 13 个设计原则 (平衡/对比/统一/比例等) |
| **Golden Ratio** | figma.com/resource-library/golden-ratio | 黄金比例 1:1.618 在设计中的应用 |
| **Design System Examples** | figma.com/resource-library/design-system-examples | 12 个设计系统对比 |

---

## 3. 实战配色方案速查

### 3.1 Mode B (HTML) 常用预设

**蓝色 SaaS (默认)**
```css
--color-primary: #2563EB; --color-primary-hover: #1D4ED8;
--color-primary-light: #EFF6FF; --color-primary-text: #1E40AF;
```

**紫色创新/教育**
```css
--color-primary: #7C3AED; --color-primary-hover: #6D28D9;
--color-primary-light: #F5F3FF; --color-primary-text: #5B21B6;
```

**青色健康/医疗**
```css
--color-primary: #0D9488; --color-primary-hover: #0F766E;
--color-primary-light: #F0FDFA; --color-primary-text: #115E59;
```

**橙色创意/活力**
```css
--color-primary: #EA580C; --color-primary-hover: #C2410C;
--color-primary-light: #FFF7ED; --color-primary-text: #9A3412;
```

**玫红电商/行动**
```css
--color-primary: #E11D48; --color-primary-hover: #BE123C;
--color-primary-light: #FFF1F2; --color-primary-text: #9F1239;
```

**深蓝企业/金融**
```css
--color-primary: #0F4C81; --color-primary-hover: #0C3D66;
--color-primary-light: #EFF6FF; --color-primary-text: #0A2E4D;
```

**绿色环保/增长**
```css
--color-primary: #16A34A; --color-primary-hover: #15803D;
--color-primary-light: #F0FDF4; --color-primary-text: #166534;
```

### 3.2 Mode A (React/shadcn) 品牌色覆盖

在 globals.css 中覆盖 primary 变量即可改变整套主题：

```css
/* 蓝色品牌 */
:root { --primary: oklch(0.55 0.22 250); --primary-foreground: oklch(0.98 0 0); }
.dark { --primary: oklch(0.65 0.20 250); --primary-foreground: oklch(0.15 0 0); }

/* 紫色品牌 */
:root { --primary: oklch(0.50 0.25 290); --primary-foreground: oklch(0.98 0 0); }

/* 青色品牌 */
:root { --primary: oklch(0.55 0.12 175); --primary-foreground: oklch(0.98 0 0); }
```

**用 uicolors.app 输入品牌 hex → 自动生成 oklch 色阶 → 复制到 globals.css。**

### 3.3 暗色模式配色

```css
.dark {
  --background: oklch(0.145 0 0);       /* 近黑不纯黑 */
  --foreground: oklch(0.985 0 0);       /* 近白不纯白 */
  --card: oklch(0.205 0 0);             /* 比背景亮一点 */
  --border: oklch(1 0 0 / 10%);         /* 白色 10% 透明 */
  --input: oklch(1 0 0 / 15%);          /* 白色 15% */
  --muted: oklch(0.269 0 0);
  --muted-foreground: oklch(0.708 0 0);
}
```

关键：暗色下 border 用 alpha 透明色 (oklch with /%) 而非实色，确保在不同背景上一致。

---

## 4. 色彩使用原则汇总

| 原则 | 来源 |
|------|------|
| 60-30-10 色彩比例 | Refactoring UI |
| 语义色 > 硬编码色 | Apple HIG / shadcn |
| 每个角色色都有 foreground 配套 | shadcn convention |
| 灰色带色温 (冷蓝/暖棕) | Refactoring UI + Radix |
| 不仅靠颜色传达信息 (配图标/文字) | Apple HIG / WCAG |
| 选一个 accent color 贯穿表示交互 | Apple HIG |
| 暗色模式 border 用 alpha 透明色 | shadcn / Fluent |
| 对比度 ≥ 4.5:1 (正文) / ≥ 3:1 (大标题) | WCAG 2.0 |
| 不用纯白 #FFF 做背景 / 不用纯黑 #000 做文字 | Refactoring UI |
| 用工具生成色阶而非手动拍脑袋 | uicolors.app / Radix custom |
