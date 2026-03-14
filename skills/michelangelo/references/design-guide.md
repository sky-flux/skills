# Design Guide

> Synthesizing design thinking and quality standards from Material Design 3 · Apple HIG · Ant Design · Refactoring UI.
> This file answers "why" and "how to think". For specific values see design-sizes.md, for colors see color-system.md, for icons see icon-libraries.md.

---

## 1. Design Philosophy Quick Reference

| System | Core Philosophy | Key Takeaways |
|--------|----------------|---------------|
| **Material Design 3** | Dynamic color + expressiveness, user personalization | Color role system, shape as brand expression |
| **Apple HIG** | Clarity + Deference + Depth, content-first | Minimal but deep, 44pt touch targets, semantic colors |
| **Microsoft Fluent** | Inclusive design, cross-platform consistency | Alpha transparency color system, purposeful motion |
| **Ant Design** | Beauty of dynamic order, natural logarithm derivation | 8px spacing, 14px base font size, restraint principle |
| **Refactoring UI** | Tactics over talent, developer perspective | Three dimensions of visual hierarchy, border alternatives, dual-layer shadows |

---

## 2. Visual Hierarchy (The Most Critical Design Skill)

### 2.1 Semantic Hierarchy ≠ Visual Hierarchy

HTML tag hierarchy (h1/h2/h3) and visual hierarchy should be separate. A sidebar heading may be semantic h2, but visually should be smaller and lighter than the main content h3.

### 2.2 Three Weapons Working Together

Don't rely on font size alone! Use font size + font weight + color brightness together.
**Key: Weakening secondary information is more effective than emphasizing primary information.**

### 2.3 Don't Let Semantics Hijack Visuals

A delete button uses gray/secondary style when it's not the page's primary action. It only becomes a red primary button in a confirmation dialog.

### 2.4 Progressive Disclosure

Present information in chunks, don't show everything at once. Use steps for long forms, use collapse/tabs for complex content.

---

## 3. Typography Principles

### 3.1 Font Selection

- Fonts with ≥ 5 weights are generally more refined
- System font stack first (Ant Design recommended): -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif
- Don't use Latin display fonts for CJK (Space Grotesk etc. only for English headings)

### 3.2 Type Scale System

- Ant Design scale: 12 / 14 / 16 / 20 / 24 / 30 / 38 / 46 / 56 / 68 (based on natural logarithm + musical intervals)
- M3 Type Scale: Display / Headline / Title / Body / Label × Large/Medium/Small
- Keep 3-5 type sizes in a single system (except showcase pages)

### 3.3 Line Height Rules

Large headings 1.1-1.2 · Medium headings 1.2-1.3 · Body text 1.5-1.6 · CJK headings 1.3-1.4 · CJK body 1.6-1.8
Ant Design: line height = font size × 1.5 (14px → 22px)

### 3.4 Letter Spacing

Large headings -0.5px · All-caps +0.05-0.1em with font size reduced 15% · Never use negative values for CJK

### 3.5 Line Length

English 45-75 characters (≈65ch) · CJK 25-35 characters · Don't fill the full screen width

### 3.6 Font Weight Restraint

Ant Design: body 400 + 500, English bold 600. In most cases use only two weights.

---

## 4. Spacing Principles

### 4.1 Ant Design Proximity

Higher information relatedness → closer distance. Goal: create organization so users can understand at a glance.
- 8px small spacing: tightly related within a group
- 16px medium spacing: loosely related within a group
- 24px large spacing: between groups

### 4.2 Start with "Too Much Whitespace"

Too little whitespace looks worse than too much. Start with generous space, then gradually reduce.

### 4.3 Spacing Expresses Belonging

Related elements close together (8-12px), unrelated elements far apart (32-64px). Headings sit close to content below, with more distance from the paragraph above.

### 4.4 Always Choose Spacing from the System

4 8 12 16 20 24 32 40 48 64 80 96 128 — Don't make up values.

---

## 5. Color Principles

### 5.1 M3 Color Roles

Named by function (Primary/Secondary/Tertiary + On-*/Container), not by color name. Each color has a 13-level tonal palette.

### 5.2 Ant Design Dual-Layer System

System level (12 base colors × 10 levels) + Product level (brand + functional + neutral). WCAG AAA 7:1 contrast ratio.

### 5.3 Apple HIG Semantic Colors

Use semantic colors, not hardcoded values. Choose one accent color throughout to indicate "interactive". Label four-level hierarchy + Background three-level hierarchy.

### 5.4 Practical Rules

- 60-30-10 color ratio
- Gray with color temperature (cool blue / warm brown)
- Don't use gray text on colorful backgrounds
- Don't rely on color alone to convey information
- Use alpha transparent borders in dark mode
- Brighten brand colors for dark mode, don't use pure black #000

---

## 6. Depth and Shape

### 6.1 M3 Shape System

35+ shapes, shape morphing. Tokenized border radius: None(0) / XS(4) / S(8) / M(12) / L(16) / XL(28) / Full.
Rounder = friendlier, squarer = more serious.

### 6.2 Border Alternatives

Too many borders = cluttered. Prefer: background color contrast · shadow · spacing · accent border.

### 6.3 Apple Liquid Glass

Translucent refraction simulates depth, UI floats above content. Concentric design (UI corner radius aligned with hardware).

---

## 7. Motion Principles

