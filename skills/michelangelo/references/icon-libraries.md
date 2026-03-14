# React 图标库速查

> 选图标库 = 选设计风格。不要每次默认 Lucide，让图标成为差异化的一部分。

---

## 选择决策树

```
需要视觉层次变化？ → Phosphor (6 种字重)
需要 line + fill 配对？ → Remix Icon
大量图标 (dashboard)？ → Tabler (5900+)
想避免 AI 味？ → Iconoir 或 Remix Icon
一个包搞定？ → Iconify (200K+)
shadcn 默认就好？ → Lucide
企业 B2B？ → Carbon Icons (IBM)
```

---

## Tier 1: 开源首选

### Lucide — shadcn/ui 默认

```bash
pnpm add lucide-react
```
```tsx
import { Home, Search, Settings } from 'lucide-react';
<Home size={24} strokeWidth={2} color="currentColor" />
```
```html
<!-- CDN (Mode B) -->
<script src="https://unpkg.com/lucide@latest"></script>
<i data-lucide="home"></i>
<script>lucide.createIcons();</script>
```
1,500+ 图标 · 1 种风格 (stroke) · 24×24 · tree-shakable

### Phosphor — 视觉层次最强 ⭐

```bash
pnpm add @phosphor-icons/react
```
```tsx
import { House, MagnifyingGlass, Gear } from '@phosphor-icons/react';
<House size={24} weight="regular" />     // regular (默认)
<House size={24} weight="bold" />        // bold — 强调
<House size={24} weight="light" />       // light — 弱化
<House size={24} weight="thin" />        // thin — 最轻
<House size={24} weight="fill" />        // fill — 实心
<House size={24} weight="duotone" />     // duotone — 双色层次
```
```html
<!-- CDN (Mode B) -->
<script src="https://unpkg.com/@phosphor-icons/web@latest"></script>
<i class="ph ph-house"></i>
<i class="ph-bold ph-house"></i>
<i class="ph-duotone ph-house"></i>
```
9,000+ 图标 · **6 种字重** · 24×24

**为什么推荐 Phosphor：** weight 属性让你在同一个图标集内表达视觉层次。
sidebar active = bold，inactive = light。Hero 图标 = duotone，辅助 = thin。
不需要混用多个库。

### Tabler — 免费最大集

```bash
pnpm add @tabler/icons-react
```
```tsx
import { IconHome, IconSearch, IconSettings } from '@tabler/icons-react';
<IconHome size={24} stroke={2} />
<IconHome size={24} stroke={1.5} />  // 可调 stroke
```
```html
<!-- CDN -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/dist/tabler-icons.min.css">
<i class="ti ti-home"></i>
```
5,900+ 图标 · 1 种风格 (stroke 2px) · 24×24 · MIT 免费

### Heroicons — Tailwind 官方

```bash
pnpm add @heroicons/react
```
```tsx
import { HomeIcon } from '@heroicons/react/24/outline';   // outline 24px
import { HomeIcon } from '@heroicons/react/24/solid';      // solid 24px
import { HomeIcon } from '@heroicons/react/20/solid';      // mini 20px
import { HomeIcon } from '@heroicons/react/16/solid';      // micro 16px
```
316 图标 · 4 种尺寸/风格 · Tailwind className 直接用

### Iconoir — 极简优雅

```bash
pnpm add iconoir-react
```
```tsx
import { Home, Settings, User } from 'iconoir-react';
<Home width={24} height={24} strokeWidth={1.5} />
```
1,600+ 图标 · 完全免费无 premium · 24×24 · 用的人少 = 更独特

### Remix Icon — line + fill 配对

```bash
pnpm add remixicon-react
```
```tsx
import { RiHomeLine, RiHomeFill } from 'remixicon-react';
<RiHomeLine size={24} />     // line 版
<RiHomeFill size={24} />     // fill 版 — 每个图标都有配对
```
2,800+ 图标 · 2 种风格 (line + fill) · 24×24

### Carbon Icons — IBM 企业级

```bash
pnpm add @carbon/icons-react
```
```tsx
import { Home, Search } from '@carbon/icons-react';
<Home size={24} />
```
2,000+ 图标 · IBM Carbon 设计系统 · 企业 B2B 调性

### Radix Icons — 小尺寸专用

```bash
pnpm add @radix-ui/react-icons
```
```tsx
import { HomeIcon } from '@radix-ui/react-icons';
<HomeIcon width={15} height={15} />
```
300+ 图标 · **15×15** 紧凑尺寸 · Radix UI 配套

---

## Tier 2: 聚合框架

### Iconify — 一个 API 200K+ 图标

```bash
pnpm add @iconify/react
```
```tsx
import { Icon } from '@iconify/react';
<Icon icon="mdi:home" width={24} />           // Material Design
<Icon icon="ph:house-bold" width={24} />       // Phosphor Bold
<Icon icon="tabler:home" width={24} />         // Tabler
<Icon icon="lucide:home" width={24} />         // Lucide
<Icon icon="heroicons:home-solid" width={24} />// Heroicons
```
```html
<!-- CDN (Mode B) — 超级强大 -->
<script src="https://code.iconify.design/3/3.1.0/iconify.min.js"></script>
<iconify-icon icon="ph:house-duotone" width="24"></iconify-icon>
```
200,000+ 图标 · 100+ icon sets · 统一语法 · 按需加载

### React Icons — 聚合经典库

```bash
pnpm add react-icons
```
```tsx
import { FaHome } from 'react-icons/fa';      // Font Awesome
import { MdHome } from 'react-icons/md';       // Material Design
import { FiHome } from 'react-icons/fi';       // Feather
import { HiHome } from 'react-icons/hi2';      // Heroicons v2
```
50,000+ 图标 · 注意：必须从具体子包 import 才能 tree-shake

---

## Tier 3: 商业/Freemium

| 库 | 图标数 | 风格 | 免费数量 | 包名 |
|---|--------|------|---------|------|
| **Hugeicons** | 46,000+ | 10 种 | 4,600 free | `hugeicons-react` |
| **Font Awesome** | 63,000+ | 30 种 | 2,000 free | `@fortawesome/react-fontawesome` |
| **Streamline** | 350,000+ | 多种 | 部分 free | `@streamlinehq/react` |

---

## Mode B (HTML) CDN 汇总

```html
<!-- Lucide (默认) -->
<script src="https://unpkg.com/lucide@latest"></script>

<!-- Phosphor (推荐替代) -->
<script src="https://unpkg.com/@phosphor-icons/web@latest"></script>

<!-- Tabler (web font) -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/dist/tabler-icons.min.css">

<!-- Iconify (万能) -->
<script src="https://code.iconify.design/3/3.1.0/iconify.min.js"></script>

<!-- Remix Icon -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/remixicon@latest/fonts/remixicon.css">
```

### 用法对比

```html
<!-- Lucide -->
<i data-lucide="home"></i>
<script>lucide.createIcons();</script>

<!-- Phosphor -->
<i class="ph ph-house"></i>
<i class="ph-bold ph-house"></i>
<i class="ph-duotone ph-house"></i>

<!-- Tabler -->
<i class="ti ti-home"></i>

<!-- Iconify (最灵活) -->
<iconify-icon icon="ph:house-duotone" width="24"></iconify-icon>
<iconify-icon icon="tabler:home" width="24"></iconify-icon>

<!-- Remix Icon -->
<i class="ri-home-line"></i>
<i class="ri-home-fill"></i>
```
