# Sub Discovery Pipeline + Algorithm Engine

## Overview

Enhance the Reddit Opportunity Hunter skill with an automated Sub Discovery Pipeline and a 20-algorithm engine. The pipeline covers cold-start discovery (finding relevant subreddits from scratch) and continuous expansion (automatically discovering new high-value subs from existing campaigns). All algorithms are implemented in bash + jq + awk with no external dependencies.

**Two scoring systems in this skill (do not confuse):**
- **Opportunity Score** (existing, in SKILL.md): rates individual product opportunities (1-10), threshold at 7/8. Config key: `score_threshold`.
- **Sub Quality Score** (new, this spec): rates subreddit value for scanning (0-10), threshold at 7.0/5.0. Config key: `sub_quality_threshold`. These are independent scoring systems for different purposes.

**Config additions:** `sub_quality_threshold` (default: `7.0`) must be added to `init_config()` defaults in `reddit.sh` and documented in SKILL.md's config table.

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Sub Discovery Pipeline              │
├──────────┬──────────────┬───────────────────────┤
│  Entry   │   Probing    │   Scoring & Mgmt      │
│          │              │                       │
│ Keyword  │ Reddit Search│ Quality Score (7 dim) │
│ Sub Name │ User Overlap │ Bayesian Average      │
│ Industry │ Crosspost    │ EMA Trend Monitor     │
│          │ Sidebar/Wiki │ Auto-add to Campaign  │
│          │ Name Pattern │ Decay Report          │
└──────────┴──────────────┴───────────────────────┘
        ↕                        ↕
