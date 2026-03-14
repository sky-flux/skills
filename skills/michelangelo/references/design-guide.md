# 设计指南 (Design Guide)

> 融合 Material Design 3 · Apple HIG · Ant Design · Refactoring UI 的设计思维与质量标准。
> 本文件回答"为什么"和"怎么想"。具体数值查 design-sizes.md，色彩查 color-system.md，图标查 icon-libraries.md。

---

## 1. 设计哲学速查

| 体系 | 核心哲学 | 学到的 |
|------|---------|--------|
| **Material Design 3** | 动态色彩 + 表达性，用户个性化 | 色彩角色系统、形状作为品牌表达 |
| **Apple HIG** | Clarity + Deference + Depth，内容优先 | 极简但有深度、44pt 触控区、语义色 |
| **Microsoft Fluent** | 包容性设计，跨平台统一 | alpha 透明色系统、有目的的动效 |
| **Ant Design** | 动态秩序之美，自然对数推导 | 8px 间距、14px 基准字号、克制原则 |
| **Refactoring UI** | 战术代替天赋，开发者视角 | 视觉层次三维度、边框替代、双层阴影 |

---

## 2. 视觉层次（最核心的设计能力）

### 2.1 语义层次 ≠ 视觉层次

HTML 标签层级 (h1/h2/h3) 和视觉层级应分开。sidebar 标题可能语义 h2，但视觉应比主内容 h3 更小更轻。

### 2.2 三把武器协同

不要只靠字号！同时用字号 + 字重 + 颜色明度。
**关键：弱化次要信息比强化主要信息更有效。**

### 2.3 不让语义绑架视觉

删除按钮不是页面主操作时用灰色/次要样式。只在确认弹窗中变红色 primary。

### 2.4 渐进式披露 (Progressive Disclosure)

信息分块呈现，不要一次展示全部。长表单分步骤，复杂内容用折叠/Tab。

---

## 3. 排版原则

### 3.1 字体选择

- 字重 ≥ 5 的字体通常更精良
- 系统字体栈优先（Ant Design 推荐）：-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif
- CJK 不用拉丁 display 字体 (Space Grotesk 等只用于英文标题)

### 3.2 字阶系统

- Ant Design 推导：12 / 14 / 16 / 20 / 24 / 30 / 38 / 46 / 56 / 68 (基于自然对数+音律)
- M3 Type Scale: Display / Headline / Title / Body / Label × Large/Medium/Small
- 一个系统中字阶控制在 3-5 种（展示页除外）

### 3.3 行高规则

大标题 1.1-1.2 · 中标题 1.2-1.3 · 正文 1.5-1.6 · CJK 标题 1.3-1.4 · CJK 正文 1.6-1.8
Ant Design: 行高 = 字号 × 1.5 (14px → 22px)

### 3.4 字间距

大标题 -0.5px · 全大写 +0.05-0.1em 且字号缩 15% · CJK 绝不用负值

### 3.5 行宽

英文 45-75 字符 (≈65ch) · CJK 25-35 汉字 · 不要填满屏幕

### 3.6 字重克制

Ant Design: 正文 400 + 500，英文加粗 600。多数情况只用两种字重。

---

## 4. 间距原则

### 4.1 Ant Design 亲密性

信息关联性越高 → 距离越近。目的：实现组织性，让用户一目了然。
- 8px 小号间距：同组紧密关联
- 16px 中号间距：组内松散
- 24px 大号间距：组与组之间

### 4.2 从"太多留白"开始

留白不够比太多更难看。先给充裕空间，再逐步减少。

### 4.3 间距表达归属

相关元素靠近 (8-12px)，不相关元素拉远 (32-64px)。标题紧跟下方内容，与上方段落拉开距离。

### 4.4 所有间距从系统中选

4 8 12 16 20 24 32 40 48 64 80 96 128 — 不要拍脑袋。

---

## 5. 色彩原则

### 5.1 M3 色彩角色

按功能命名 (Primary/Secondary/Tertiary + On-*/Container)，不按颜色命名。每色 13 级 tonal palette。

### 5.2 Ant Design 双层体系

系统级 (12 基色 × 10 级) + 产品级 (品牌+功能+中性)。WCAG AAA 7:1 对比度。

### 5.3 Apple HIG 语义色

用语义色而非硬编码。选一个 accent color 贯穿表示"可交互"。Label 四级层次 + Background 三级层次。

### 5.4 实战规则

- 60-30-10 色彩比例
- 灰色带色温 (冷蓝/暖棕)
- 不在彩色背景上用灰色文字
- 不只靠颜色传达信息
- 暗色下 border 用 alpha 透明色
- 暗色品牌色需提亮，不用纯黑 #000

---

## 6. 深度与形状

### 6.1 M3 形状系统

35+ 种形状，shape morphing。圆角 token 化：None(0) / XS(4) / S(8) / M(12) / L(16) / XL(28) / Full。
更圆 = 更友好，更方 = 更严肃。

### 6.2 边框替代

边框太多 = 拥挤。优先用：背景色差 · 阴影 · 间距 · accent border。

### 6.3 Apple Liquid Glass

半透明折射模拟深度，UI 漂浮在内容上方。同心圆设计 (UI 圆角与硬件对齐)。

---

## 7. 动效原则

