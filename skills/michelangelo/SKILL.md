---
name: michelangelo
description: >
  Generate beautiful UI prototypes and production-ready React projects from natural language.
  Supports two modes: (1) React + Tailwind v4 + shadcn/ui project scaffold with real component
  files, oklch design tokens, and proper project structure; (2) self-contained HTML prototype
  with CSS custom properties, zero dependencies, opens directly in browser.
  Use for ANY UI request: "design", "prototype", "make a page", "UI", "prototype", "landing page",
  "dashboard", "mock up", "React project", "shadcn", "Tailwind", "show me what it looks like".
  Always use this skill over ad-hoc HTML — output quality is dramatically better.
---

# Michelangelo

> "I saw the angel in the marble and carved until I set him free."

Two modes, one design philosophy. Master the design principles before writing a single line of code.

---

## Step 0: Determine Output Mode

| User says | Mode |
|-----------|------|
| "make a prototype" / "preview" / "show me" / "quick look" | **Mode B: HTML Prototype** |
| "generate React project" / "shadcn" / "Tailwind" / "write code" / "real project" | **Mode A: React + Tailwind + shadcn + Visual Validation** |
| Ambiguous | Default to **Mode B**, then prompt whether to generate Mode A after completion |

**Mode A and Mode B both include a visual validation loop**: after generating code, use Playwright MCP to screenshot → review → iterate until the result looks right. This is what makes Michelangelo surpass design tools like pencil.dev — direct code output with a visual feedback loop, no intermediate file format.

---

## Step 0.5: Playwright MCP Detection

Before any visual validation, check if Playwright MCP is available.

### Detection

Try calling any Playwright MCP tool (e.g. `browser_navigate`). If it responds → available, proceed normally.

If unavailable, detect the current agent by checking which config files exist:

```bash
# Claude Code
claude mcp list 2>/dev/null | grep -i playwright

# Cursor
cat .cursor/mcp.json 2>/dev/null | grep -i playwright

# Gemini
cat .gemini/settings.json 2>/dev/null | grep -i playwright

# Generic: check project .mcp.json
cat .mcp.json 2>/dev/null | grep -i playwright
```

### Installation

**Universal approach — add to `.mcp.json` in the project root** (works with Claude Code, Cursor, Gemini, Windsurf, most agents):

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

**Agent-specific CLI commands:**

| Agent | Command |
|-------|---------|
| Claude Code | `claude mcp add playwright -s user -- npx @playwright/mcp@latest` |
| OpenCode | `opencode mcp add playwright -- npx @playwright/mcp@latest` |
| Cursor / Gemini / Windsurf | Add the JSON block above to the agent's config file |

### If not installed — ask for authorization

> "Visual validation requires Playwright MCP, which is not currently installed.
> I can add it now by creating/updating `.mcp.json` in the project root.
> May I do this?"

- **Yes**: write the `.mcp.json` config block, then proceed with visual validation
- **No**: skip visual validation, deliver the code only, and note that the user can install Playwright MCP later

**Do not silently skip visual validation** — always inform the user if it's unavailable.

---

## Step 1: Design Thinking (Must Complete Before Writing Code)

### 1.1 Determine Design Type

| Type | Characteristics | Canvas Width | Content Area | Height |
|------|----------------|-------------|--------------|--------|
| **Landing Page** | Marketing/product intro, requires scrolling | 1440px | 1200px centered | Long page, 80-96px between sections |
| **Dashboard** | Data/admin, sidebar + content area | 1440px | 100% - sidebar(240px) | Full screen 900px |
| **Single Screen** | Single task: login, form | 1440px (desktop) | Centered card 400-480px | Vertically centered |
| **Mobile Screen** | Mobile App page | **390×844** | Full width, padding 16px | Includes status bar + safe area |
| **Mobile (Compatible)** | Compatible with older devices | **375×812** | Full width | iPhone SE baseline |
| **Tablet** | iPad etc. | 768-1024px | 720-960px | Responsive |
| **Mini Program** | WeChat Mini Program | 375×812 (or 750×1624 @2x) | Full width | Includes nav bar 88rpx |
| **Email Template** | EDM/marketing email | **600px** | 600px | 1500-2000px |
| **Social Image** | WeChat/Xiaohongshu/TikTok | By platform | See references/design-sizes.md | — |

