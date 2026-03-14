# CSS Effects Recipes & Component Patterns

> Ready-to-copy CSS snippets, font pairings, and page section patterns for Claude when generating UI code.

---

## 1. Background Effects

### 1.1 Mesh Gradient

```css
.mesh-gradient {
  background:
    radial-gradient(at 0% 0%, oklch(0.75 0.18 250 / 0.3) 0, transparent 50%),
    radial-gradient(at 100% 0%, oklch(0.80 0.15 300 / 0.2) 0, transparent 50%),
    radial-gradient(at 80% 100%, oklch(0.70 0.12 180 / 0.15) 0, transparent 50%),
    var(--color-bg);
}
/* Dark version */
.mesh-gradient-dark {
  background:
    radial-gradient(at 20% 80%, oklch(0.35 0.15 250 / 0.4) 0, transparent 50%),
    radial-gradient(at 80% 20%, oklch(0.30 0.12 300 / 0.3) 0, transparent 50%),
    #0F172A;
}
```

### 1.2 Grain Texture

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

### 1.3 Glassmorphism

```css
.glass {
  background: rgba(255,255,255,0.15);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255,255,255,0.2);
  border-radius: var(--radius-lg);
  box-shadow: 0 4px 30px rgba(0,0,0,0.08);
}
/* Dark version */
.glass-dark {
  background: rgba(15,23,42,0.6);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(255,255,255,0.08);
}
/* Navbar glassmorphism */
.nav-glass {
  background: rgba(255,255,255,0.8);
  backdrop-filter: blur(12px) saturate(180%);
  border-bottom: 1px solid rgba(0,0,0,0.05);
}
```

### 1.4 Blob

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

### 1.5 Dot Grid

```css
.dot-grid {
  background-image: radial-gradient(circle, var(--color-border) 1px, transparent 1px);
  background-size: 24px 24px;
}
```

### 1.6 Slant Divider

```css
.slant { clip-path: polygon(0 0, 100% 0, 100% 85%, 0 100%); }
.slant-reverse { clip-path: polygon(0 0, 100% 0, 100% 100%, 0 85%); }
```

### 1.7 Animated Gradient

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

### 1.8 Glow

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

## 2. Micro-Interactions

### 2.1 Button hover lift

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

### 2.2 Card hover float

```css
.card-hover {
  transition: all 200ms cubic-bezier(.4,0,.2,1);
}
.card-hover:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-xl);
}
```

### 2.3 Entrance Animation (Fade Up + Stagger)

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

## 3. Font Pairings

Choose based on the project's personality. Each pair includes its Google Fonts import URL.

### 3.1 Modern / SaaS (Most Common)

| Heading | Body | Feel |
|---------|------|------|
| **Inter** (600) | **Inter** (400) | Neutral, professional, safe |
| **Manrope** (700) | **Inter** (400) | Modern with a touch of personality |
| **DM Sans** (700) | **DM Sans** (400) | Rounded and friendly |
| **Plus Jakarta Sans** (700) | **Inter** (400) | Geometric yet warm |

```html
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@500;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
```

### 3.2 Bold / Creative

| Heading | Body | Feel |
|---------|------|------|
| **Space Grotesk** (700) | **Inter** (400) | Tech-bold |
| **Sora** (700) | **DM Sans** (400) | Futuristic |
| **Outfit** (800) | **Source Sans 3** (400) | Geometric power |

```html
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
```

### 3.3 Elegant / Editorial

| Heading | Body | Feel |
|---------|------|------|
| **Playfair Display** (700) | **Lato** (400) | Classic elegance |
| **Cormorant Garamond** (600) | **Raleway** (400) | Literary and high-end |
| **DM Serif Display** (400) | **Nunito** (400) | Modern serif |

```html
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Lato:wght@400;700&display=swap" rel="stylesheet">
```

### 3.4 Corporate / Serious

| Heading | Body | Feel |
|---------|------|------|
| **IBM Plex Sans** (600) | **IBM Plex Sans** (400) | Enterprise-grade |
| **Montserrat** (700) | **Source Sans 3** (400) | Classic business |

```html
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
```

### 3.5 Lively / Youthful

| Heading | Body | Feel |
|---------|------|------|
| **Poppins** (700) | **Poppins** (400) | Rounded geometric |
| **Quicksand** (700) | **Nunito** (400) | Soft and approachable |

```html
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
```

### 3.6 CJK (Chinese) Pairing

Use Noto Sans SC for both headings and body, differentiated by font weight. Use a Latin display font for English portions.

```html
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400;500;700&family=Space+Grotesk:wght@500;700&display=swap" rel="stylesheet">
```
```css
body { font-family: 'Noto Sans SC', 'PingFang SC', 'Microsoft YaHei', sans-serif; }
h1, h2, .heading-en { font-family: 'Space Grotesk', 'Noto Sans SC', sans-serif; }
```

---

## 4. Landing Page Section Recipes

Standard section composition and key CSS structure for a complete Landing Page.

### 4.1 Standard Section Order

```
1. Nav (glassmorphism sticky)
2. Hero (large heading + subtitle + CTA + background decoration)
3. Logo Cloud (partner/trust logos)
4. Feature Grid (3-4 column icon + heading + description)
5. Bento Grid (feature cards of varying sizes)
6. Stats (large number statistics)
7. Testimonials (user reviews)
8. Pricing (plan comparison)
9. FAQ (collapsible Q&A)
10. CTA Section (call to action)
11. Footer (links + copyright)
```

### 4.2 Pricing Section Structure

