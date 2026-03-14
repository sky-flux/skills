# Reddit Opportunity Hunter

Discover niche product opportunities by monitoring global Reddit communities. Identifies emerging needs, pain points, and market gaps from thousands of subreddits across developed markets.

## Prerequisites

- `bash` (included on macOS/Linux)
- `curl` (included on macOS/Linux)
- `jq` — JSON query tool

Install jq with: `brew install jq`

## Quick Start

```bash
# Diagnose the environment
reddit.sh diagnose

# Fetch opportunities from global English-speaking communities
reddit.sh fetch --campaign global_english --sort new --pages 1

# View generated opportunities
cat .reddit-leads/scan_report.json
```

## Modes

| Mode | Purpose |
|------|---------|
| `fetch` | Scan subreddits and extract opportunities |
| `comments` | Mine comment threads for deeper insights |
| `search` | Search for specific keywords across Reddit |
| `discover` | Auto-discover high-potential subreddits |
| `profile` | Analyze user profiles and activity patterns |
| `crosspost` | Find cross-subreddit discussions |
| `stickied` | Extract pinned/stickied posts (moderator priorities) |
| `firehose` | Monitor real-time Reddit activity stream |
| `duplicates` | Detect duplicate opportunities across runs |
| `wiki` | Extract knowledge from subreddit wikis |
| `stats` | Generate statistics on findings |
| `export` | Export opportunities to external formats |
| `cleanup` | Archive old leads and reset state |
| `diagnose` | Verify environment and dependencies |

## Configuration

**Campaigns** — Edit `references/subreddits.json` to define subreddit lists:
```json
{
  "global_english": ["r/entrepreneur", "r/ProductManagement", ...],
  "niche_tech": ["r/webdev", "r/golang", ...]
}
```

**Intent Keywords** — Edit `references/intent_keywords.json` to customize opportunity signals:
```json
{
  "pain_points": ["struggling with", "frustrated by", "wish there was"],
  "needs": ["looking for", "need help with", "anyone know"]
}
```

## Output

Results are saved to `.reddit-leads/`:
- `scan_report.json` — Raw opportunities with metadata
- `opportunity_cards.json` — Formatted cards for review
- `state.json` — Timestamp and progress tracking

## Scheduled Scanning

Run scans on a timer:
```bash
/loop 30m /reddit fetch --campaign global_english --sort new --pages 1
```

This runs every 30 minutes with automatic conflict resolution and deduplication.

## Examples

```bash
# Fetch from specific subreddit campaign
reddit.sh fetch --campaign niche_tech --pages 2

# Search for "SaaS pricing" across Reddit
reddit.sh search --query "SaaS pricing" --limit 50

# Auto-discover subreddits matching keywords
reddit.sh discover --keywords "ecommerce,dropshipping" --min-subscribers 5000

# Export opportunities as CSV
reddit.sh export --format csv --output opportunities.csv
```
