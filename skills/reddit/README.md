# Reddit Opportunity Hunter

**English** | [中文](./README.zh-CN.md)

Monitor global Reddit communities to discover niche product opportunities — unmet pain points, frustrated users, tool-seeking posts — from high-purchasing-power markets (US, UK, EU, DACH, Nordics, JP, KR, AU, and more).

**Core idea:** Scan Reddit → find real user pain points → identify products you can build in 1-2 weeks → price in USD/EUR/GBP.

---

## Installation

```bash
npx skills add sky-flux/skills --skill reddit
```

Install globally (available across all projects):

```bash
npx skills add sky-flux/skills --skill reddit -g
```

## Prerequisites

```bash
brew install curl jq
```

- **curl** — HTTP client for Reddit API requests
- **jq** — JSON processor for parsing and enriching Reddit data

## Quick Start

### Step 1: Check your environment

```bash
reddit.sh diagnose
```

This verifies curl, jq, network connectivity, and config files.

### Step 2: Configure your preferences

```bash
reddit.sh config show                    # view current config
reddit.sh config set output_language zh  # Chinese reports
reddit.sh config set currency_display CNY
reddit.sh config set focus_industries '["SaaS","DevTools","AI"]'
```

### Step 3: Run your first scan

```bash
reddit.sh fetch --campaign global_english --sort new --pages 1
```

### Step 4: Let Claude analyze

Just tell Claude:

```
scan Reddit for product opportunities
```

Or use the skill directly:

```
/reddit
```

Claude will run the 4-phase pipeline: fetch → analyze → verify → report.

## How It Works

### 4-Phase Pipeline

```
Phase 1: Data Collection
  reddit.sh fetches posts from configured subreddits
  jq filters spam, enriches with metadata (intent keywords, sentiment, tech stack, geo)

Phase 2: Analysis (Claude)
  Clusters pain points across posts and subreddits
  Scores each opportunity (1-10) using weighted formula
  Classifies intent tier (1-5) from context

Phase 3: Deep Verification (score >= 8)
  Fetches comment trees for deeper discussion
  Searches for competitor complaints
  Cross-platform validation (optional)

Phase 4: Report
  Generates opportunity cards with build assessment
  Daily scan report, weekly/monthly summaries
```

### Scoring Algorithm

Each opportunity is scored 1-10:

| Dimension | Weight | What it measures |
|-----------|--------|-----------------|
| Pain intensity | 20% | Intent tier (1-5), sentiment analysis |
| Competitive gap | 20% | Existing solutions, user complaints |
| Build feasibility | 20% | Can you build an MVP in 1-2 weeks? |
| Market value | 20% | Tier S/A/B market, payment signals |
| Frequency | 15% | How many posts mention this pain? |
| Timeliness | 5% | Persistent pain > flash-in-the-pan |

**Score thresholds:**
- **>= 8** — Deep verification + highlighted in report
- **>= 7** — Included in daily report
- **< 7** — Only in trending pain points

## Modes Reference

### Data Collection

| Mode | Usage | Purpose |
|------|-------|---------|
| `fetch` | `reddit.sh fetch --campaign X --sort new --pages 2` | Fetch & enrich posts from configured subreddits |
| `comments` | `reddit.sh comments <post_id> <subreddit>` | Fetch comment tree with nested replies |
| `search` | `reddit.sh search "query" [--global] [--type post\|user\|subreddit]` | Search across Reddit |
| `firehose` | `reddit.sh firehose [sub1+sub2+sub3]` | Real-time comment stream polling |
| `stickied` | `reddit.sh stickied [subreddit]` | Mine stickied/pinned posts and their comments |

### Discovery & Analysis

| Mode | Usage | Purpose |
|------|-------|---------|
| `discover` | `reddit.sh discover <keyword> [--method keyword\|autocomplete]` | Find new high-value subreddits |
| `profile` | `reddit.sh profile <username> [--enrich]` | Analyze a user's activity and expertise |
| `crosspost` | `reddit.sh crosspost [--campaign X]` | Detect users posting across multiple subreddits |
| `duplicates` | `reddit.sh duplicates <post_id>` | Track link propagation across subreddits |
| `wiki` | `reddit.sh wiki <subreddit> [page]` | Extract knowledge from community wikis |

### Management

| Mode | Usage | Purpose |
|------|-------|---------|
| `config` | `reddit.sh config [show\|set <key> <val>\|reset]` | User preferences (language, industry, currency) |
| `stats` | `reddit.sh stats` | Database statistics (seen posts, opportunities, watched threads) |
| `export` | `reddit.sh export [--format csv\|json]` | Export opportunities for external tools |
| `cleanup` | `reddit.sh cleanup` | Purge expired data (30d posts, expired watches) |
| `diagnose` | `reddit.sh diagnose` | Health check (jq, curl, network, config, rate limit) |

## Configuration

### User Preferences (`.reddit/config.json`)

