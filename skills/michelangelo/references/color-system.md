# Color Resources & Tools Quick Reference

> From color theory to practical tools — a one-stop reference.

---

## 1. Color System Architecture Comparison

### 1.1 Radix Colors — 12-Step Functional Scale

Radix's core innovation: **every step in the scale has a defined UI purpose**.

| Step | Purpose | Example |
|------|----------|---------|
| **1-2** | Backgrounds (App/subtle background) | Page background, card fill |
| **3-5** | Interactive components (hover/active backgrounds) | Button hover, input focus |
| **6-7** | Borders and separators | Subtle border / defined border |
| **8** | Solid colors | Button background, badge |
| **9-10** | Solid color hover/active | Button hover state |
| **11** | Low-contrast text | Secondary text, placeholder |
| **12** | High-contrast text | Headings, body text |

**Key features:**
- 30 variants per color (light/dark × solid/alpha)
- Alpha transparent versions for blending over colored backgrounds
- APCA contrast algorithm (more accurate than WCAG AA)
- P3 wide-gamut color support
- Light/dark mode toggling with a single class swap

Available gray series (each with a distinct color temperature): Gray / Mauve (purple-gray) / Slate (blue-gray) / Sage (green-gray) / Olive (yellow-gray) / Sand (warm gray)

### 1.2 shadcn/ui — oklch Semantic Variable System

shadcn uses a **background + foreground convention**: every role color has a paired text color.

```css
:root {
  --background: oklch(1 0 0);           /* Page background */
  --foreground: oklch(0.145 0 0);       /* Page text */
  --card: oklch(1 0 0);                 /* Card background */
  --card-foreground: oklch(0.145 0 0);
  --popover: oklch(1 0 0);             /* Popover layer */
  --primary: oklch(0.205 0 0);         /* Primary action */
  --primary-foreground: oklch(0.985 0 0);
  --secondary: oklch(0.97 0 0);        /* Secondary action */
  --muted: oklch(0.97 0 0);            /* Muted area */
  --muted-foreground: oklch(0.556 0 0); /* Muted text */
  --accent: oklch(0.97 0 0);           /* Accent */
  --destructive: oklch(0.577 0.245 27.325); /* Destructive */
  --border: oklch(0.922 0 0);
  --input: oklch(0.922 0 0);
  --ring: oklch(0.708 0 0);            /* focus ring */
  --radius: 0.625rem;
  /* Sidebar-specific */
  --sidebar: oklch(0.985 0 0);
  --sidebar-primary: oklch(0.205 0 0);
  /* Chart colors */
  --chart-1: oklch(0.646 0.222 41.116);  /* Orange */
  --chart-2: oklch(0.6 0.118 184.704);   /* Cyan */
  --chart-3: oklch(0.398 0.07 227.392);  /* Deep blue */
  --chart-4: oklch(0.828 0.189 84.429);  /* Yellow */
  --chart-5: oklch(0.769 0.188 70.08);   /* Gold */
}
```

**How to add custom colors:**
```css
:root { --warning: oklch(0.84 0.16 84); --warning-foreground: oklch(0.28 0.07 46); }
.dark { --warning: oklch(0.41 0.11 46); --warning-foreground: oklch(0.99 0.02 95); }
@theme inline {
  --color-warning: var(--warning);
  --color-warning-foreground: var(--warning-foreground);
}
```

**Available base grays:** Neutral / Stone / Zinc / Mauve / Olive / Mist / Taupe

### 1.3 Tailwind CSS v4 Color Palette

22 colors × 11 steps (50–950), totaling 242 colors.
v4 uses oklch format. All colors can be viewed and copied at ui.shadcn.com/colors.

Full palette: neutral / stone / zinc / slate / gray / red / orange / amber / yellow / lime / green / emerald / teal / cyan / sky / blue / indigo / violet / purple / fuchsia / pink / rose

### 1.4 Apple HIG Color System

**System Colors:** Blue / Green / Indigo / Orange / Pink / Purple / Red / Teal / Yellow
- Automatically adapts to light and dark mode
- Each color has a default version and an Accessible enhanced version

