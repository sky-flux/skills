# Sky Flux Skills

**English** | [中文](./README.zh-CN.md)

Agent skills for Claude Code by [Sky Flux](https://github.com/sky-flux).

## Skills

| Skill | Description |
|-------|-------------|
| [elysiajs](./skills/elysiajs/) | One-stop ElysiaJS skills covering full website, all blog posts, and all GitHub repository insights |
| [michelangelo](./skills/michelangelo/) | Generate beautiful UI prototypes and production-ready React projects from natural language |
| [reddit](./skills/reddit/) | Monitor global Reddit communities to discover niche product opportunities — pain points, unmet needs, market gaps |

## Installation

Install all skills:

```bash
npx skills add sky-flux/skills
```

Install a single skill:

```bash
npx skills add sky-flux/skills --skill elysiajs
npx skills add sky-flux/skills --skill michelangelo
npx skills add sky-flux/skills --skill reddit
```

Install globally (available across all projects):

```bash
npx skills add sky-flux/skills -g
```

## Contributing

Contributions are welcome — new skills, improvements, and bug fixes alike. See [CONTRIBUTING.md](./CONTRIBUTING.md) to get started.

## Support

Open a [GitHub issue](../../issues) if something isn't working or you have a question. Check existing issues first to avoid duplicates.

## License

MIT
