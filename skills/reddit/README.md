# Reddit Opportunity Hunter

Monitor global Reddit communities to discover niche product opportunities — unmet pain points, frustrated users, tool-seeking posts — from high-purchasing-power markets.

## Installation

```bash
npx skills add sky-flux/skills --skill reddit
```

Or install globally (available across all projects):

```bash
npx skills add sky-flux/skills --skill reddit -g
```

## Prerequisites

- `bash` (included on macOS/Linux)
- `curl` (included on macOS/Linux)
- `jq` — install with `brew install jq`

## Quick Start

```bash
# Check environment
bash skills/reddit/scripts/reddit.sh diagnose

# First scan — global English SaaS/startup communities
bash skills/reddit/scripts/reddit.sh fetch --campaign global_english --sort new --pages 1

# Use as a skill — just tell Claude:
# "scan Reddit for product opportunities"
# or use /reddit
```

## Modes

| Mode | Usage | Purpose |
|------|-------|---------|
| `fetch` | `reddit.sh fetch --campaign X --sort new --pages 2` | Fetch & enrich posts from configured subreddits |
| `comments` | `reddit.sh comments <post_id> <subreddit>` | Fetch comment tree with nested replies |
| `search` | `reddit.sh search "query" [--global] [--type post\|user\|subreddit]` | Search Reddit |
| `discover` | `reddit.sh discover <keyword> [--method keyword\|autocomplete]` | Find new subreddits |
| `profile` | `reddit.sh profile <username> [--enrich]` | User analysis |
| `crosspost` | `reddit.sh crosspost [--campaign X]` | Cross-poster detection |
| `stickied` | `reddit.sh stickied [subreddit]` | Mine stickied/pinned posts |
| `firehose` | `reddit.sh firehose [sub1+sub2]` | Real-time comment stream |
| `duplicates` | `reddit.sh duplicates <post_id>` | Link propagation tracking |
| `wiki` | `reddit.sh wiki <subreddit> [page]` | Community wiki content |
| `stats` | `reddit.sh stats` | Database statistics |
| `export` | `reddit.sh export [--format csv\|json]` | Export opportunities |
| `cleanup` | `reddit.sh cleanup` | Purge expired data |
| `diagnose` | `reddit.sh diagnose` | Health check |

## Configuration

**Campaigns** — `references/subreddits.json` defines 17 campaigns across 50+ countries:
- Tier S (every loop): global_english, english_developed, dach, france, nordics, east_asia, etc.
- Tier A (daily): india, brazil, southeast_asia, latam_es, eastern_europe, etc.
- Tier B (weekly): africa, south_asia, turkey

**Intent Keywords** — `references/intent_keywords.json` covers 9 languages (EN, DE, FR, PT, ES, JA, KO, AR, FI) with 5 intent tiers.

## Output

Results are saved to `.reddit-leads/` in your project:
- `.reddit.json` — State file (dedup, watched threads, opportunity tracking)
- `YYYY-MM-DD-scan.md` — Daily scan reports
- `reports/` — Weekly and monthly reports
- `opportunities/` — Individual product opportunity cards

## Scheduled Scanning

```
/loop 30m /reddit
```

Scans every 30 minutes with automatic deduplication and tiered scanning.