```bash
reddit.sh config show                                # view all settings
reddit.sh config set output_language zh              # Chinese output
reddit.sh config set focus_industries '["SaaS","AI"]' # focus industries
reddit.sh config set excluded_subreddits '["Entrepreneur"]'
reddit.sh config set score_threshold 8               # only high-value opportunities
reddit.sh config set max_build_complexity Medium      # skip complex projects
reddit.sh config set currency_display CNY            # revenue in CNY
reddit.sh config reset                               # restore defaults
```

| Setting | Default | Description |
|---------|---------|-------------|
| `output_language` | `en` | Report language — `en`, `zh`, `ja`, `de`, `fr`, `es`, `pt`, `ko` |
| `focus_industries` | `[]` | Only surface opportunities in these industries (empty = all) |
| `excluded_subreddits` | `[]` | Skip these subreddits during scanning |
| `score_threshold` | `7` | Minimum opportunity score to include in reports |
| `max_build_complexity` | `Heavy` | Filter: `Trivial` / `Light` / `Medium` / `Heavy` |
| `currency_display` | `USD` | Currency for revenue estimates — `USD`, `CNY`, `EUR`, `GBP`, `JPY` |

### Campaigns (`references/subreddits.json`)

17 campaigns organized by economic value:

| Tier | Scan Frequency | Markets | Example Campaigns |
|------|---------------|---------|-------------------|
| **S** | Every loop | US, UK, EU, DACH, Nordics, JP, AU | `global_english`, `dach`, `france`, `east_asia` |
| **A** | Daily | India, Brazil, SEA, LATAM, Eastern Europe | `india`, `brazil`, `southeast_asia` |
| **B** | Weekly | Africa, South Asia, Turkey | `africa`, `south_asia`, `turkey` |

### Intent Keywords (`references/intent_keywords.json`)

9 languages with 5 intent tiers:

| Tier | Signal | Examples |
|------|--------|---------|
| 1 | Direct purchase intent | "willing to pay", "take my money", "budget for" |
| 2 | Active solution seeking | "looking for a tool", "switching from", "need alternative" |
| 3 | Pain expression | "frustrated with", "too expensive", "spent hours trying" |
| 4 | Research | "what do you use for", "best practices", "evaluating" |
| 5 | Indirect signals | Domain discussions implying unmet needs |

## Output

All data is saved to `.reddit/` in your project root:

```
.reddit/
├── config.json              # your preferences
├── .reddit.json             # state (dedup, watched threads, opportunities)
├── 2026-03-15-scan.md       # daily scan report
├── reports/
│   ├── 2026-W11-weekly.md   # weekly summary
│   └── 2026-03-monthly.md   # monthly summary
├── opportunities/
│   └── soc2-compliance-tool.md  # individual opportunity card
└── archive/                 # old reports
```

### Opportunity Card Format

Each high-scoring opportunity gets a detailed card:

- **Pain Point** — what's the problem, source posts
- **Market Evidence** — frequency, intensity, geography, budget signals
- **Competitive Landscape** — existing solutions, why they fail, the gap
- **Build Assessment** — complexity, MVP scope, build time, solo dev fit
- **Revenue Model** — pricing anchor, suggested tiers (USD/EUR/PPP), distribution, CAC
- **Cross-Market Signal** — which markets have this pain

## Scheduled Scanning

Use Claude Code's `/loop` command to run automated scans:

```bash
/loop 30m /reddit          # scan every 30 minutes (recommended)
/loop 15m /reddit          # more frequent — good for time-sensitive opportunities
/loop 1h /reddit           # hourly — lighter on API budget
```

Each loop cycle:
1. Reads config and subreddit campaigns
2. Fetches by scan priority (Tier S every loop, A daily, B weekly)
3. Deduplicates against seen posts
4. Checks watched threads for new comments
5. Runs competitor keyword searches
6. Claude analyzes, scores, clusters
7. Outputs incremental report
8. High-value (>= 8): alerts `OPPORTUNITY: [title]`
9. Updates subreddit quality scores

**Weekly report:** Auto-generated on Sundays
**Monthly report:** Auto-generated on last day of month

### Tips & Tricks

```bash
# One-off scan without loop
/reddit

# Scan specific campaign only
reddit.sh fetch --campaign dach --sort new --pages 2

# Monitor a trending post for new comments
reddit.sh comments <post_id> <subreddit>

# Find new subreddits to add to your config
reddit.sh discover "your niche keyword"

# Check how many API requests you have left
reddit.sh diagnose

# Deep dive on a high-value user
reddit.sh profile interesting_user --enrich

# Export all discovered opportunities to CSV
reddit.sh export --format csv

# Clean up old data (run monthly)
reddit.sh cleanup
```

## Rate Limits

Reddit unauthenticated API: 100 requests per ~260 seconds.

The script handles this automatically:
- 3-second sleep between requests
- Reads `x-ratelimit-remaining` header
- Waits on 429 (rate limited) responses
- Multi-subreddit merge (`r/A+B+C/new.json`) reduces total requests
- Single Tier S scan uses ~40-45 of 100 request budget

## Safety

- Only collects public data via Reddit's public JSON API
- No PII stored beyond Reddit usernames
- `.reddit/` should be in `.gitignore` (the script warns if missing)
- Reply drafts always marked `[REVIEW BEFORE POSTING]`
- Suggested max: 5 community replies per day

