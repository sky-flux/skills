# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [3.0.0] - 2026-03-15

### Added
- `reddit` skill — monitor global Reddit communities (50+ countries, 9 languages) to discover niche product opportunities
  - 15-mode bash script (`reddit.sh`) with curl+jq data pipeline
  - 4-phase opportunity hunting workflow (fetch → analyze → verify → report)
  - Multi-tier global subreddit config (Tier S/A/B by economic value)
  - Multi-language intent keyword matching (EN, DE, FR, PT, ES, JA, KO, AR, FI)
  - User config system (`reddit.sh config`) for output language, industry focus, currency display
  - Opportunity scoring algorithm with solo dev fit assessment
  - `/loop` integration for scheduled scanning

## [2.0.0] - 2026-03-14

### Added
- `michelangelo` skill — generate UI prototypes and production-ready React projects from natural language
- `.github` issue and PR templates
- `CONTRIBUTING.md`
- `LICENSE` file

### Changed
- Translated all skill content to English
- Updated marketplace config (`sky-flux` plugin name)
- Improved README with CLI installation instructions

## [1.0.0] - 2026-03-01

### Added
- `elysiajs` skill — one-stop ElysiaJS reference covering full website, blog posts, and GitHub repository insights