| Context | Duration | Curve |
|---------|----------|-------|
| Hover | 150ms | ease |
| Expand/Collapse | 200-300ms | ease-out |
| Page Transition | 300-400ms | cubic-bezier(.4,0,.2,1) |
| Entrance stagger | 400-600ms + 100ms delay | cubic-bezier(.4,0,.2,1) |

One well-choreographed entrance > ten scattered micro-interactions. All motion must be disableable (prefers-reduced-motion).

---

## 8. Component Design Patterns

### Cards
Padding 24-32px · shadow-sm hover→shadow-lg · if shadow, no border needed · border radius 8-12px

### Hero Section
Overline (brand color uppercase) + Large heading (48-56px Bold tracking-tight) + Subtitle (18-20px muted)
Spacing: heading→subtitle 16px · subtitle→button 32px · background uses gradient/pattern

### Feature Grid (3-4 columns)
Icon with brand color light circle (48px circle + 24px icon) · Title semibold 16-18px · Description 14-15px muted ≤20 words

### Forms
Label above input · semibold 13-14px · input ≥40px · ≤5-7 fields at a time · focus: border→brand color+ring

### Navigation Bar
Height 64px (desktop) / 56px (mobile) · Current page primary + bottom indicator line · On scroll add shadow-sm + backdrop-blur

### Data Display
Numbers largest and boldest (text-3xl bold) · Labels smallest and lightest (text-sm muted) · Trends use semantic colors · Spacing as separator

### Tables
Header uppercase small semibold light gray background · Row border-bottom · Numbers right-aligned · Actions use tertiary

---

## 9. Dark Mode

| Element | Light | Dark |
|---------|-------|------|
| Background | #F8FAFC | #0F172A |
| Surface | #FFFFFF | #1E293B |
| Border | #E2E8F0 | rgba(255,255,255,0.1) |
| Primary Text | #0F172A | #F8FAFC |

Shadows are invisible in dark mode → use borders or lighter surfaces. Don't use pure black #000. Fluent uses alpha transparent colors for consistency across backgrounds.

---

## 10. Accessibility

| Rule | Standard |
|------|----------|
| Body text contrast | ≥ 4.5:1 (AA) / ≥ 7:1 (AAA) |
| Large heading contrast | ≥ 3:1 |
| Minimum touch target | 44×44pt (Apple) / 48×48dp (Material) |
| Don't convey info by color alone | Pair with icon/shape/text |
| Motion can be disabled | prefers-reduced-motion |
| focus-visible not focus | Avoid showing outline on mouse click |
| Semantic HTML | header/nav/main/footer/article |

---

## 11. Anti-Pattern Self-Check List

Check generated code in the following order (see SKILL.md Step 1.3 for details):

1. **Squint test**: Can you make out hierarchy and focal points with the page blurred? → No = #1 No visual hierarchy
2. **Count borders**: More than necessary? → Yes = #2 Border overload (replace with background contrast/shadow/spacing)
3. **Count colors**: Close to 60-30-10? → No = #3 Evenly distributed colors
4. **Check brand color**: Blue again? → Yes = #4 Generic look (choose color based on industry)
5. **Check background**: Pure white #FFF + pure black #000? → Yes = #5 (use #F8FAFC + #0F172A)
6. **Check spacing**: Is there variety? Does it express belonging? → No = #6 Random spacing
7. **Read the copy**: Does it read like a real product or lorem ipsum? → Fake = #7
8. **Count buttons**: Is there a hierarchy? → No = #8 Uniform buttons
9. **Look at cards**: All identical? → Yes = #9 Copy-paste
10. **Check details**: Hover states? Background decoration? Accent border? → None = #10 Lacking polish
11. **Check text on colorful backgrounds**: Using gray text? → Yes = #11 (use a lighter shade of the same hue)
12. **Check uppercase**: Added letter-spacing? → No = #12

---

## 12. Chinese Tech Company Design Systems

| System | Company | Highlights |
|--------|---------|------------|
| Ant Design | Ant Group | Standard for mid/back-end, 8px spacing, 14px base |
| Arco Design | ByteDance | Strong modern feel, built-in dark mode |
| TDesign | Tencent | Cross-platform consistency |
| Semi Design | Douyin | Design2Code |
| Element Plus | Ele.me | Most popular for Vue |
| Vant | Youzan | Mobile e-commerce |
| NutUI | JD.com | Mobile |

---

## 13. Figma Resource Library Picks

| Resource | URL |
|----------|-----|
| 100 Color Combinations | figma.com/resource-library/color-combinations |
| Typography Guide | figma.com/resource-library/typography-in-design |
| Visual Hierarchy | figma.com/resource-library/what-is-visual-hierarchy |
| UI Design Principles | figma.com/resource-library/ui-design-principles |
| 13 Graphic Design Principles | figma.com/resource-library/graphic-design-principles |
| Golden Ratio | figma.com/resource-library/golden-ratio |
| Design System Examples | figma.com/resource-library/design-system-examples |

---

## 14. Responsive Breakpoints

| Breakpoint | Tailwind | Bootstrap | Device |
|------------|----------|-----------|--------|
| sm | 640px | 576px | Large phone landscape |
| md | 768px | 768px | Tablet portrait |
| lg | 1024px | 992px | Tablet landscape |
| xl | 1280px | 1200px | Desktop |
| 2xl | 1536px | 1400px | Large screen |

Mobile-first. 3 columns→2 columns→1 column · sidebar→hamburger · heading 56→36px · padding 64→24px