For detailed device sizes, social media sizes, and component sizes, see `references/design-sizes.md`.

⚠️ "Mobile login page" = a real App interface at 390×844, **not** a desktop page with an embedded phone mockup frame.

### 1.2 Define Design Personality

Every project must choose a clear personality direction — this determines all values for fonts, colors, border radius, and spacing:

| Personality | Font | Border Radius | Color Tone | Whitespace |
|-------------|------|---------------|------------|------------|
| **Serious/Enterprise** | Serif heading + sans-serif body | Small (4-8px) | Deep blue/navy | Generous |
| **Friendly/SaaS** | Rounded sans-serif (e.g. DM Sans) | Medium (8-12px) | Blue/purple/cyan | Moderate |
| **Bold/Creative** | Heavy geometric typeface | Large or none (16px/0) | High-saturation contrast | Extreme |
| **Elegant/Luxury** | Serif + thin weight | Small (4px) | Black/gold/off-white | Very generous |
| **Playful/Youthful** | Rounded/handwritten feel | Large (16-24px) | Vibrant clashing colors | Tight |

**A personality is non-negotiable.** UI without a defined personality = generic AI-generated look.

### 1.3 Anti-Pattern Quick Check

Run through this mentally before writing code (see `references/design-guide.md` section 11 for details):

- ❌ All elements given equal importance (no visual hierarchy)
- ❌ Too many border dividers (use background contrast/spacing/shadows instead)
- ❌ Colors distributed evenly (should follow 60-30-10 ratio)
- ❌ Generic blue color scheme
- ❌ Large blocks of Lorem ipsum placeholder text
- ❌ All buttons using the same style (missing primary/secondary/tertiary hierarchy)
- ❌ Pure white background + pure black text (adjust color temperature slightly)
- ❌ Arbitrary spacing (should be based on 4px/8px grid system)
- ❌ All cards identical in size and style

### 1.4 Choose an Icon Library

Don't default to Lucide every time. Lucide has become the default icon set for AI-generated UI, leading to visually homogeneous products. Choose based on project needs:

| Use Case | Recommended | Package / CDN |
|----------|-------------|--------------|
| shadcn/ui default | **Lucide** (1,500+) | `lucide-react` · CDN: `unpkg.com/lucide@latest` |
| Needs visual weight variety | **Phosphor** (9,000+, 6 weights including duotone) | `@phosphor-icons/react` · CDN: `unpkg.com/@phosphor-icons/web@latest` |
| Dashboard / many icons | **Tabler** (5,900+ free) | `@tabler/icons-react` · CDN: `cdn.jsdelivr.net/npm/@tabler/icons@latest` |
| Avoid "AI look" | **Iconoir** (1,600+) or **Remix Icon** (2,800+ line+fill) | `iconoir-react` / `remixicon-react` |
| Tailwind native | **Heroicons** (316, small and refined) | `@heroicons/react` |
| One package for all libraries | **Iconify** (200,000+ across 100+ libraries) | `@iconify/react` |
| Enterprise/B2B feel | **Carbon Icons** (IBM) | `@carbon/icons-react` |
| Largest multi-style library (paid) | **Hugeicons** (46,000+, 10 styles) | `hugeicons-react` |

See `references/icon-libraries.md` for full installation commands and usage examples.

---

## Step 2: Visual Hierarchy System (The Core of the Core)

Visual hierarchy is the deciding factor in design quality. Not all elements are equally important.

### 2.1 Three Tools to Control Hierarchy

