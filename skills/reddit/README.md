# Reddit Opportunity Hunter

Monitor global Reddit communities to discover niche product opportunities — unmet pain points, frustrated users, tool-seeking posts — from high-purchasing-power markets (US, UK, EU, DACH, Nordics, JP, KR, AU, and more).

**Core idea:** Scan Reddit → find real user pain points → identify products you can build in 1-2 weeks → price in USD/EUR/GBP.

> 中文文档见下方 [中文说明](#中文说明)

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

```
/loop 30m /reddit
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

---

# 中文说明

## 这是什么？

Reddit Opportunity Hunter 是一个 Claude Code skill，用于从全球 Reddit 社区中发现产品机会。

**核心思路：** 扫描发达国家 Reddit 社区 → 发现真实用户痛点 → 找到可以 1-2 周内做出 MVP 的产品机会 → 用 USD/EUR/GBP 定价，赚汇率差。

## 安装

```bash
npx skills add sky-flux/skills --skill reddit
```

## 依赖

```bash
brew install curl jq
```

## 快速开始

### 第一步：检查环境

```bash
reddit.sh diagnose
```

### 第二步：配置偏好

```bash
reddit.sh config set output_language zh    # 中文输出报告
reddit.sh config set currency_display CNY  # 人民币显示收入
reddit.sh config set focus_industries '["SaaS","DevTools","AI"]'  # 聚焦行业
```

### 第三步：首次扫描

```bash
reddit.sh fetch --campaign global_english --sort new --pages 1
```

### 第四步：让 Claude 分析

直接告诉 Claude：

```
扫描 Reddit 寻找产品机会
```

或使用：

```
/reddit
```

## 工作原理

```
阶段 1：数据采集
  reddit.sh 从配置的 subreddit 抓取帖子
  jq 过滤垃圾信息，富化元数据（意图关键词、情感、技术栈、地理位置）

阶段 2：分析（Claude 执行）
  跨帖子、跨社区聚类痛点
  对每个机会打分（1-10），使用加权公式
  从上下文判断意图等级（1-5）

阶段 3：深度验证（评分 >= 8）
  抓取评论树，看更深层讨论
  搜索竞品投诉
  跨平台验证（可选）

阶段 4：报告
  生成产品机会卡片（含构建评估）
  每日扫描报告 / 周报 / 月报
```

## 配置项

```bash
reddit.sh config show                                # 查看当前配置
reddit.sh config set output_language zh              # 中文报告
reddit.sh config set focus_industries '["SaaS"]'     # 聚焦 SaaS
reddit.sh config set currency_display CNY            # 人民币
reddit.sh config set score_threshold 8               # 只看高分机会
reddit.sh config set max_build_complexity Medium      # 过滤复杂项目
reddit.sh config reset                               # 恢复默认
```

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `output_language` | `en` | 报告语言（zh/en/ja/de/fr/...） |
| `focus_industries` | `[]` | 关注的行业（空=全部） |
| `excluded_subreddits` | `[]` | 跳过的 subreddit |
| `score_threshold` | `7` | 最低报告评分 |
| `max_build_complexity` | `Heavy` | 最大复杂度（Trivial/Light/Medium/Heavy） |
| `currency_display` | `USD` | 收入预估货币（USD/CNY/EUR/GBP/JPY） |

## 15 个模式

### 数据采集

| 模式 | 用法 | 用途 |
|------|------|------|
| `fetch` | `reddit.sh fetch --campaign X --sort new --pages 2` | 抓取并富化帖子 |
| `comments` | `reddit.sh comments <帖子ID> <subreddit>` | 抓取评论树 |
| `search` | `reddit.sh search "关键词" [--global]` | 全 Reddit 搜索 |
| `firehose` | `reddit.sh firehose [sub1+sub2]` | 实时评论流 |
| `stickied` | `reddit.sh stickied [subreddit]` | 置顶帖挖掘 |

### 发现与分析

| 模式 | 用法 | 用途 |
|------|------|------|
| `discover` | `reddit.sh discover <关键词>` | 发现新的高价值 subreddit |
| `profile` | `reddit.sh profile <用户名> [--enrich]` | 用户画像分析 |
| `crosspost` | `reddit.sh crosspost [--campaign X]` | 交叉发帖检测 |
| `duplicates` | `reddit.sh duplicates <帖子ID>` | 链接传播追踪 |
| `wiki` | `reddit.sh wiki <subreddit> [页面]` | 社区 Wiki 知识 |

### 管理

| 模式 | 用法 | 用途 |
|------|------|------|
| `config` | `reddit.sh config [show\|set\|reset]` | 用户偏好配置 |
| `stats` | `reddit.sh stats` | 数据库统计 |
| `export` | `reddit.sh export [--format csv\|json]` | 导出机会数据 |
| `cleanup` | `reddit.sh cleanup` | 清理过期数据 |
| `diagnose` | `reddit.sh diagnose` | 环境健康检查 |

## 全球覆盖

17 个扫描 campaign，覆盖 50+ 国家：

| 层级 | 扫描频率 | 市场 |
|------|---------|------|
| **Tier S** | 每次循环 | 美国、英国、欧盟、德语区、北欧、日本、澳大利亚 |
| **Tier A** | 每天 | 印度、巴西、东南亚、拉美、东欧 |
| **Tier B** | 每周 | 非洲、南亚、土耳其 |

## 定时扫描

```
/loop 30m /reddit
```

每 30 分钟自动扫描，自动去重，按层级优先扫描。

周报：每周日自动生成
月报：每月最后一天自动生成

## 输出目录

```
.reddit/
├── config.json              # 用户配置
├── .reddit.json             # 状态文件（去重、监控、机会追踪）
├── 2026-03-15-scan.md       # 每日扫描报告
├── reports/                 # 周报、月报
├── opportunities/           # 产品机会卡片
└── archive/                 # 历史报告
```

## 安全说明

- 仅采集公开数据（Reddit 公开 JSON API）
- 不存储 PII（仅 Reddit 用户名和公开内容）
- `.reddit/` 目录应加入 `.gitignore`
- 回复草稿标注 `[REVIEW BEFORE POSTING]`，不自动发送
- 遵守 Reddit 速率限制（100 请求/260 秒）