┌─────────────────────────────────────────────────┐
│           Algorithm Engine (cross-cutting)       │
├─────────────────────────────────────────────────┤
│ Aho-Corasick · Bloom Filter · SimHash           │
│ TF-IDF · N-gram · Inverted Index                │
│ Wilson Score · Influence Score · UCB1 Bandit     │
│ Kleinberg Burst · Shannon Entropy · Z-Score     │
│ Apriori · Jaccard · Threshold Cluster · SMA     │
│ Char N-gram · Flesch-Kincaid · Sequential Pat.  │
└─────────────────────────────────────────────────┘
```

## Entry Layer

Three entry points, all output a unified candidate sub list for the probing layer.

### a) Keyword Entry

```bash
reddit.sh discover "bookkeeping" --method deep
```

- Keyword → Reddit subreddit search API
- Keyword → autocomplete API
- Keyword → co-occurrence expansion from reference files
  - "bookkeeping" → "accounting", "invoicing", "reconciliation", "QuickBooks"
  - Expansion source: scan `intent_keywords.json` + `market_keywords.json` for terms co-occurring in the same category/language group
  - Note: this is co-occurrence-based expansion, not NLP semantic analysis (no external dependencies)

**Backward compatibility:** The existing `--method keyword|autocomplete|footprint|overlap` flags continue to work. `--method deep` is a new method that runs the full discovery pipeline (all probing methods). `--method keyword` and `--method autocomplete` remain as lightweight alternatives.

### b) Sub Name Entry

```bash
reddit.sh discover r/Dentistry --method from-sub
```

- Input a known sub → skip search, go directly to deep probing
- Trigger user overlap, crosspost, sidebar, name pattern analysis

### c) Industry Description Entry

```bash
reddit.sh discover "veterinary practice management software" --method industry
```

- Claude decomposes the description into keyword groups
- "veterinary practice management software" → ["veterinary", "vet clinic", "practice management", "animal hospital", "DVM"]
- Each keyword goes through entry a) flow
- Merge and deduplicate all candidate subs

### Method Summary

| Method | Existing/New | Behavior |
|--------|-------------|----------|
| `keyword` | Existing | Reddit subreddit search only (lightweight) |
| `autocomplete` | Existing | Autocomplete API only (lightweight) |
| `footprint` | Existing | Overlap data from state file |
| `overlap` | Existing | Alias for footprint |
| `deep` | **New** | Full pipeline: search + autocomplete + expansion + all probing |
| `from-sub` | **New** | Skip search, deep-probe a known sub |
| `industry` | **New** | Claude decomposes description → multi-keyword deep discovery |
| `*` (catch-all) | **Fix** | Unknown method → print error with valid methods list (currently silently ignored) |

### Unified Output Format

```json
{
  "candidates": [
    {"name": "Dentistry", "source": "keyword_search", "initial_subscribers": 161000},
    {"name": "DentalHygienist", "source": "autocomplete", "initial_subscribers": 28000}
  ]
}
```

## Probing Layer

Five probing methods for each candidate sub, collecting raw data for the scoring layer.

### a) Post Sampling

- Fetch 50-100 recent posts from candidate sub (new + hot, one page each)
- Run through Aho-Corasick engine: single pass extracts all tags (intent / pain / tech / geo)
- Compute baseline metrics: pain post ratio, avg comments, avg score

### b) User Overlap Analysis

- Extract authors of pain-tagged posts from sampled posts (max 20 users)
- `reddit.sh profile <user>` to get their other active subs
- Jaccard Similarity between candidate sub and existing high-value subs
- High-overlap subs → append to candidate list (recursive, max 2 levels deep)

### c) Crosspost Tracking

- Check sampled posts' `num_crossposts`
- For crossposted posts: `reddit.sh duplicates <post_id>`
- Record crosspost source/target subs → related sub candidates

### d) Sub Content Parsing

- `reddit.sh wiki <sub>` to fetch sidebar/wiki
- Regex extract `r/XXX` references
- Referenced subs → append to candidate list

### e) Name Pattern Matching

- From candidate sub name, infer variants:
  - r/Dentistry → probe r/DentistryStudents, r/DentalProfessionals, r/DentistrySchool
  - Patterns: `{name}Students`, `{name}Pros`, `{name}Jobs`, `{name}Career`
- Validate existence via autocomplete API
- Existing ones → append to candidate list

### API Budget Control

Realistic per-candidate API cost:
- Post sampling: 2 calls (new + hot)
- User overlap: 5-10 calls (sample 5-10 authors, not 20, to stay in budget)
- Crosspost: 0-3 calls (only for posts with `num_crossposts > 0`)
- Wiki/sidebar: 1-2 calls
- Name pattern validation: 2-3 autocomplete calls

**Total: ~10-18 calls per candidate sub.**

Budget strategy:
- Limit initial candidates to 10 per discovery run (not 20)
- 10 candidates × 15 avg calls = ~150 calls per discovery run
- Rate limit: ~100 req/260s → split into 2 batches with cooldown
- UCB1 Bandit dynamic allocation: score candidates after post sampling (cheapest probe), skip remaining probes for clearly low-quality candidates
- `--method deep` warns the user about API cost before proceeding

### Probing Output Format

```json
{
  "sub": "Dentistry",
  "sample_posts": 87,
  "pain_posts": 23,
  "avg_comments": 12.4,
  "avg_score": 18.7,
  "user_overlap": {"bookkeeping": 0.03, "accounting": 0.12},
  "crosspost_sources": ["DentalHygienist", "OralSurgery"],
  "sidebar_refs": ["DentalHygienist", "Ortho"],
  "name_variants_found": ["DentistryStudents"]
}
```

## Scoring Layer

7 dimensions, weighted to produce a composite quality score per candidate sub.

### Dimension 1: Pain Density (weight 0.25)

```
pain_density = pain_posts / total_posts
score = pain_density × 10
```

Driven by Aho-Corasick tag data. `pain_posts` = posts tagged "pain" or "request".

### Dimension 2: Purchasing Power (weight 0.20)

```
purchasing_power = weighted_sum(
  geo_tier_score,           # Tier S market user ratio
  budget_mention_rate,      # Posts mentioning budget/pricing
  flesch_kincaid_avg,       # Text professionalism (low readability = professional)
  professional_title_rate   # Sub name/flair implies professional identity
)
```

### Dimension 3: Activity Level (weight 0.15)

```
activity = posts_per_week × log(subscribers)
```

Adjusted: high subscribers but low posting = dead sub (penalized); low subscribers but active posting = active niche (rewarded).

### Dimension 4: Competitor Discussion Density (weight 0.15)

```
competitor_density = posts_mentioning_products / total_posts
```

Aho-Corasick matches product name keywords. High density = mature market with entry opportunity.

### Dimension 5: Engagement Depth (weight 0.10)

```
engagement_depth = avg_comments_per_post × avg_comment_depth
```

Wilson Score correction: a few high-comment posts don't inflate the average.

### Dimension 6: Growth Rate (weight 0.10)

```
growth = (recent_post_rate - older_post_rate) / older_post_rate
```

Last 7 days posting frequency vs previous 30-day average. Positive growth = community expanding.

### Dimension 7: Solo Dev Friendliness (weight 0.05)

```
solo_friendly = weighted_sum(
  small_team_mention_rate,    # "solo", "small team", "freelance"
  self_serve_signal_rate,     # "free trial", "sign up" vs "contact sales"
  no_compliance_mentions      # No HIPAA/SOC2/GDPR = low compliance burden
)
```

### Composite Score

```
raw_score = Σ(dimension_score × weight)   # Range 0-10