```html
<!-- Three-column pricing, center highlighted -->
<div class="pricing-grid" style="display:grid; grid-template-columns:repeat(3,1fr); gap:24px; align-items:center;">
  <!-- Basic plan -->
  <div class="card" style="padding:32px; border:1px solid var(--color-border); border-radius:var(--radius-lg);">
    <p class="overline">Basic</p>
    <p style="font-size:var(--text-4xl); font-weight:700;">¥29<span style="font-size:var(--text-sm); color:var(--color-muted);">/mo</span></p>
    <ul><!-- features --></ul>
    <button class="btn-secondary">Choose Plan</button>
  </div>
  <!-- Recommended plan (highlighted) -->
  <div class="card" style="padding:40px 32px; background:var(--color-primary); color:white; border-radius:var(--radius-lg); transform:scale(1.05); box-shadow:var(--shadow-xl);">
    <span class="badge">Most Popular</span>
    <p class="overline" style="color:rgba(255,255,255,0.7);">Pro</p>
    <p style="font-size:var(--text-4xl); font-weight:700;">¥79<span style="font-size:var(--text-sm); opacity:0.7;">/mo</span></p>
    <ul><!-- features --></ul>
    <button style="background:white; color:var(--color-primary);">Choose Plan</button>
  </div>
  <!-- Enterprise plan -->
  <div class="card"><!-- Same structure as Basic --></div>
</div>
```

### 4.3 Testimonial Section Structure

```html
<div style="display:grid; grid-template-columns:repeat(3,1fr); gap:24px;">
  <div class="card" style="padding:24px;">
    <p style="color:var(--color-muted); font-style:italic; line-height:1.6;">
      "The product experience is incredibly smooth — our team's efficiency improved by 40%."
    </p>
    <div style="display:flex; align-items:center; gap:12px; margin-top:16px;">
      <div style="width:40px; height:40px; border-radius:50%; background:var(--color-primary-light);"></div>
      <div>
        <p style="font-weight:600; font-size:14px;">Zhang Ming</p>
        <p style="color:var(--color-muted); font-size:13px;">CTO, Some Tech Company</p>
      </div>
    </div>
  </div>
</div>
```

### 4.4 FAQ Section (Collapsible)

```html
<details style="border-bottom:1px solid var(--color-border); padding:16px 0;">
  <summary style="font-weight:600; cursor:pointer; list-style:none; display:flex; justify-content:space-between; align-items:center;">
    Do you offer refunds?
    <i data-lucide="chevron-down" style="width:20px;"></i>
  </summary>
  <p style="margin-top:12px; color:var(--color-muted); line-height:1.6;">
    We offer a no-questions-asked refund within 14 days of purchase.
  </p>
</details>
```

### 4.5 Stats Section

```html
<div style="display:grid; grid-template-columns:repeat(4,1fr); gap:32px; text-align:center;">
  <div>
    <p style="font-size:var(--text-4xl); font-weight:700; color:var(--color-text);">12,847</p>
    <p style="font-size:var(--text-sm); color:var(--color-muted);">Active Users</p>
  </div>
  <div>
    <p style="font-size:var(--text-4xl); font-weight:700;">99.9%</p>
    <p style="font-size:var(--text-sm); color:var(--color-muted);">Uptime</p>
  </div>
  <!-- ... -->
</div>
```

### 4.6 Footer Structure

```
┌─────────────────────────────────────────┐
│  Logo + one-line brand description        │
│                                         │
│  Product   Company   Resources   Legal  │
│  Feature1  About     Blog        Privacy│
│  Feature2  Team      Docs        Terms  │
│  Pricing   Careers   Help        Cookie │
│                                         │
│  ─────────────────────────────────────  │
│  © 2026 Brand Name        Social icons  │
└─────────────────────────────────────────┘
```

4-column link grid + bottom copyright row + social icons. Use surface-2 or dark background.

---

## 5. Tailwind CSS Shorthand Patterns

Common Tailwind class combinations (reference for Mode A):

```
/* Card */
rounded-xl border bg-card p-6 shadow-sm hover:shadow-lg transition-shadow

/* Button primary */
inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90

/* Button secondary */
inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium hover:bg-accent

/* Button ghost */
inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium hover:bg-accent hover:text-accent-foreground

/* Input */
flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring

/* Badge */
inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold

/* Navbar */
sticky top-0 z-50 w-full border-b bg-background/80 backdrop-blur-sm

/* Section container */
mx-auto max-w-7xl px-6 py-24 lg:px-8

/* Heading group */
mx-auto max-w-2xl text-center
text-4xl font-bold tracking-tight sm:text-5xl
mt-4 text-lg text-muted-foreground
```

---

## 6. SVG Inline Patterns (Hero Patterns Alternative)

SVG patterns that can be inlined directly into CSS background-image:

### 6.1 Micro Dots

```css
background-image: url("data:image/svg+xml,%3Csvg width='20' height='20' viewBox='0 0 20 20' xmlns='http://www.w3.org/2000/svg'%3E%3Ccircle cx='1' cy='1' r='1' fill='%23e2e8f0'/%3E%3C/svg%3E");
```

### 6.2 Cross

```css
background-image: url("data:image/svg+xml,%3Csvg width='40' height='40' viewBox='0 0 40 40' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M20 18v4M18 20h4' stroke='%23e2e8f0' stroke-width='1' fill='none'/%3E%3C/svg%3E");
```

### 6.3 Diagonal Lines

```css
background-image: url("data:image/svg+xml,%3Csvg width='6' height='6' viewBox='0 0 6 6' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M0 6L6 0' stroke='%23e2e8f0' stroke-width='0.5' fill='none'/%3E%3C/svg%3E");
```