**Semantic Colors:**
- **Label hierarchy:** label (primary text) / secondaryLabel / tertiaryLabel / quaternaryLabel
- **Background hierarchy:** systemBackground / secondarySystemBackground / tertiarySystemBackground
- **Grouped backgrounds:** systemGroupedBackground / secondary / tertiary
- **Fill:** systemFill / secondarySystemFill / tertiarySystemFill / quaternarySystemFill
- **Separator:** separator / opaqueSeparator

**Key principles:**
- Use semantic colors rather than hardcoded values
- Choose one accent color throughout to indicate "interactive"
- Do not use the same color to mean both interactive and non-interactive
- Do not rely on color alone to convey information

---

## 2. Color Tool Checklist

### 2.1 Generators & Palette Tools

| Tool | URL | Highlights |
|------|-----|------------|
| **Coolors** | coolors.co | Most popular palette generator (8M+ users), spacebar to randomize |
| ↳ Palette Generator | coolors.co/generate | Spacebar to randomize, lock favorites and keep iterating |
| ↳ Explore Palettes | coolors.co/palettes | 10M+ palettes, searchable by style/theme/color |
| ↳ Image Picker | coolors.co/image-picker | Extract colors from an image |
| ↳ Contrast Checker | coolors.co/contrast-checker | Visual WCAG contrast check |
| ↳ Palette Visualizer | coolors.co/visualizer | Live preview of color schemes on real UI |
| ↳ Tailwind Colors | coolors.co/tailwind | Preview Tailwind colors on real UI |
| ↳ Color Bot | coolors.co/color-bot | AI color pairing assistant |
| ↳ Gradient Maker | coolors.co/gradient-maker | Gradient generator |
| ↳ Gradient Palette | coolors.co/gradient-palette | Generate gradient steps between two colors |
| ↳ Free Fonts | coolors.co/fonts | Curated free font library |
| **UI Colors** | uicolors.app | Input a color value to generate an 11-step Tailwind scale (oklch/hex/hsl) |
| **Radix Custom** | radix-ui.com/colors/custom | Generate a 12-step Radix scale from a custom brand color |
| **shadcn Colors** | ui.shadcn.com/colors | One-click copy of the full Tailwind palette |
| **shadcn Themes** | ui.shadcn.com/themes | Visual theme preview + globals.css generation |
| **Flat UI Colors** | flatuicolors.com | 14 curated palettes (280 colors), categorized by country/style |
| **Figma Color Combos** | figma.com/resource-library/color-combinations | 100 color combinations + color theory tutorials |
| **Realtime Colors** | realtimecolors.com | Real-time color preview on UI templates |
| **Huemint** | huemint.com | AI brand color generation |
| **Material Theme Builder** | material-foundation.github.io/material-theme-builder | M3 dynamic color |

### 2.2 Accessibility Checks

| Tool | Purpose |
|------|---------|
| **Coolors Contrast Checker** | coolors.co/contrast-checker — visual WCAG check |
| **WebAIM Contrast Checker** | webaim.org/resources/contrastchecker |
| **Stark (Figma Plugin)** | Contrast check + color blindness simulation inside Figma |
| **APCA Calculator** | Modern APCA algorithm (used by Radix) |

### 2.3 Design Inspiration Resources (from Figma Resource Library)

| Resource | URL | Content |
|----------|-----|---------|
| **100 Color Combinations** | figma.com/resource-library/color-combinations | Color wheel / color harmony / color psychology + 100 palettes |
| **Typography Guide** | figma.com/resource-library/typography-in-design | Complete guide to font selection, hierarchy, line height, letter spacing, and alignment |
| **Typography Anatomy** | figma.com/resource-library/typography-anatomy | Type anatomy (serifs / x-height / baseline, etc.) |
| **Visual Hierarchy** | figma.com/resource-library/what-is-visual-hierarchy | 8 visual hierarchy principles (alignment / color / contrast / proximity) |
| **UI Design Principles** | figma.com/resource-library/ui-design-principles | 7 UI design principles + practical tips |
| **Graphic Design Principles** | figma.com/resource-library/graphic-design-principles | 13 design principles (balance / contrast / unity / proportion, etc.) |
| **Golden Ratio** | figma.com/resource-library/golden-ratio | Applying the golden ratio 1:1.618 in design |
| **Design System Examples** | figma.com/resource-library/design-system-examples | Comparison of 12 design systems |

