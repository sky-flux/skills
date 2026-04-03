# Sky Flux Skills

[English](./README.md) | **中文**

由 [Sky Flux](https://github.com/sky-flux) 打造的 Claude Code Agent 技能包。

## 技能列表

| 技能 | 说明 |
|------|------|
| [elysiajs](./skills/elysiajs/) | 一站式 ElysiaJS 技能 — 覆盖官网全部文档、博客文章、GitHub 仓库源码洞察 |
| [michelangelo](./skills/michelangelo/) | 用自然语言生成精美 UI 原型和生产级 React 项目 |
| [reddit](./skills/reddit/) | 监控全球 Reddit 社区，发现 niche 产品机会 — 痛点、未被满足的需求、市场空白 |

## 安装

安装所有技能：

```bash
npx skills add sky-flux/skills
```

安装单个技能：

```bash
npx skills add sky-flux/skills --skill elysiajs
npx skills add sky-flux/skills --skill michelangelo
npx skills add sky-flux/skills --skill reddit
```

全局安装（所有项目可用）：

```bash
npx skills add sky-flux/skills -g
```

## 贡献

欢迎提交新技能、改进和 Bug 修复。请参阅 [CONTRIBUTING.md](./CONTRIBUTING.md) 了解详情。

## 支持

如遇问题或有疑问，请提交 [GitHub Issue](../../issues)。提交前请先搜索已有 Issue 避免重复。

## 许可证

MIT