# Bayesian Average correction
final_score = (C × global_avg + raw_score × sample_size) / (C + sample_size)
C = 15  # Confidence coefficient (tuned for 50-100 post sample sizes)
```

### Auto-Add Thresholds

- `final_score >= 7.0` → auto-write to `.reddit/discovered_subs.json`, assign to matching campaign
- `final_score >= 5.0` → record to `candidates` queue, re-evaluate next scan
- `final_score < 5.0` → discard, record to `rejected` to avoid re-probing

**Discovered subs storage:** Auto-discovered subs are written to `.reddit/discovered_subs.json` (not the git-tracked `references/subreddits.json`). The fetch pipeline merges both files at read time. This prevents uncommitted drift in the tracked reference file. Users can promote discovered subs to `references/subreddits.json` manually via `reddit.sh promote <sub_name>`.

**Graceful degradation:** Not all scoring dimensions will have data for every sub. If a dimension has insufficient data (e.g., no geo signals found), it falls back to the global average for that dimension rather than scoring 0. This prevents new/small subs from being unfairly penalized.

## Management Layer

Sub lifecycle management: auto-add, continuous monitoring, decay reporting.

### a) Auto-Add to Campaign

When a new sub reaches threshold, auto-determine placement:

1. **By language** → Char N-gram detects sub's primary language
2. **By industry** → TF-IDF extracts sub's characteristic terms, match nearest vertical campaign
3. **By tier** → Purchasing power dimension determines S/A/B tier

Written to `.reddit/discovered_subs.json` (not the git-tracked `references/subreddits.json`):

```json
{
  "discovered": {
    "vertical_education_health": [
      {
        "name": "DentalHygienist",
        "subscribers": 28000,
        "sort_modes": ["new"],
        "pages": 1,
        "_auto_added": true,
        "_added_date": "2026-03-15",
        "_discovery_score": 7.8,
        "_source": "user_overlap:Dentistry"
      }
    ]
  }
}
```

The fetch pipeline merges `references/subreddits.json` + `.reddit/discovered_subs.json` at read time. Promote to tracked file: `reddit.sh promote <sub_name>`.

### b) Continuous Monitoring — EMA Trend Tracking

After each loop scan, update sub's EMA:

```
weekly_score = this_week_pain_hits / this_week_posts_scanned
new_ema = 0.3 × weekly_score + 0.7 × old_ema
```

State stored in `.reddit/.reddit.json`. New fields are **additive** to the existing `{scanned, opportunities, hit_rate}` schema — existing fields are preserved, new fields are appended:

```json
{
  "subreddit_quality": {
    "DentalHygienist": {
      "scanned": 340,
      "opportunities": 12,
      "hit_rate": 3.53,
      "ema_score": 6.8,
      "ema_history": [7.2, 7.0, 6.9, 6.8],
      "peak_score": 7.8,
      "weeks_tracked": 4
    }
  }
}
```

No migration needed — the existing `update_subreddit_quality()` function continues to update `scanned`, `opportunities`, `hit_rate`. New EMA fields are written by a separate `update_sub_ema()` function. Both write to the same object.

### c) Decay Report

Weekly quality change report (no auto-removal, report only):

```markdown
## Sub Quality Weekly Report — YYYY-MM-DD

### Warning: Quality Declining
| Sub | Current EMA | Peak | Decline | Consecutive Weeks |
|-----|------------|------|---------|------------------|
| r/DentalHygienist | 6.8 | 7.8 | -12.8% | 3 |

### Rising Quality
| Sub | Current EMA | Last Week | Increase |
|-----|------------|-----------|---------|
| r/OralSurgery | 7.5 | 6.9 | +8.7% |