---

## 3. Practical Color Scheme Quick Reference

### 3.1 Mode B (HTML) Common Presets

**Blue SaaS (default)**
```css
--color-primary: #2563EB; --color-primary-hover: #1D4ED8;
--color-primary-light: #EFF6FF; --color-primary-text: #1E40AF;
```

**Purple — Innovation / Education**
```css
--color-primary: #7C3AED; --color-primary-hover: #6D28D9;
--color-primary-light: #F5F3FF; --color-primary-text: #5B21B6;
```

**Teal — Health / Medical**
```css
--color-primary: #0D9488; --color-primary-hover: #0F766E;
--color-primary-light: #F0FDFA; --color-primary-text: #115E59;
```

**Orange — Creative / Energetic**
```css
--color-primary: #EA580C; --color-primary-hover: #C2410C;
--color-primary-light: #FFF7ED; --color-primary-text: #9A3412;
```

**Rose — E-commerce / Call to Action**
```css
--color-primary: #E11D48; --color-primary-hover: #BE123C;
--color-primary-light: #FFF1F2; --color-primary-text: #9F1239;
```

**Navy — Enterprise / Finance**
```css
--color-primary: #0F4C81; --color-primary-hover: #0C3D66;
--color-primary-light: #EFF6FF; --color-primary-text: #0A2E4D;
```

**Green — Eco / Growth**
```css
--color-primary: #16A34A; --color-primary-hover: #15803D;
--color-primary-light: #F0FDF4; --color-primary-text: #166534;
```

### 3.2 Mode A (React/shadcn) Brand Color Override

Override the primary variables in globals.css to change the entire theme:

```css
/* Blue brand */
:root { --primary: oklch(0.55 0.22 250); --primary-foreground: oklch(0.98 0 0); }
.dark { --primary: oklch(0.65 0.20 250); --primary-foreground: oklch(0.15 0 0); }

/* Purple brand */
:root { --primary: oklch(0.50 0.25 290); --primary-foreground: oklch(0.98 0 0); }

/* Teal brand */
:root { --primary: oklch(0.55 0.12 175); --primary-foreground: oklch(0.98 0 0); }
```

**Use uicolors.app — enter a brand hex → auto-generate an oklch scale → copy to globals.css.**

### 3.3 Dark Mode Colors

```css
.dark {
  --background: oklch(0.145 0 0);       /* Near-black, not pure black */
  --foreground: oklch(0.985 0 0);       /* Near-white, not pure white */
  --card: oklch(0.205 0 0);             /* Slightly lighter than background */
  --border: oklch(1 0 0 / 10%);         /* White at 10% alpha */
  --input: oklch(1 0 0 / 15%);          /* White at 15% */
  --muted: oklch(0.269 0 0);
  --muted-foreground: oklch(0.708 0 0);
}
```

Key point: in dark mode, use alpha-transparent colors for borders (oklch with /%) rather than solid colors, ensuring consistency across different backgrounds.

---

## 4. Color Usage Principles Summary

| Principle | Source |
|-----------|--------|
| 60-30-10 color ratio | Refactoring UI |
| Semantic colors > hardcoded colors | Apple HIG / shadcn |
| Every role color has a paired foreground | shadcn convention |
| Grays carry a color temperature (cool blue / warm brown) | Refactoring UI + Radix |
| Don't rely on color alone to convey information (pair with icons/text) | Apple HIG / WCAG |
| Choose one accent color throughout to indicate interaction | Apple HIG |
| Use alpha-transparent colors for dark mode borders | shadcn / Fluent |
| Contrast ratio ≥ 4.5:1 (body text) / ≥ 3:1 (large headings) | WCAG 2.0 |
| Don't use pure white #FFF for backgrounds / pure black #000 for text | Refactoring UI |
| Use tools to generate color scales rather than guessing manually | uicolors.app / Radix custom |
