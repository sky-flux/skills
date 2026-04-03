# Michelangelo

[English](./README.md) | **中文**

用自然语言生成精美 UI 原型和生产级 React 项目。

---

## 功能

Michelangelo 根据需求提供两种模式：

**模式 A — React + Tailwind + shadcn 项目**
生成完整代码库：Vite + React 19 + TypeScript、Tailwind CSS v4 + oklch 设计令牌、shadcn/ui 组件、CVA 变体模式、暗色模式支持。适合需要可交付代码的场景。

**模式 B — 独立 HTML 原型**
生成零依赖的单个 `.html` 文件，直接在浏览器中打开。适合快速 mockup、设计评审或分享概念。

与众不同之处：在写任何代码之前，技能会强制进行设计思考 — 选择个性风格（严肃、活泼、大胆、优雅）、应用视觉层级规则、选择合适的图标库、运行反模式检查。输出避免千篇一律的"AI 蓝"风格。

---

## 触发示例

- "设计一个带侧边栏和动态 Feed 的 SaaS 仪表盘"
- "为一个金融科技 App 做移动端登录页原型"
- "给我做一个开发者工具的落地页"
- "生成一个电商后台的 React + shadcn 项目"
- "让我看看暗色模式的数据分析页长什么样"
- "做一个设置页面 — 简洁、企业感"

---

## 目录结构

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 完整 AI 指令集 — 技能核心逻辑和分步设计流程 |
| `references/design-guide.md` | 设计主指南：视觉层级、排版、间距、颜色、动效、组件模式、反模式检查清单 |
| `references/color-system.md` | 色彩系统参考：Radix 12 阶色阶、shadcn oklch 变量、Tailwind 调色板、7 套预设方案、工具链 |
| `references/design-sizes.md` | 尺寸速查：设备视口、断点、组件尺寸、社交媒体画布尺寸 |
| `references/icon-libraries.md` | 10+ 图标库：安装命令、CDN 链接、React 使用示例 |
| `references/css-recipes.md` | CSS 效果配方：磨砂玻璃、噪点纹理、动态渐变、字体搭配、落地页区块模板 |

---

## 安装

```bash
npx skills add sky-flux/skills --skill michelangelo
```