| 场景 | 时长 | 曲线 |
|------|------|------|
| Hover | 150ms | ease |
| 展开/收起 | 200-300ms | ease-out |
| 页面切换 | 300-400ms | cubic-bezier(.4,0,.2,1) |
| 入场 stagger | 400-600ms + 100ms delay | cubic-bezier(.4,0,.2,1) |

一个精心编排的入场 > 十个散乱微交互。所有动效必须可禁用 (prefers-reduced-motion)。

---

## 8. 组件设计模式

### 卡片
内边距 24-32px · shadow-sm hover→shadow-lg · 有阴影不需边框 · 圆角 8-12px

### Hero Section
Overline(品牌色 uppercase) + 大标题(48-56px Bold tracking-tight) + 副标题(18-20px muted)
间距：标题→副标题 16px · 副标题→按钮 32px · 背景用渐变/pattern

### Feature Grid (3-4列)
图标用品牌色浅底圆(48px圆+24px图标) · 标题 semibold 16-18px · 描述 14-15px muted ≤20 词

### 表单
label 在 input 上方 · semibold 13-14px · input ≥40px · 一次 ≤5-7 字段 · focus: border→品牌色+ring

### 导航栏
高度 64px(desktop)/56px(mobile) · 当前页 primary+底部指示线 · 滚动加 shadow-sm+backdrop-blur

### 数据展示
数字最大最重(text-3xl bold) · 标签最小最轻(text-sm muted) · 趋势用语义色 · 间距分隔

### 表格
表头 uppercase 小号 semibold 浅灰背景 · 行间 border-bottom · 数字右对齐 · 操作用 tertiary

---

## 9. 暗色模式

| 元素 | 亮色 | 暗色 |
|------|------|------|
| 背景 | #F8FAFC | #0F172A |
| Surface | #FFFFFF | #1E293B |
| 边框 | #E2E8F0 | rgba(255,255,255,0.1) |
| 主文字 | #0F172A | #F8FAFC |

暗色下阴影不可见→用边框或更亮 surface。不用纯黑 #000。Fluent 用 alpha 透明色跨背景一致。

---

## 10. 无障碍

| 规则 | 标准 |
|------|------|
| 正文对比度 | ≥ 4.5:1 (AA) / ≥ 7:1 (AAA) |
| 大标题对比度 | ≥ 3:1 |
| 最小触控区 | 44×44pt (Apple) / 48×48dp (Material) |
| 不只用颜色传达信息 | 配图标/形状/文字 |
| 动效可禁用 | prefers-reduced-motion |
| focus-visible 而非 focus | 避免鼠标点击显示 outline |
| 语义 HTML | header/nav/main/footer/article |

---

## 11. 反模式自检清单

生成代码后按以下顺序检查（详见 SKILL.md Step 1.3）：

1. **眯眼测试**: 模糊页面能看出层次和焦点吗？→ 不能 = #1 无视觉层次
2. **数边框**: 超过必要了吗？→ 是 = #2 边框泛滥（用背景色差/阴影/间距替代）
3. **数颜色**: 接近 60-30-10 吗？→ 不是 = #3 色彩均布
4. **查品牌色**: 又是蓝色？→ 是 = #4 千篇一律（根据行业选色）
5. **查底色**: 纯白#FFF + 纯黑#000？→ 是 = #5（用 #F8FAFC + #0F172A）
6. **查间距**: 有大有小吗？表达归属？→ 没有 = #6 间距随机
7. **读文案**: 像真产品还是 lorem ipsum？→ 假的 = #7
8. **数按钮**: 有层级区分吗？→ 没有 = #8 按钮单一
9. **看卡片**: 全一样？→ 是 = #9 复制粘贴
10. **查细节**: hover 状态？背景装饰？accent border？→ 没有 = #10 缺精修
11. **查彩色背景文字**: 用了灰色文字？→ 是 = #11（用同色系浅色）
12. **查大写**: 加了 letter-spacing？→ 没有 = #12

---

## 12. 中国大厂设计系统

| 系统 | 公司 | 特色 |
|------|------|------|
| Ant Design | 蚂蚁 | 中后台标杆，8px间距，14px基准 |
| Arco Design | 字节 | 现代感强，内置暗色 |
| TDesign | 腾讯 | 跨端统一 |
| Semi Design | 抖音 | Design2Code |
| Element Plus | 饿了么 | Vue 最流行 |
| Vant | 有赞 | 移动端电商 |
| NutUI | 京东 | 移动端 |

---

## 13. Figma 资源库精选

| 资源 | URL |
|------|-----|
| 100 Color Combinations | figma.com/resource-library/color-combinations |
| Typography Guide | figma.com/resource-library/typography-in-design |
| Visual Hierarchy | figma.com/resource-library/what-is-visual-hierarchy |
| UI Design Principles | figma.com/resource-library/ui-design-principles |
| 13 Graphic Design Principles | figma.com/resource-library/graphic-design-principles |
| Golden Ratio | figma.com/resource-library/golden-ratio |
| Design System Examples | figma.com/resource-library/design-system-examples |

---

## 14. 响应式断点

| 断点 | Tailwind | Bootstrap | 设备 |
|------|----------|-----------|------|
| sm | 640px | 576px | 大手机横屏 |
| md | 768px | 768px | 平板竖屏 |
| lg | 1024px | 992px | 平板横屏 |
| xl | 1280px | 1200px | 桌面 |
| 2xl | 1536px | 1400px | 大屏 |

移动优先。3列→2列→1列 · sidebar→hamburger · 标题56→36px · padding 64→24px
