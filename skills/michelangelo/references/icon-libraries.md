# React Icon Library Quick Reference

> Choosing an icon library means choosing a design style. Don't default to Lucide every time — let icons be part of what makes your product distinctive.

---

## Decision Tree

```
Need visual weight variation? → Phosphor (6 weights)
Need line + fill pairing? → Remix Icon
Lots of icons (dashboard)? → Tabler (5900+)
Want to avoid the AI look? → Iconoir or Remix Icon
One package for everything? → Iconify (200K+)
shadcn default is fine? → Lucide
Enterprise B2B? → Carbon Icons (IBM)
```

---

## Tier 1: Open-Source First Picks

### Lucide — shadcn/ui Default

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
1,500+ icons · 1 style (stroke) · 24×24 · tree-shakable

### Phosphor — Best Visual Hierarchy ⭐

```bash
pnpm add @phosphor-icons/react
```
```tsx
import { House, MagnifyingGlass, Gear } from '@phosphor-icons/react';
<House size={24} weight="regular" />     // regular (default)
<House size={24} weight="bold" />        // bold — emphasis
<House size={24} weight="light" />       // light — de-emphasis
<House size={24} weight="thin" />        // thin — lightest
<House size={24} weight="fill" />        // fill — solid
<House size={24} weight="duotone" />     // duotone — two-tone hierarchy
```
```html
<!-- CDN (Mode B) -->
<script src="https://unpkg.com/@phosphor-icons/web@latest"></script>
<i class="ph ph-house"></i>
<i class="ph-bold ph-house"></i>
<i class="ph-duotone ph-house"></i>
```
9,000+ icons · **6 weights** · 24×24

**Why Phosphor is recommended:** The weight prop lets you express visual hierarchy within a single icon set.
Sidebar active = bold, inactive = light. Hero icons = duotone, supporting icons = thin.
No need to mix multiple libraries.

### Tabler — Largest Free Collection

```bash
pnpm add @tabler/icons-react
```
```tsx
import { IconHome, IconSearch, IconSettings } from '@tabler/icons-react';
<IconHome size={24} stroke={2} />
<IconHome size={24} stroke={1.5} />  // adjustable stroke
```
```html
<!-- CDN -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/dist/tabler-icons.min.css">
<i class="ti ti-home"></i>
```
5,900+ icons · 1 style (stroke 2px) · 24×24 · MIT free

### Heroicons — Official Tailwind Icons

```bash
pnpm add @heroicons/react
```
```tsx
import { HomeIcon } from '@heroicons/react/24/outline';   // outline 24px
import { HomeIcon } from '@heroicons/react/24/solid';      // solid 24px
import { HomeIcon } from '@heroicons/react/20/solid';      // mini 20px
import { HomeIcon } from '@heroicons/react/16/solid';      // micro 16px
```
316 icons · 4 sizes/styles · Tailwind className ready

### Iconoir — Minimal & Elegant

```bash
pnpm add iconoir-react
```
```tsx
import { Home, Settings, User } from 'iconoir-react';
<Home width={24} height={24} strokeWidth={1.5} />
```
1,600+ icons · completely free, no premium tier · 24×24 · less common = more distinctive

### Remix Icon — Line + Fill Pairing

```bash
pnpm add remixicon-react
```
```tsx
import { RiHomeLine, RiHomeFill } from 'remixicon-react';
<RiHomeLine size={24} />     // line version
<RiHomeFill size={24} />     // fill version — every icon has a pair
```
2,800+ icons · 2 styles (line + fill) · 24×24

### Carbon Icons — IBM Enterprise Grade

```bash
pnpm add @carbon/icons-react
```
```tsx
import { Home, Search } from '@carbon/icons-react';
<Home size={24} />
```
2,000+ icons · IBM Carbon Design System · enterprise B2B aesthetic

### Radix Icons — Small Size Specialist

```bash
pnpm add @radix-ui/react-icons
```
```tsx
import { HomeIcon } from '@radix-ui/react-icons';
<HomeIcon width={15} height={15} />
```
300+ icons · **15×15** compact size · paired with Radix UI

---

## Tier 2: Aggregator Frameworks

### Iconify — One API, 200K+ Icons

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
<!-- CDN (Mode B) — extremely powerful -->
<script src="https://code.iconify.design/3/3.1.0/iconify.min.js"></script>
<iconify-icon icon="ph:house-duotone" width="24"></iconify-icon>
```
200,000+ icons · 100+ icon sets · unified syntax · on-demand loading

### React Icons — Classic Library Aggregator

```bash
pnpm add react-icons
```
```tsx
import { FaHome } from 'react-icons/fa';      // Font Awesome
import { MdHome } from 'react-icons/md';       // Material Design
import { FiHome } from 'react-icons/fi';       // Feather
import { HiHome } from 'react-icons/hi2';      // Heroicons v2
```
50,000+ icons · Note: must import from the specific sub-package for tree-shaking to work

---

## Tier 3: Commercial / Freemium

| Library | Icons | Styles | Free Tier | Package |
|---------|-------|--------|-----------|---------|
| **Hugeicons** | 46,000+ | 10 | 4,600 free | `hugeicons-react` |
| **Font Awesome** | 63,000+ | 30 | 2,000 free | `@fortawesome/react-fontawesome` |
| **Streamline** | 350,000+ | Multiple | Partial free | `@streamlinehq/react` |

---

## Mode B (HTML) CDN Summary

```html
<!-- Lucide (default) -->
<script src="https://unpkg.com/lucide@latest"></script>

<!-- Phosphor (recommended alternative) -->
<script src="https://unpkg.com/@phosphor-icons/web@latest"></script>

<!-- Tabler (web font) -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/dist/tabler-icons.min.css">

<!-- Iconify (universal) -->
<script src="https://code.iconify.design/3/3.1.0/iconify.min.js"></script>

<!-- Remix Icon -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/remixicon@latest/fonts/remixicon.css">
```

### Usage Comparison

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

<!-- Iconify (most flexible) -->
<iconify-icon icon="ph:house-duotone" width="24"></iconify-icon>
<iconify-icon icon="tabler:home" width="24"></iconify-icon>

<!-- Remix Icon -->
<i class="ri-home-line"></i>
<i class="ri-home-fill"></i>
```
