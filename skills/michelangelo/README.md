# Michelangelo

**English** | [中文](./README.zh-CN.md)

Generate beautiful UI prototypes and production-ready React projects from natural language.

---

## What It Does

Michelangelo operates in two modes depending on what you ask for:

**Mode A — React + Tailwind + shadcn project**
Scaffolds a real codebase: Vite + React 19 + TypeScript, Tailwind CSS v4 with oklch design tokens, shadcn/ui components, CVA variant patterns, and dark mode support. Use this when you need working code you can ship.

**Mode B — Self-contained HTML prototype**
Produces a single `.html` file with zero dependencies that opens directly in the browser. Use this for quick mockups, design reviews, or sharing a concept without a build step.

What makes it different: before writing a single line of code, the skill forces design thinking — choosing a personality (serious, playful, bold, elegant), applying visual hierarchy rules, selecting an appropriate icon library, and running an anti-pattern check. The output avoids the generic "AI blue" look.

---

## Trigger Examples

- "Design a SaaS dashboard with a sidebar and activity feed"
- "Prototype a mobile login screen for a fintech app"
- "Make me a landing page for a developer tool"
- "Generate a React + shadcn project for an e-commerce admin panel"
- "Show me what a dark-mode analytics page could look like"
- "Mock up a settings page — clean, enterprise feel"

---

## Contents

| File | Description |
|------|-------------|
| `SKILL.md` | Full AI instruction set — the skill's core logic and step-by-step design process |
| `references/design-guide.md` | Master design guide: visual hierarchy, typography, spacing, color, animation, component patterns, and anti-pattern checklist |
| `references/color-system.md` | Color system reference: Radix 12-step scales, shadcn oklch variables, Tailwind palette, 7 preset schemes, and toolchain |
| `references/design-sizes.md` | Size quick reference: device viewports, breakpoints, component sizes, social media canvas sizes |
| `references/icon-libraries.md` | 10+ icon libraries with install commands, CDN links, and React usage examples |
| `references/css-recipes.md` | CSS effect recipes: frosted glass, noise textures, animated gradients, font pairings, landing page section templates |

---

## Installation

```bash
npx skills add sky-flux/skills --skill michelangelo
```