### Newly Added
| Sub | Discovery Score | Source | Campaign |
|-----|----------------|--------|----------|
| r/DentistryStudents | 7.2 | name_pattern | vertical_education_health |

### Suggested Actions
- Consider removing r/DentalHygienist (3 consecutive weeks declining, below threshold)
- r/OralSurgery performing strongly, suggest upgrading pages: 1 → 2
```

### d) Trigger Integration

| Scenario | Command | Frequency |
|----------|---------|-----------|
| Cold start | `reddit.sh discover "keyword" --method deep` | Manual |
| Manual expand | `reddit.sh expand --campaign vertical_finance` | Manual |
| Auto expand | Auto-triggered in loop | Weekly |
| Decay report | Auto-generated in loop | Weekly |

## Algorithm Engine

20 algorithms organized into 4 modules, integrated across all pipeline stages.

### Module 1: `algo_engine.sh` — Data Ingestion

Used during fetch phase to replace current jq regex approach.

| Algorithm | Purpose |
|-----------|---------|
| Aho-Corasick | Single-pass multi-pattern matching for all keywords |
| Bloom Filter | O(1) post deduplication, replaces JSON seen_posts |
| Char N-gram | Per-post language detection for multi-language keyword matching |
| Inverted Index | keyword → post_id mapping for fast queries |

Functions:

```bash
algo_compile_keywords()        # Pre-compile tagged keyword file from references/
algo_match_text "$text"        # Single-pass match, returns categorized results
algo_bloom_add "$id"           # Add to bloom filter
algo_bloom_check "$id"         # Check existence (0=unseen, 1=seen)
algo_detect_lang "$text"       # Returns language code
algo_index_add "$kw" "$id"     # Add to inverted index
algo_index_query "$kw"         # Query post IDs by keyword
```

### Module 2: `algo_analysis.sh` — Text Analysis

Used during Claude analysis phase for quantitative data support.

| Algorithm | Purpose |
|-----------|---------|
| TF-IDF | Compute term importance per subreddit |
| N-gram | Extract high-frequency 2-3 word pain phrases |
| SimHash | Near-duplicate detection, merge repeated pain signals |
| Shannon Entropy | Measure topic focus vs scatter in a sub |
| Flesch-Kincaid | Text professionalism → purchasing power signal |
| Apriori | Discover co-occurring pain point combinations (max 20 labels, min-support 0.1) |
| Jaccard Similarity | Compare user set overlap between subs |
| Threshold Cluster | Group subs by Jaccard similarity threshold (replaces Louvain — simpler, bash-friendly) |

**Louvain replaced with Threshold Clustering:** Louvain modularity optimization requires iterative matrix operations impractical in bash. Instead, use threshold-based clustering: compute pairwise Jaccard similarity between subs, group subs where similarity > threshold (e.g., 0.15) into clusters using union-find. Simpler, fast in bash, sufficient for sub grouping.

Functions:

```bash
algo_tfidf "$posts_json" "$sub"                    # Returns [{term, tfidf}]
algo_ngrams "$posts_json" --n 2,3 --min-freq 3     # Returns [{ngram, freq, posts}]
algo_simhash "$text"                                # Returns 64-bit fingerprint
algo_simhash_dist "$h1" "$h2"                       # Returns hamming distance
algo_entropy "$posts_json"                          # Returns 0-10 score
algo_readability "$text"                            # Returns Flesch-Kincaid score
algo_association "$labels" --min-support 0.1        # Returns [{antecedent, consequent, confidence}]
algo_jaccard "$set_a" "$set_b"                      # Returns similarity 0-1
algo_threshold_cluster "$similarity_matrix" --threshold 0.15  # Returns [{cluster_id, subs}]
```

### Module 3: `algo_scoring.sh` — Scoring & Ranking

Used during scoring phase for statistically sound evaluations.

| Algorithm | Purpose |
|-----------|---------|
| Bayesian Average | Small-sample correction for sub quality scores |
| Wilson Score | Confidence-aware post ranking |
| EMA | Trend tracking with recent-data weighting |
| Influence Score | User influence scoring based on accumulated karma + post frequency (replaces PageRank) |

**PageRank replaced with Influence Score:** Building a reply graph from Reddit's public API is too expensive (requires crawling every comment tree). Instead, use a simpler influence score based on data already available from `reddit.sh profile`: `influence = log(link_karma + comment_karma) × active_sub_count × post_frequency`. This avoids extra API calls while still identifying high-value users.

Functions:

```bash
algo_bayesian "$raw" "$n" "$global_avg" "$C"        # Returns corrected score
algo_wilson "$up" "$total" --confidence 0.95         # Returns lower bound
algo_ema_update "$current" "$old_ema" --alpha 0.3    # Returns new EMA
algo_influence "$user_profile_json"                  # Returns influence score
```

### Module 4: `algo_scheduling.sh` — Scheduling & Detection

Used during loop phase for intelligent resource allocation and anomaly detection.

| Algorithm | Purpose |
|-----------|---------|
| UCB1 Bandit | Dynamic scan priority allocation across subs |
| Kleinberg Burst | Detect sudden keyword frequency spikes |
| Z-Score | Anomaly detection for posts and trends |
| SMA Decomposition | Simple Moving Average trend/seasonal separation (replaces STL) |
| Sequential Pattern | Discover user behavior paths (pain → seek → buy) |

**STL replaced with SMA Decomposition:** STL requires LOESS smoothing (weighted polynomial regression) which is impractical in bash. Instead, use Simple Moving Average: `trend = SMA(4 weeks)`, `seasonal = value - trend` averaged over same-week-of-year. Sufficient for detecting "tax season" type patterns. Works with as few as 8 weeks of data (vs STL needing 2+ full cycles).

**Sequential Pattern data source:** User behavior paths are reconstructed from accumulated state, not live API calls. As the loop scans posts over time, it tracks users who appear in multiple scans across intent tiers (pain → seek → buy). Requires 2-4 weeks of accumulated scan data to produce meaningful patterns.

Functions:

```bash
algo_ucb1_priority "$stats_json"                     # Returns [{sub, priority}]
algo_burst_detect "$history_json" --threshold 2.5    # Returns [{keyword, burst: bool}]
algo_zscore "$value" "$mean" "$stddev"               # Returns z-score
algo_sma_decompose "$weekly_json" --window 4         # Returns {trend, seasonal, residual}
algo_sequential_pattern "$timeline" --min-support 0.05  # Returns [{pattern, support}]
```

## File Structure

```
skills/reddit/
├── scripts/
│   ├── reddit.sh              # Main script (existing, add new discover methods + expand + quality + promote)
│   ├── algo_engine.sh         # Aho-Corasick, Bloom Filter, language detection, inverted index
│   ├── algo_analysis.sh       # TF-IDF, N-gram, SimHash, Entropy, Readability, Apriori, Jaccard, Threshold Cluster
│   ├── algo_scoring.sh        # Bayesian, Wilson, EMA, Influence Score
│   ├── algo_scheduling.sh     # UCB1, Burst, Z-Score, SMA, Sequential Pattern
│   └── test/
│       ├── run_tests.sh             # Existing test runner (preserved + extended)
│       ├── fixtures/                # Existing test fixtures (preserved + extended)
│       │   ├── fetch_response.json  # Existing
│       │   ├── comments_response.json  # Existing
│       │   ├── discover_candidates.json  # New: mock discovery results
│       │   ├── user_profiles.json       # New: mock user profile data
│       │   └── scoring_samples.json     # New: mock scoring input data
│       │
│       │   # --- Existing functionality tests (TDD: ensure no regression) ---
│       ├── test_fetch.sh            # Tests for mode_fetch (existing enrich pipeline)
│       ├── test_comments.sh         # Tests for mode_comments (comment tree parsing)
│       ├── test_search.sh           # Tests for mode_search (query + filters)
│       ├── test_discover_legacy.sh  # Tests for existing discover methods (keyword, autocomplete, footprint)
│       ├── test_profile.sh          # Tests for mode_profile (user analysis)
│       ├── test_crosspost.sh        # Tests for mode_crosspost
│       ├── test_stickied.sh         # Tests for mode_stickied
│       ├── test_firehose.sh         # Tests for mode_firehose (comment stream)
│       ├── test_export.sh           # Tests for mode_export (JSON + CSV)
│       ├── test_cleanup.sh          # Tests for mode_cleanup (TTL expiry)
│       ├── test_diagnose.sh         # Tests for mode_diagnose (health check)
│       ├── test_duplicates.sh       # Tests for mode_duplicates
│       ├── test_wiki.sh             # Tests for mode_wiki
│       ├── test_stats.sh            # Tests for mode_stats
│       ├── test_config.sh           # Tests for mode_config (show/set/reset)
│       ├── test_state.sh            # Tests for state management (init, read, update)
│       ├── test_helpers.sh          # Tests for helper functions (watch_check, competitor_search, update_subreddit_quality)
│       │
│       │   # --- New algorithm module tests ---
│       ├── test_algo_engine.sh      # Aho-Corasick, Bloom Filter, lang detect, inverted index
│       ├── test_algo_analysis.sh    # TF-IDF, N-gram, SimHash, Entropy, Readability, Apriori, Jaccard, Threshold Cluster
│       ├── test_algo_scoring.sh     # Bayesian, Wilson, EMA, Influence Score
│       ├── test_algo_scheduling.sh  # UCB1, Burst, Z-Score, SMA, Sequential Pattern
│       │
│       │   # --- New pipeline tests ---
│       ├── test_discover_deep.sh    # Tests for new discover methods (deep, from-sub, industry)
│       ├── test_expand.sh           # Tests for expand command
│       ├── test_quality.sh          # Tests for quality report + EMA history
│       ├── test_promote.sh          # Tests for promote command
│       └── test_scoring_integration.sh  # End-to-end: probing → scoring → auto-add
├── references/
│   ├── subreddits.json        # Existing (NOT auto-modified — read-only reference)
│   ├── intent_keywords.json   # Existing (NOT auto-modified)
│   ├── market_keywords.json   # Existing
│   └── seasonal_patterns.json # Existing
└── SKILL.md                   # Updated with new commands
```

**Runtime data (`.reddit/` — gitignored):**
```
.reddit/
├── .reddit.json               # Existing state file (seen_posts, watched_threads, opportunities, etc.)
├── config.json                # Existing user config
├── discovered_subs.json       # New: auto-discovered subs (merged with references/subreddits.json at read time)
├── algo/                      # New: algorithm engine runtime data
│   ├── bloom.dat              # Bloom filter bit array
│   ├── index/                 # Inverted index (one file per keyword)
│   ├── keywords_compiled.txt  # Pre-compiled tagged keywords for Aho-Corasick
│   └── ngram_cache.json       # N-gram frequency cache
├── reports/                   # Existing
├── opportunities/             # Existing
└── archive/                   # Existing
```

**State file splitting:** Large data structures (inverted index, bloom filter) are stored as separate files under `.reddit/algo/` instead of inside `.reddit.json`. This prevents the state file from growing to megabytes and keeps `update_state()` fast.

## New Commands

| Command | Purpose |
|---------|---------|
| `reddit.sh discover "<keyword>" --method deep` | Cold-start deep discovery from keyword |
| `reddit.sh discover "<sub>" --method from-sub` | Discovery from known sub |
| `reddit.sh discover "<description>" --method industry` | Discovery from industry description |
| `reddit.sh expand --campaign <name>` | Manual expansion for existing campaign |
| `reddit.sh quality [--report\|--history <sub>]` | Quality report and EMA history |
| `reddit.sh promote <sub_name> --campaign <name>` | Move discovered sub from `.reddit/discovered_subs.json` to `references/subreddits.json` under specified campaign |

### `expand` Command Details

`reddit.sh expand --campaign <campaign_name>` performs targeted expansion on an existing campaign:

1. Read the campaign's current subreddits from `references/subreddits.json`
2. For the top 3 highest-EMA subs in this campaign:
   a. Sample recent pain-post authors (5 per sub)
   b. Run user overlap analysis → find new candidate subs
3. For all campaign subs: check crosspost patterns for undiscovered source/target subs
4. Merge all candidates, deduplicate against existing campaign subs and `rejected_subs`
5. Run scoring pipeline on candidates
6. Auto-add qualifying subs to `.reddit/discovered_subs.json` under this campaign

This is the same probing + scoring pipeline as `discover --method deep`, but scoped to a single campaign and seeded from existing high-performing subs rather than keywords.

## Integration with Existing Workflow

### Loop Integration

Add to the existing loop cycle (after step 10 in SKILL.md):

```
11. Weekly: auto-expand — run discovery on top-performing subs' user overlap
12. Weekly: quality report — generate EMA decay/growth report
13. Weekly: SMA update — refresh seasonal trend patterns (requires 8+ weeks of data)
14. Each loop: UCB1 priority — reorder scan priority dynamically
15. Each loop: burst detection — alert on keyword frequency spikes
```

### State Management Extensions

New keys in `.reddit/.reddit.json`:

| Key | Purpose | TTL |
|-----|---------|-----|
| `candidate_subs` | Pending evaluation queue | 30 days |
| `rejected_subs` | Already evaluated, below threshold | 90 days |
| `keyword_frequencies` | Weekly keyword counts for burst detection | 90 days |
| `sub_clusters` | Threshold clustering results | 30 days |
| `user_intent_timeline` | Per-user intent tier progression for sequential pattern mining | 60 days |

**Stored outside `.reddit.json` (in `.reddit/algo/`):**

| File | Purpose | TTL |
|------|---------|-----|
| `bloom.dat` | Post ID deduplication (Bloom filter) | Permanent (periodic rebuild) |
| `index/<keyword>` | Inverted index files | 30 days |
| `keywords_compiled.txt` | Pre-compiled Aho-Corasick keyword file | Rebuilt on keyword file changes |
| `ngram_cache.json` | N-gram frequency data | 30 days |

## Development Approach

**TDD (Test-Driven Development) — strict red-green-refactor cycle:**

### Phase 0: Existing Functionality Test Coverage

Before writing any new code, achieve full test coverage for all existing `reddit.sh` functionality. This creates a regression safety net:

1. **Refactor existing `run_tests.sh`**: Split the current monolithic test file (12 test groups) into per-mode test files. Move existing test groups into the appropriate files. `run_tests.sh` becomes a test runner that discovers and executes all `test_*.sh` files.
2. Write tests for all 14 existing modes: fetch, comments, search, discover, profile, crosspost, stickied, firehose, export, cleanup, diagnose, duplicates, wiki, stats, config
3. Write tests for helper functions: watch_check, competitor_search, update_subreddit_quality
4. Write tests for state management: init_state, read_state, update_state
5. Write tests for enrichment pipeline: enrich_posts (extend existing test group 9)
6. All tests use fixture data (no live API calls)
7. Run full suite → all green before proceeding

**Bloom filter sizing:** capacity 100K post IDs, false positive rate 0.1%, file size ~150KB, 7 hash functions (implemented in awk using djb2/sdbm variants).

**Bayesian Average C=15:** Adjusted from C=50 to C=15. With post sampling capped at 50-100 posts, C=50 would over-regress to the mean. C=15 means a sub with ~15 sampled posts starts reflecting its true score. Rationale: we want subs to differentiate within 1-2 sampling cycles.

### Phase 1-4: New Feature Development (per algorithm module)

Each module follows strict TDD:

1. **RED:** Write test file first (`test_algo_*.sh`) with all expected function signatures, inputs, and outputs
2. **GREEN:** Implement the minimum code to pass all tests
3. **REFACTOR:** Clean up implementation, optimize
4. **REGRESSION:** Run full test suite (existing + new) → all green before next module

### Test Categories

| Category | Files | What They Test |
|----------|-------|----------------|
| **Existing regression** | `test_fetch.sh` through `test_config.sh` | All 14 existing modes + helpers |
| **Algorithm unit** | `test_algo_engine.sh` through `test_algo_scheduling.sh` | Each algorithm function in isolation |
| **Pipeline integration** | `test_discover_deep.sh`, `test_expand.sh`, `test_quality.sh`, `test_promote.sh` | New commands end-to-end |
| **Cross-cutting** | `test_scoring_integration.sh` | Full pipeline: probing → scoring → auto-add |

### Test Runner

Extend existing `run_tests.sh` to discover and run all `test_*.sh` files in the test directory. Each test file uses the same `assert_eq` / `assert_contains` helpers.

## Constraints

- **No external dependencies** — all algorithms implemented in bash + jq + awk
- **Rate limit compliant** — discovery probing respects ~100 req/260s budget
- **Backward compatible** — existing `--method keyword|autocomplete|footprint|overlap` unchanged; new methods added alongside
- **`.reddit/` stays in .gitignore** — all state/data/algo files are local only
- **`references/` is read-only at runtime** — discovered subs go to `.reddit/discovered_subs.json`, merged at read time
- **Dispatch table updated** — new modes (`expand`, `quality`, `promote`) added to the case statement in `reddit.sh`
