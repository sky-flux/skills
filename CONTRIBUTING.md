# Contributing to Sky Flux Skills

Welcome, and thanks for your interest in contributing! This repository is a collection of AI agent skills for Claude Code and other AI coding agents. Contributions of all kinds are appreciated.

## Ways to Contribute

- **New skills** — share a skill that extends what AI agents can do
- **Bug fixes** — correct broken references, outdated content, or broken skill metadata
- **Documentation** — improve clarity in existing SKILL.md files or repo-level docs
- **Feedback** — open an issue to suggest ideas or report problems

## Adding a New Skill

Each skill lives in its own directory under `skills/`:

```
skills/
  your-skill-name/
    SKILL.md          # required
    references/       # optional — supporting files, docs, or data
```

### SKILL.md structure

At minimum, your `SKILL.md` must include a frontmatter block with `name` and `description`, followed by the skill content:

```markdown
---
name: your-skill-name
description: A short, clear description of what this skill does.
---

<!-- Skill instructions go here -->
```

- `name` must be lowercase and hyphen-separated, matching the directory name
- `description` should be a single sentence that clearly states the skill's purpose
- Content should be written in English
- Add a `references/` directory if the skill depends on external files, scraped docs, or supplementary data

## Submitting a Pull Request

1. Fork the repository on GitHub
2. Create a branch from `main` with a descriptive name (e.g., `add-drizzle-skill`)
3. Make your changes
4. Open a pull request targeting `main` on `sky-flux/skills`

Please keep PRs focused — one skill or change per PR makes review easier.

## Skill Quality Guidelines

- The `description` field should tell a user exactly what the skill enables in one sentence
- Skill content should be written in clear English
- Include `references/` files when the skill draws on external knowledge that the agent needs access to
- Avoid bundling unrelated capabilities into a single skill — prefer smaller, composable skills
- Test that your skill loads correctly with `npx skills add` before submitting

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](./LICENSE).