**Don't rely on font size alone!** Use all three simultaneously:

| Dimension | Primary Content | Secondary Content | Supporting Content |
|-----------|----------------|------------------|--------------------|
| **Font size** | Large (20-48px) | Medium (14-16px) | Small (12-13px) |
| **Font weight** | Bold/Semibold (600-700) | Medium (500) | Regular (400) |
| **Color lightness** | Dark (#0F172A) | Mid gray (#64748B) | Light gray (#94A3B8) |

**Key insight: Weakening secondary content is more effective than emphasizing primary content.**

### 2.2 Button Hierarchy

Each page has at most 1 primary action, a few secondary, and the rest tertiary:

```css
.btn-primary { background: var(--color-primary); color: white; font-weight: 600; }
.btn-secondary { background: transparent; color: var(--color-primary);
  border: 1.5px solid var(--color-primary); }
.btn-tertiary { background: none; color: var(--color-primary); text-decoration: underline; }
/* Destructive actions use secondary style when not primary; only use red primary in confirmation dialogs */
```

### 2.3 Label De-emphasis

Avoid labels when possible. When the data format itself conveys meaning, display the value directly.
When labels are necessary, de-emphasize them (light color/small text) and emphasize the value.

---

## Step 3: Color System

> For detailed color system architecture, tool references, and preset schemes, see `references/color-system.md`

### 3.1 Complete Color Scale

Each semantic color needs 8-10 shade steps. 5 hex values are not enough.

### 3.2 Brand Color (Don't always use blue!)

| Industry | Color | Hex |
|----------|-------|-----|
| Tech/SaaS | Blue | #2563EB |
| Creative/Design | Orange | #F97316 |
| Finance/Enterprise | Deep blue | #0F4C81 |
| Health/Medical | Teal | #0D9488 |
| Education | Purple | #7C3AED |
| E-commerce | Rose | #E11D48 |
| Environment | Green | #16A34A |
| Dark theme | — | bg #0F172A + accent #60A5FA |

### 3.3 Grays with Color Temperature

Cool gray (#64748B with blue) → tech feel · Warm gray (#78716C with brown) → friendly feel

### 3.4 Color Ratio 60-30-10

60% primary background · 30% secondary surface · 10% accent color

### 3.5 Accessibility

Body text 4.5:1 · Large headings 3:1 · No gray text on colored backgrounds

---

## Step 4: Layout and Spacing

### 4.1 Spacing System (4px grid)

```css
--sp-1:4px; --sp-2:8px; --sp-3:12px; --sp-4:16px; --sp-5:20px; --sp-6:24px;
--sp-8:32px; --sp-10:40px; --sp-12:48px; --sp-16:64px; --sp-20:80px; --sp-24:96px;
```

**Start with "too much whitespace", then reduce incrementally.**

### 4.2 Spacing Communicates Relationships

Related elements close together (8-12px), unrelated elements further apart (24-48px). Headings tight to the content below them.

### 4.3 Content Width

Text line width 45-75 characters (max-width: 65ch). Content area max-width 1200px. Don't fill the screen edge to edge.

---

## Step 5: Advanced Typography

> For font pairing schemes categorized by project personality (including Google Fonts import code), see `references/css-recipes.md` section 3

### 5.1 Font Selection

**Fonts with ≥ 5 weights are generally higher quality.**

| Use | Latin | CJK |
|-----|-------|-----|
| Headings | Space Grotesk, DM Sans, Outfit, Sora, Manrope | Noto Sans SC Medium/Bold |
| Body | Inter, Source Sans 3, IBM Plex Sans | Noto Sans SC Regular |

**Never use Latin display fonts like Space Grotesk for CJK text.**

### 5.2 Line Height Varies with Font Size

Large headings 1.1-1.2 · Medium headings 1.2-1.3 · Body 1.5-1.6 · CJK headings 1.3-1.4 · CJK body 1.6-1.8

### 5.3 Letter Spacing

Large headings -0.5px · All caps +1px and reduce font-size by 15% · Never use negative values for CJK

### 5.4 Copy Length

Hero 2-6 words · Subtitle ≤15 words · Feature ≤20 words · Button 1-3 words · No paragraphs longer than 3 sentences

---

## Step 6: Depth and Shadows

### 6.1 Dual-Layer Shadows

```css
--shadow-sm: 0 1px 3px rgba(0,0,0,.06), 0 1px 2px rgba(0,0,0,.04);
--shadow-md: 0 4px 6px -1px rgba(0,0,0,.07), 0 2px 4px -2px rgba(0,0,0,.05);
--shadow-lg: 0 10px 15px -3px rgba(0,0,0,.08), 0 4px 6px -4px rgba(0,0,0,.05);
--shadow-xl: 0 20px 25px -5px rgba(0,0,0,.10), 0 8px 10px -6px rgba(0,0,0,.05);
```

### 6.2 Border Alternatives

Prefer: background color contrast · shadows · spacing · accent border (border-left: 3px solid)

---

## Step 7: Refinement Techniques

> For more CSS effect code (frosted glass/noise/glow/animated gradients/skeleton screens), font pairing schemes, and Landing Page Section templates, see `references/css-recipes.md`

### 7.1 Accent Borders

```css
.card-accent { border-left: 4px solid var(--color-primary); }
```

### 7.2 Background Decoration (Solid backgrounds are too flat)

```css
/* Gradient mesh */
.hero-bg {
  background:
    radial-gradient(at 20% 80%, oklch(0.75 0.15 250 / 0.3) 0, transparent 50%),
    radial-gradient(at 80% 20%, oklch(0.80 0.12 300 / 0.2) 0, transparent 50%),
    var(--color-bg);
}
/* Noise texture */
.textured {
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.04'/%3E%3C/svg%3E");
}
```

Also consider SVG patterns from HeroPatterns.com · angled clip-path color blocks

### 7.3 Empty States

Empty state = icon + description text + call-to-action button

### 7.4 Interaction States

Every interactive element must have hover/focus/active:
```css
.btn:hover { transform: translateY(-1px); box-shadow: var(--shadow-md); }
.card:hover { box-shadow: var(--shadow-lg); transform: translateY(-2px); }
.btn:focus-visible { outline: 2px solid var(--color-primary); outline-offset: 2px; }
```

---

## Step 8: Motion and Animation

### 8.1 Animation Philosophy

- A single well-orchestrated page load + staggered reveals (animation-delay) is more memorable than scattered hover micro-interactions everywhere
- Animation serves content, not decoration. Every animation must have a reason to exist
- Use spring physics instead of linear/ease: more natural, with a sense of elasticity

### 8.2 CSS Animation (Preferred for Mode B)

```css
/* Staggered reveal */
@keyframes fadeUp {
  from { opacity: 0; transform: translateY(20px); }
  to   { opacity: 1; transform: translateY(0); }
}
.reveal { animation: fadeUp 0.5s ease forwards; opacity: 0; }
.reveal:nth-child(2) { animation-delay: 0.1s; }
.reveal:nth-child(3) { animation-delay: 0.2s; }

/* Spring-like bounce (CSS approximation) */
@keyframes springIn {
  0%   { transform: scale(0.85); opacity: 0; }
  60%  { transform: scale(1.05); }
  100% { transform: scale(1);    opacity: 1; }
}
```

### 8.3 React Animation (Mode A)

```
pnpm add motion
```

```jsx
import { motion } from 'motion/react'

// List staggered
const container = { hidden: {}, show: { transition: { staggerChildren: 0.1 } } }
const item = { hidden: { opacity: 0, y: 20 }, show: { opacity: 1, y: 0 } }

<motion.ul variants={container} initial="hidden" animate="show">
  {items.map(i => <motion.li key={i} variants={item}>{i}</motion.li>)}
</motion.ul>

// Spring physics
<motion.div whileHover={{ scale: 1.03 }} transition={{ type: 'spring', stiffness: 300, damping: 20 }} />
```

### 8.4 Prohibited

- ❌ Adding transition to every element (visual noise)
- ❌ duration > 600ms (feels sluggish)
- ❌ Purely decorative infinite loop animations
- ❌ Forcing animations without supporting prefers-reduced-motion

---

## Mode A: React + Tailwind v4 + shadcn/ui

```
Vite + React 19 + TypeScript | Tailwind CSS v4 (@theme) | shadcn/ui (oklch) | Icon library (see Step 1.4)
```

### Package Manager Detection

Before running any command, detect the local package manager in this order:

```
bun → pnpm → yarn → npm
```

Use `which bun pnpm yarn npm` to detect, then use the first available one throughout. Examples below use `{pm}` as placeholder.

| Manager | Run command | Exec command |
|---------|------------|--------------|
| bun | `bun` | `bunx` |
| pnpm | `pnpm` | `pnpm dlx` |
| yarn | `yarn` | `yarn dlx` |
| npm | `npm` | `npx` |

### Project Initialization

```bash
# 1. Create Vite project
{pm} create vite@latest my-app -- --template react-ts && cd my-app && {pm} install

# 2. Install Tailwind v4
{pm} add -D tailwindcss @tailwindcss/vite

# 3. Configure vite.config.ts — add tailwindcss plugin + path alias
# 4. Configure tsconfig.json — add baseUrl + paths alias for @/*
# 5. Add @import "tailwindcss"; to src/index.css

# 6. Initialize shadcn (Radix + Nova preset, skip prompts)
{pmx} shadcn@latest init -y -b radix -p nova

# 7. Add components
{pmx} shadcn@latest add button card input
```

Default Lucide (built into shadcn), switch to Phosphor/Tabler/Iconoir for differentiation:
```bash
{pm} add @phosphor-icons/react    # 6 weights, strongest visual hierarchy
{pm} add @tabler/icons-react      # 5900+ largest free set
{pm} add iconoir-react            # Minimal elegance, avoids AI feel
```

### Tailwind v4

```css
@import "tailwindcss";
@theme { --color-brand-500: oklch(0.62 0.19 250); }
```

### shadcn oklch variables

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

### File Structure

```
src/ app.css · main.tsx · App.tsx
  components/ ui/ (shadcn) · layout/ (sidebar, topbar) · pages/ (dashboard)
  lib/ utils.ts (cn())
```

### CVA Component Variant Pattern

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
> CVA solves boolean prop explosion: no more writing `isPrimary isLarge isGhost` as three separate props

### color-mix() Opacity Variants

```css
/* Use color-mix to generate opacity variants in Tailwind v4, no extra variables needed */
.bg-primary-10 { background: color-mix(in oklch, var(--color-primary) 10%, transparent); }
.bg-primary-20 { background: color-mix(in oklch, var(--color-primary) 20%, transparent); }

/* Or inline directly in class */
/* bg-[color-mix(in_oklch,var(--color-primary)_15%,transparent)] */
```

### Container Queries

```css
/* Define in @theme */
@theme {
  --breakpoint-sm: 640px;
}

/* Component-level responsiveness, more precise than global breakpoints */
@container (min-width: 400px) {
  .card-content { flex-direction: row; }
}
```
```html
<div class="@container">
  <div class="@sm:flex-row flex-col">...</div>
</div>
```

### Visual Validation Loop (Mode A)

After writing all component files, close the loop visually:

```
Step 1 — Start dev server (if not already running)
         {pm} dev --port 5173

Step 2 — Screenshot with Playwright MCP
         Navigate to http://localhost:5173
         Take a full-page screenshot

Step 3 — Review the screenshot
         Check against the design principles from Steps 1–8:
         - Visual hierarchy clear?
         - Color 60-30-10 ratio correct?
         - Spacing on 4px/8px grid?
         - Typography weights differentiated?
         - Hover/focus states visible?
         - Background not plain white?

Step 4 — Iterate if needed
         Fix issues in the component files → Vite HMR auto-refreshes → re-screenshot
         Repeat until the result matches design intent

Step 5 — Done
         Confirm to user with a final screenshot
```

**This loop is what pencil.dev cannot do** — it outputs a `.pen` file requiring a separate export step. Michelangelo outputs real code and validates it visually in the same session.

---

## Mode B: Pure HTML Prototype

Single `.html` file, zero dependencies, opens directly in browser.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>[Name] — Prototype</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Space+Grotesk:wght@500;600;700&display=swap" rel="stylesheet">
  <!-- Icon CDN (pick one, see Step 1.4) -->
  <script src="https://unpkg.com/lucide@latest"></script>
  <!-- Or Phosphor: <script src="https://unpkg.com/@phosphor-icons/web@latest"></script> -->
  <!-- Or Iconify: <script src="https://code.iconify.design/3/3.1.0/iconify.min.js"></script> -->
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

### Visual Validation Loop (Mode B)

Mode B produces a single `.html` file — no dev server needed. Playwright MCP can open it directly:

```
Step 1 — Write the .html file to an absolute path
         e.g. /Users/you/workspace/prototype.html

Step 2 — Screenshot with Playwright MCP
         Navigate to file:///Users/you/workspace/prototype.html
         Take a full-page screenshot

Step 3 — Review the screenshot
         Same checklist as Mode A — visual hierarchy, color ratio,
         spacing, typography, hover states, background texture

Step 4 — Iterate if needed
         Edit the .html file → re-navigate → re-screenshot
         (No server restart needed — Playwright reads the file fresh each time)

Step 5 — Done
         Confirm to user with a final screenshot
```

---

## Quality Checklist

**Universal:**
- [ ] Has a clear design personality (not a generic blue theme)
- [ ] Clear visual hierarchy
- [ ] Button primary/secondary/tertiary hierarchy
- [ ] Color 60-30-10 ratio
- [ ] Borders used sparingly
- [ ] 4px/8px spacing system, spacing communicates relationships
- [ ] Heading letter-spacing tightened
- [ ] Line height varies with font size
- [ ] Background not pure white, text not pure black
- [ ] Font not on the banned list (not Inter/Roboto/Arial/Space Grotesk)
- [ ] hover/focus states
- [ ] Interactive elements touch target ≥ 44px (mobile)
- [ ] Focus ring visible (`focus-visible:outline`), not relying solely on color to convey state
- [ ] Empty states have design
- [ ] Background decoration present
- [ ] Animation: page load has staggered reveal, duration ≤ 500ms
- [ ] Respects `prefers-reduced-motion`

**Mode A additions:** oklch brand color · shadcn components · semantic Tailwind classes · .dark mode · CVA for managing component variants (not hand-stitched className strings) · use container queries instead of relying solely on global breakpoints
**Mode B additions:** All CSS variables · display/CJK fonts · self-contained file · includes `@media (prefers-reduced-motion: reduce)` to override animations

---

## References

- `references/design-guide.md` — Design thinking master guide: visual hierarchy, typography, spacing, color, animation, component patterns, anti-pattern self-check list
- `references/color-system.md` — Color system in practice: Radix 12-step / shadcn oklch variables / Tailwind palette / 7 preset schemes / toolchain
- `references/design-sizes.md` — Size quick reference: device viewports, breakpoints, component sizes, social media sizes, project type canvases
- `references/icon-libraries.md` — Icon library quick reference: 10+ libraries with install commands, CDN, React import examples
- `references/css-recipes.md` — CSS effect recipes: background effects / micro-interactions / font pairing / Landing Page Section patterns / Tailwind shortcuts
