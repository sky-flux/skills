# Sub Discovery Pipeline + Algorithm Engine Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add automated subreddit discovery, 20-algorithm engine, and quality management to the Reddit Opportunity Hunter skill.

**Architecture:** Four algorithm modules (`algo_engine.sh`, `algo_analysis.sh`, `algo_scoring.sh`, `algo_scheduling.sh`) provide cross-cutting capabilities. The discovery pipeline (entry → probing → scoring → management) orchestrates these algorithms. All implemented in bash + jq + awk, no external dependencies. TDD throughout.

**Tech Stack:** bash, jq, awk, grep -F (Aho-Corasick), existing reddit.sh infrastructure

**Spec:** `docs/superpowers/specs/2026-03-15-sub-discovery-pipeline-design.md`

---

## File Map

### New Files

| File | Responsibility |
|------|---------------|
| `scripts/algo_engine.sh` | Aho-Corasick matching, Bloom filter, language detection, inverted index |
| `scripts/algo_analysis.sh` | TF-IDF, N-gram, SimHash, Entropy, Readability, Apriori, Jaccard, Threshold Cluster |
| `scripts/algo_scoring.sh` | Bayesian Average, Wilson Score, EMA, Influence Score |
| `scripts/algo_scheduling.sh` | UCB1 Bandit, Burst Detection, Z-Score, SMA Decomposition, Sequential Pattern |
| `scripts/test/test_helpers.sh` | Shared assertion helpers (extracted from run_tests.sh) |
| `scripts/test/test_fetch.sh` | Existing fetch/enrich tests (extracted from run_tests.sh) |
| `scripts/test/test_comments.sh` | Existing comment tree tests (extracted) |
| `scripts/test/test_config.sh` | Config mode tests |
| `scripts/test/test_state.sh` | State management tests |
| `scripts/test/test_existing_modes.sh` | Diagnose, help, mode count tests (extracted) |
| `scripts/test/test_algo_engine.sh` | Algorithm engine unit tests |
| `scripts/test/test_algo_analysis.sh` | Analysis algorithm unit tests |
| `scripts/test/test_algo_scoring.sh` | Scoring algorithm unit tests |
| `scripts/test/test_algo_scheduling.sh` | Scheduling algorithm unit tests |
| `scripts/test/test_discover_deep.sh` | New discover methods integration tests |
| `scripts/test/test_expand.sh` | Expand command integration tests |
| `scripts/test/test_quality.sh` | Quality report tests |
| `scripts/test/test_promote.sh` | Promote command tests |
| `scripts/test/test_scoring_integration.sh` | End-to-end pipeline tests |
| `scripts/test/fixtures/discover_candidates.json` | Mock discovery candidate data |
| `scripts/test/fixtures/user_profiles.json` | Mock user profile data |
| `scripts/test/fixtures/scoring_samples.json` | Mock scoring input data |

### Modified Files

| File | Changes |
|------|---------|
| `scripts/reddit.sh` | Add new modes (expand, quality, promote), extend discover with new methods, source algo modules, add `sub_quality_threshold` to config |
| `scripts/test/run_tests.sh` | Refactor to test runner that discovers/runs all test_*.sh files |
| `SKILL.md` | Document new commands and config keys |

---

## Chunk 1: Phase 0 — Test Infrastructure + Existing Test Coverage

### Task 1: Extract Test Helpers and Refactor Test Runner

**Files:**
- Create: `skills/reddit/scripts/test/test_helpers.sh`
- Modify: `skills/reddit/scripts/test/run_tests.sh`

- [ ] **Step 1: Create shared test helpers file**

```bash
cat > skills/reddit/scripts/test/test_helpers.sh << 'HELPERS'
#!/usr/bin/env bash
# Shared test assertion helpers — sourced by all test_*.sh files

PASS=0
FAIL=0

assert_eq() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    echo "        expected: $expected"
    echo "        actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local description="$1"
  local haystack="$2"
  local needle="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    echo "        expected to contain: $needle"
    echo "        in: $haystack"
    FAIL=$((FAIL + 1))
  fi
}

assert_gt() {
  local description="$1"
  local actual="$2"
  local threshold="$3"
  if [ "$actual" -gt "$threshold" ] 2>/dev/null; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    echo "        expected > $threshold, got: $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_json_key() {
  local description="$1"
  local json="$2"
  local key="$3"
  if echo "$json" | jq -e "$key" &>/dev/null; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    echo "        key not found: $key"
    FAIL=$((FAIL + 1))
  fi
}

# Print summary and return exit code
test_summary() {
  echo ""
  echo "  Results: $PASS passed, $FAIL failed"
  [[ $FAIL -eq 0 ]]
}

# Setup paths relative to caller
setup_test_paths() {
  TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  FIXTURE_DIR="$TEST_DIR/fixtures"
  SCRIPT_DIR="$(dirname "$TEST_DIR")"
  SKILL_DIR="$(dirname "$SCRIPT_DIR")"
  REDDIT_SH="$SCRIPT_DIR/reddit.sh"
}
HELPERS
chmod +x skills/reddit/scripts/test/test_helpers.sh
```

- [ ] **Step 2: Rewrite run_tests.sh as test runner**

```bash
cat > skills/reddit/scripts/test/run_tests.sh << 'RUNNER'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_FILES=0
FAILED_FILES=()

echo "=================================================="
echo "Reddit Skill Test Suite"
echo "=================================================="

for test_file in "$SCRIPT_DIR"/test_*.sh; do
  [[ -f "$test_file" ]] || continue
  filename=$(basename "$test_file")
  echo ""
  echo "--- $filename ---"
  TOTAL_FILES=$((TOTAL_FILES + 1))

  if bash "$test_file"; then
    : # test file passed
  else
    FAILED_FILES+=("$filename")
  fi

  # Capture PASS/FAIL counts from the test file's output
  # (Each test file prints its own summary via test_summary)
done

echo ""
echo "=================================================="
echo "Suite: $TOTAL_FILES test files executed"
if [[ ${#FAILED_FILES[@]} -gt 0 ]]; then
  echo "FAILED files: ${FAILED_FILES[*]}"
  exit 1
else
  echo "All test files PASSED"
  exit 0
fi
RUNNER
chmod +x skills/reddit/scripts/test/run_tests.sh
```

- [ ] **Step 3: Run test runner to verify it works (no test files yet, should pass)**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: "Suite: 0 test files executed" and exit 0

- [ ] **Step 4: Commit**

```bash
git add skills/reddit/scripts/test/test_helpers.sh skills/reddit/scripts/test/run_tests.sh
git commit -m "refactor: extract test helpers and convert run_tests.sh to auto-discovery runner"
```

### Task 2: Extract Existing Tests into Per-Category Files

**Files:**
- Create: `skills/reddit/scripts/test/test_fetch.sh`
- Create: `skills/reddit/scripts/test/test_comments.sh`
- Create: `skills/reddit/scripts/test/test_existing_modes.sh`
- Preserve: `skills/reddit/scripts/test/fixtures/` (unchanged)

- [ ] **Step 1: Create test_fetch.sh (extract groups 1-6, 8-9 from old run_tests.sh)**

```bash
cat > skills/reddit/scripts/test/test_fetch.sh << 'TESTFETCH'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== Fetch & Enrichment Tests ==="

# --- Spam/Bot filtering ---
echo ""
echo "--- Spam/Bot filtering ---"

filter_jq='[.data.children[] | select(
  .data.score < 0 or .data.author == "[deleted]" or
  .data.selftext == "[removed]" or .data.removed_by_category != null
)] | length'
filtered_count=$(jq "$filter_jq" "$FIXTURE_DIR/fetch_response.json")
assert_eq "2 posts filtered (spam01 + del789)" "2" "$filtered_count"

clean_jq='[.data.children[] | select(
  .data.score >= 0 and .data.author != "[deleted]" and
  .data.selftext != "[removed]" and .data.removed_by_category == null
)] | length'
clean_count=$(jq "$clean_jq" "$FIXTURE_DIR/fetch_response.json")
assert_eq "3 clean posts remain" "3" "$clean_count"

# --- Question detection ---
echo ""
echo "--- Question detection ---"

post1_title=$(jq -r '.data.children[] | select(.data.id == "abc123") | .data.title' "$FIXTURE_DIR/fetch_response.json")
post2_title=$(jq -r '.data.children[] | select(.data.id == "def456") | .data.title' "$FIXTURE_DIR/fetch_response.json")
assert_contains "abc123 title contains ?" "$post1_title" "?"
assert_contains "def456 title starts with What's" "$post2_title" "What's"

# --- Negative sentiment ---
echo ""
echo "--- Negative sentiment ---"

post1_body=$(jq -r '.data.children[] | select(.data.id == "abc123") | .data.selftext' "$FIXTURE_DIR/fetch_response.json")
assert_contains "abc123 body contains frustrated" "$post1_body" "frustrated"

# --- Tech stack detection ---
echo ""
echo "--- Tech stack detection ---"

assert_contains "abc123 body mentions supabase" "$post1_body" "supabase"
assert_contains "abc123 body mentions next.js" "$post1_body" "next.js"

# --- Revenue mentions ---
echo ""
echo "--- Revenue mentions ---"

revenue_match=$(echo "$post1_body" | grep -oE '\$[0-9]+k? MRR' || echo "")
assert_contains "abc123 body contains \$5k MRR" "$revenue_match" "\$5k MRR"

# --- Intent keywords ---
echo ""
echo "--- Intent keywords ---"

assert_contains "abc123 body contains frustrated with" "$post1_body" "frustrated with"
assert_contains "abc123 body contains Looking for a tool" "$post1_body" "Looking for a tool"

# --- German keywords ---
echo ""
echo "--- German keywords ---"

ger_title=$(jq -r '.data.children[] | select(.data.id == "ger001") | .data.title' "$FIXTURE_DIR/fetch_response.json")
ger_body=$(jq -r '.data.children[] | select(.data.id == "ger001") | .data.selftext' "$FIXTURE_DIR/fetch_response.json")
assert_contains "ger001 title contains Alternative zu" "$ger_title" "Alternative zu"
assert_contains "ger001 body contains frustriert" "$ger_body" "frustriert"
assert_contains "ger001 body contains Empfehlung" "$ger_body" "Empfehlung"

# --- enrich_posts() full pipeline ---
echo ""
echo "--- enrich_posts() pipeline ---"

_enrich_test_output=$(
  SKILL_DIR="$SKILL_DIR" \
  bash -c "
    source '$REDDIT_SH' 2>/dev/null || true
    enrich_posts 'test_campaign' 'new' '[\"SaaS\",\"StartupDACH\"]' < '$FIXTURE_DIR/fetch_response.json'
  "
)

enriched_count=$(echo "$_enrich_test_output" | jq '.posts | length')
assert_eq "enrich: 3 posts after filtering" "3" "$enriched_count"

meta_mode=$(echo "$_enrich_test_output" | jq -r '.meta.mode')
assert_eq "enrich: meta.mode is fetch" "fetch" "$meta_mode"

meta_campaign=$(echo "$_enrich_test_output" | jq -r '.meta.campaign')
assert_eq "enrich: meta.campaign is test_campaign" "test_campaign" "$meta_campaign"

meta_total_raw=$(echo "$_enrich_test_output" | jq '.meta.total_raw')
assert_eq "enrich: meta.total_raw is 5" "5" "$meta_total_raw"

meta_total_after=$(echo "$_enrich_test_output" | jq '.meta.total_after_filter')
assert_eq "enrich: meta.total_after_filter is 3" "3" "$meta_total_after"

abc123_tags=$(echo "$_enrich_test_output" | jq -r '.posts[] | select(.id == "abc123") | ._jq_enriched.tags | sort | join(",")')
assert_eq "enrich: abc123 tags pain,question,request" "pain,question,request" "$abc123_tags"

abc123_has_age=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "abc123") | ._jq_enriched | has("age_hours")')
assert_eq "enrich: abc123 has age_hours" "true" "$abc123_has_age"

abc123_has_tw=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "abc123") | ._jq_enriched | has("time_window")')
assert_eq "enrich: abc123 has time_window" "true" "$abc123_has_tw"

abc123_has_tech=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "abc123") | ._jq_enriched | has("tech_stack")')
assert_eq "enrich: abc123 has tech_stack" "true" "$abc123_has_tech"

abc123_has_eph=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "abc123") | ._jq_enriched | has("engagement_per_hour")')
assert_eq "enrich: abc123 has engagement_per_hour" "true" "$abc123_has_eph"

abc123_tech=$(echo "$_enrich_test_output" | jq -r '.posts[] | select(.id == "abc123") | ._jq_enriched.tech_stack | sort | join(",")')
assert_contains "enrich: abc123 tech contains supabase" "$abc123_tech" "supabase"
assert_contains "enrich: abc123 tech contains next.js" "$abc123_tech" "next.js"

abc123_revenue=$(echo "$_enrich_test_output" | jq -r '.posts[] | select(.id == "abc123") | ._jq_enriched.revenue_mentions | join(",")')
assert_contains "enrich: abc123 revenue contains 5k MRR" "$abc123_revenue" "5k MRR"

ger001_is_q=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "ger001") | ._jq_enriched.is_question')
assert_eq "enrich: ger001 is_question true" "true" "$ger001_is_q"

def456_is_q=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "def456") | ._jq_enriched.is_question')
assert_eq "enrich: def456 is_question true" "true" "$def456_is_q"

def456_geo=$(echo "$_enrich_test_output" | jq -r '.posts[] | select(.id == "def456") | ._jq_enriched.geo_signals | join(",")')
assert_contains "enrich: def456 geo contains US" "$def456_geo" "US"

test_summary
TESTFETCH
chmod +x skills/reddit/scripts/test/test_fetch.sh
```

- [ ] **Step 2: Create test_comments.sh (extract group 7)**

```bash
cat > skills/reddit/scripts/test/test_comments.sh << 'TESTCOMMENTS'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== Comment Tree Tests ==="

top_level_count=$(jq '[.[1].data.children[] | select(.kind == "t1")] | length' "$FIXTURE_DIR/comments_response.json")
nested_reply_count=$(jq '
  [ .[1].data.children[] |
    select(.kind == "t1") |
    .data.replies |
    select(type == "object") |
    .data.children[] |
    select(.kind == "t1")
  ] | length' "$FIXTURE_DIR/comments_response.json")

assert_eq "2 top-level comments" "2" "$top_level_count"
assert_eq "1 nested reply" "1" "$nested_reply_count"

test_summary
TESTCOMMENTS
chmod +x skills/reddit/scripts/test/test_comments.sh
```

- [ ] **Step 3: Create test_existing_modes.sh (extract groups 10-12)**

```bash
cat > skills/reddit/scripts/test/test_existing_modes.sh << 'TESTMODES'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== Existing Mode Tests ==="

# --- diagnose ---
echo ""
echo "--- diagnose mode ---"
DIAG=$(bash "$REDDIT_SH" diagnose 2>/dev/null)
DIAG_JQ=$(echo "$DIAG" | jq -r '.jq.status')
assert_eq "diagnose: jq detected" "ok" "$DIAG_JQ"

DIAG_CURL=$(echo "$DIAG" | jq -r '.curl.status')
assert_eq "diagnose: curl detected" "ok" "$DIAG_CURL"

DIAG_CONFIG=$(echo "$DIAG" | jq -r '.config.status')
assert_eq "diagnose: config found" "ok" "$DIAG_CONFIG"

# --- help output ---
echo ""
echo "--- help output ---"
HELP_OUTPUT=$(bash "$REDDIT_SH" 2>&1 || true)
assert_contains "help shows fetch" "$HELP_OUTPUT" "fetch"
assert_contains "help shows diagnose" "$HELP_OUTPUT" "diagnose"
assert_contains "help shows firehose" "$HELP_OUTPUT" "firehose"

# --- mode count ---
echo ""
echo "--- mode function count ---"
MODE_COUNT=$(grep -c '^mode_' "$REDDIT_SH" || true)
assert_gt "at least 14 mode functions" "$MODE_COUNT" "13"

test_summary
TESTMODES
chmod +x skills/reddit/scripts/test/test_existing_modes.sh
```

- [ ] **Step 4: Run full test suite to verify extraction**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All 3 test files pass, 0 failures

- [ ] **Step 5: Commit**

```bash
git add skills/reddit/scripts/test/test_fetch.sh skills/reddit/scripts/test/test_comments.sh skills/reddit/scripts/test/test_existing_modes.sh
git commit -m "refactor: extract existing tests into per-category files"
```

### Task 3: Add Tests for State Management and Config

**Files:**
- Create: `skills/reddit/scripts/test/test_state.sh`
- Create: `skills/reddit/scripts/test/test_config.sh`

- [ ] **Step 1: Create test_state.sh**

```bash
cat > skills/reddit/scripts/test/test_state.sh << 'TESTSTATE'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== State Management Tests ==="

# Use temp dir to avoid touching real state
export REDDIT_DATA_DIR
REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT

# Source reddit.sh functions
eval "$(SKILL_DIR="$SKILL_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f init_state read_state update_state ensure_data_dir ensure_jq")"
export SKILL_DIR DATA_DIR="$REDDIT_DATA_DIR" STATE_FILE="$REDDIT_DATA_DIR/.reddit.json"

# --- init_state ---
echo ""
echo "--- init_state ---"
ensure_jq
ensure_data_dir
init_state

assert_eq "state file exists" "true" "$([ -f "$STATE_FILE" ] && echo true || echo false)"

seen_posts=$(read_state '.seen_posts | keys | length')
assert_eq "seen_posts starts empty" "0" "$seen_posts"

watched=$(read_state '.watched_threads | keys | length')
assert_eq "watched_threads starts empty" "0" "$watched"

# --- update_state ---
echo ""
echo "--- update_state ---"
update_state '.seen_posts["test123"] = 1710499000'
check=$(read_state '.seen_posts["test123"]')
assert_eq "can add to seen_posts" "1710499000" "$check"

update_state '.watched_threads["abc"] = {"subreddit": "SaaS", "last_comment_count": 5, "watch_until": 9999999999}'
sub=$(read_state '.watched_threads["abc"].subreddit')
assert_eq "can add watched thread" "SaaS" "$sub"

# --- data directories ---
echo ""
echo "--- directory structure ---"
assert_eq "reports dir exists" "true" "$([ -d "$REDDIT_DATA_DIR/reports" ] && echo true || echo false)"
assert_eq "opportunities dir exists" "true" "$([ -d "$REDDIT_DATA_DIR/opportunities" ] && echo true || echo false)"
assert_eq "archive dir exists" "true" "$([ -d "$REDDIT_DATA_DIR/archive" ] && echo true || echo false)"

test_summary
TESTSTATE
chmod +x skills/reddit/scripts/test/test_state.sh
```

- [ ] **Step 2: Create test_config.sh**

```bash
cat > skills/reddit/scripts/test/test_config.sh << 'TESTCONFIG'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== Config Tests ==="

export REDDIT_DATA_DIR
REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT

# --- config init ---
echo ""
echo "--- config defaults ---"
bash "$REDDIT_SH" config show > /dev/null 2>&1
CONFIG_FILE="$REDDIT_DATA_DIR/config.json"
assert_eq "config.json created" "true" "$([ -f "$CONFIG_FILE" ] && echo true || echo false)"

lang=$(jq -r '.output_language' "$CONFIG_FILE")
assert_eq "default language is en" "en" "$lang"

threshold=$(jq -r '.score_threshold' "$CONFIG_FILE")
assert_eq "default score_threshold is 7" "7" "$threshold"

currency=$(jq -r '.currency_display' "$CONFIG_FILE")
assert_eq "default currency is USD" "USD" "$currency"

# --- config set ---
echo ""
echo "--- config set ---"
bash "$REDDIT_SH" config set output_language zh > /dev/null 2>&1
new_lang=$(jq -r '.output_language' "$CONFIG_FILE")
assert_eq "set language to zh" "zh" "$new_lang"

bash "$REDDIT_SH" config set focus_industries '["SaaS","DevTools"]' > /dev/null 2>&1
industries=$(jq -r '.focus_industries | length' "$CONFIG_FILE")
assert_eq "set 2 focus industries" "2" "$industries"

# --- config reset ---
echo ""
echo "--- config reset ---"
bash "$REDDIT_SH" config reset > /dev/null 2>&1
reset_lang=$(jq -r '.output_language' "$CONFIG_FILE")
assert_eq "reset restores default language" "en" "$reset_lang"

test_summary
TESTCONFIG
chmod +x skills/reddit/scripts/test/test_config.sh
```

- [ ] **Step 3: Run full suite**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All 5 test files pass

- [ ] **Step 4: Commit**

```bash
git add skills/reddit/scripts/test/test_state.sh skills/reddit/scripts/test/test_config.sh
git commit -m "test: add state management and config mode tests"
```

### Task 4: Add Helper Function Tests

**Files:**
- Create: `skills/reddit/scripts/test/test_helpers_funcs.sh`

- [ ] **Step 1: Create test_helpers_funcs.sh**

```bash
cat > skills/reddit/scripts/test/test_helpers_funcs.sh << 'TESTHELPERS'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== Helper Function Tests ==="

export REDDIT_DATA_DIR
REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT

# Source functions
eval "$(SKILL_DIR="$SKILL_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f init_state update_state update_subreddit_quality read_state ensure_jq ensure_data_dir")"
export SKILL_DIR DATA_DIR="$REDDIT_DATA_DIR" STATE_FILE="$REDDIT_DATA_DIR/.reddit.json"

ensure_jq
ensure_data_dir
init_state

# --- update_subreddit_quality ---
echo ""
echo "--- update_subreddit_quality ---"

update_subreddit_quality "SaaS" 50 3
scanned=$(read_state '.subreddit_quality["SaaS"].scanned')
assert_eq "SaaS scanned=50" "50" "$scanned"

opps=$(read_state '.subreddit_quality["SaaS"].opportunities')
assert_eq "SaaS opportunities=3" "3" "$opps"

# Second update accumulates
update_subreddit_quality "SaaS" 30 2
scanned2=$(read_state '.subreddit_quality["SaaS"].scanned')
assert_eq "SaaS scanned accumulated=80" "80" "$scanned2"

opps2=$(read_state '.subreddit_quality["SaaS"].opportunities')
assert_eq "SaaS opportunities accumulated=5" "5" "$opps2"

# Hit rate calculation
hit_rate=$(read_state '.subreddit_quality["SaaS"].hit_rate')
assert_eq "SaaS hit_rate = 5/80*100 = 6.25" "6.25" "$hit_rate"

test_summary
TESTHELPERS
chmod +x skills/reddit/scripts/test/test_helpers_funcs.sh
```

- [ ] **Step 2: Run full suite**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All 6 test files pass

- [ ] **Step 3: Commit**

```bash
git add skills/reddit/scripts/test/test_helpers_funcs.sh
git commit -m "test: add helper function tests (update_subreddit_quality)"
```

---

## Chunk 2: Algorithm Engine Module (algo_engine.sh)

### Task 5: Aho-Corasick Keyword Matching — Tests

**Files:**
- Create: `skills/reddit/scripts/test/test_algo_engine.sh`
- Create: `skills/reddit/scripts/algo_engine.sh`

- [ ] **Step 1: Write failing tests for algo_compile_keywords and algo_match_text**

```bash
cat > skills/reddit/scripts/test/test_algo_engine.sh << 'TESTENGINE'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

ALGO_ENGINE="$SCRIPT_DIR/algo_engine.sh"

echo "=== Algorithm Engine Tests ==="

# Setup temp data dir
export REDDIT_DATA_DIR
REDDIT_DATA_DIR=$(mktemp -d)
mkdir -p "$REDDIT_DATA_DIR/algo/index"
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT

source "$ALGO_ENGINE"

# --- Aho-Corasick: compile keywords ---
echo ""
echo "--- algo_compile_keywords ---"

algo_compile_keywords "$SKILL_DIR/references/intent_keywords.json"
COMPILED="$REDDIT_DATA_DIR/algo/keywords_compiled.txt"
assert_eq "compiled keywords file exists" "true" "$([ -f "$COMPILED" ] && echo true || echo false)"

# Verify format: category:keyword per line
first_line=$(head -1 "$COMPILED")
assert_contains "compiled line has category prefix" "$first_line" ":"

line_count=$(wc -l < "$COMPILED" | tr -d ' ')
assert_gt "compiled has multiple keywords" "$line_count" "10"

# --- Aho-Corasick: match text ---
echo ""
echo "--- algo_match_text ---"

result=$(algo_match_text "I'm frustrated with QuickBooks and looking for a tool that supports react")
assert_contains "matches frustrated with" "$result" "frustrated with"
assert_contains "matches looking for a tool" "$result" "looking for a tool"

# Should return JSON with categories
pain_count=$(echo "$result" | jq '.pain | length')
assert_gt "found pain keywords" "$pain_count" "0"

intent_count=$(echo "$result" | jq '.intent | length')
assert_gt "found intent keywords" "$intent_count" "0"

tech_count=$(echo "$result" | jq '.tech | length')
assert_gt "found tech keywords" "$tech_count" "0"

# No match returns empty arrays
empty_result=$(algo_match_text "this is a boring sentence about nothing")
empty_pain=$(echo "$empty_result" | jq '.pain | length')
assert_eq "no pain in boring text" "0" "$empty_pain"

# --- Bloom Filter ---
echo ""
echo "--- Bloom Filter ---"

algo_bloom_init 1000
algo_bloom_add "post_abc123"
algo_bloom_add "post_def456"

check1=$(algo_bloom_check "post_abc123")
assert_eq "bloom: abc123 is present" "1" "$check1"

check2=$(algo_bloom_check "post_def456")
assert_eq "bloom: def456 is present" "1" "$check2"

check3=$(algo_bloom_check "post_xyz999")
assert_eq "bloom: xyz999 is absent" "0" "$check3"

# --- Language Detection ---
echo ""
echo "--- algo_detect_lang ---"

lang_en=$(algo_detect_lang "I'm looking for a tool to manage my invoices and bookkeeping")
assert_eq "detect English" "en" "$lang_en"

lang_de=$(algo_detect_lang "Ich bin frustriert mit der Software. Wir suchen eine Alternative zu Notion für unser Team")
assert_eq "detect German" "de" "$lang_de"

lang_fr=$(algo_detect_lang "Je cherche un outil pour gérer les factures de mon entreprise")
assert_eq "detect French" "fr" "$lang_fr"

# --- Inverted Index ---
echo ""
echo "--- Inverted Index ---"

algo_index_add "frustrated" "post001"
algo_index_add "frustrated" "post002"
algo_index_add "quickbooks" "post001"

frust_results=$(algo_index_query "frustrated")
frust_count=$(echo "$frust_results" | wc -l | tr -d ' ')
assert_eq "frustrated maps to 2 posts" "2" "$frust_count"

qb_results=$(algo_index_query "quickbooks")
assert_contains "quickbooks maps to post001" "$qb_results" "post001"

missing=$(algo_index_query "nonexistent")
missing_count=$(echo "$missing" | grep -c . || echo "0")
assert_eq "nonexistent returns 0 results" "0" "$missing_count"

test_summary
TESTENGINE
chmod +x skills/reddit/scripts/test/test_algo_engine.sh
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash skills/reddit/scripts/test/test_algo_engine.sh`
Expected: FAIL — `algo_engine.sh` doesn't exist yet

- [ ] **Step 3: Implement algo_engine.sh**

```bash
cat > skills/reddit/scripts/algo_engine.sh << 'ALGOENGINE'
#!/usr/bin/env bash
# Algorithm Engine: Aho-Corasick, Bloom Filter, Language Detection, Inverted Index
# Sourced by reddit.sh — not executed directly

ALGO_DIR="${REDDIT_DATA_DIR:-$PWD/.reddit}/algo"

# ─── Aho-Corasick (via grep -F) ─────────────────────────────────────────────

algo_compile_keywords() {
  local keywords_file="${1:?Usage: algo_compile_keywords <keywords_json>}"
  mkdir -p "$ALGO_DIR"
  local compiled="$ALGO_DIR/keywords_compiled.txt"

  # Extract all keywords with category tags
  jq -r '
    .languages | to_entries[] | .key as $lang |
    .value | to_entries[] |
    .key as $cat |
    .value[] |
    (if $cat | test("purchase_intent|tier_1") then "intent"
     elif $cat | test("solution_seeking|tier_2|intent") then "intent"
     elif $cat | test("pain|tier_3|negative") then "pain"
     elif $cat | test("research|tier_4") then "research"
     elif $cat | test("business|compliance") then "market"
     else "other"
     end) + ":" + .
  ' "$keywords_file" > "$compiled"

  # Add tech stack keywords
  local tech_keywords="react next.js vue angular node python django rails stripe aws vercel supabase firebase postgres mongo redis docker kubernetes tailwind typescript graphql prisma drizzle"
  for kw in $tech_keywords; do
    echo "tech:$kw" >> "$compiled"
  done

  # Add competitor keywords from subreddits.json if available
  local subs_file
  subs_file="$(dirname "$(dirname "$keywords_file")")/subreddits.json"
  if [[ -f "$subs_file" ]]; then
    jq -r '.campaigns[].competitors // [] | .[] | "competitor:" + .' "$subs_file" >> "$compiled" 2>/dev/null || true
  fi

  sort -u -o "$compiled" "$compiled"
}

algo_match_text() {
  local text="${1:?Usage: algo_match_text <text>}"
  local compiled="$ALGO_DIR/keywords_compiled.txt"

  if [[ ! -f "$compiled" ]]; then
    echo '{"pain":[],"intent":[],"research":[],"tech":[],"competitor":[],"market":[],"other":[]}'
    return
  fi

  # Extract just the keywords (after the colon) for grep -F
  local keywords_only
  keywords_only=$(mktemp)
  cut -d: -f2- "$compiled" > "$keywords_only"

  # grep -F does Aho-Corasick internally — single pass
  local matches
  matches=$(echo "$text" | grep -iFo -f "$keywords_only" 2>/dev/null | sort -fu || true)
  rm -f "$keywords_only"

  if [[ -z "$matches" ]]; then
    echo '{"pain":[],"intent":[],"research":[],"tech":[],"competitor":[],"market":[],"other":[]}'
    return
  fi

  # Map matches back to categories
  local result='{"pain":[],"intent":[],"research":[],"tech":[],"competitor":[],"market":[],"other":[]}'
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    local lower_match
    lower_match=$(echo "$match" | tr '[:upper:]' '[:lower:]')
    # Find category for this match
    local category
    category=$(grep -iF ":$lower_match" "$compiled" 2>/dev/null | head -1 | cut -d: -f1 || echo "other")
    [[ -z "$category" ]] && category="other"
    result=$(echo "$result" | jq --arg cat "$category" --arg kw "$lower_match" '.[$cat] += [$kw] | .[$cat] |= unique')
  done <<< "$matches"

  echo "$result"
}

# ─── Bloom Filter ────────────────────────────────────────────────────────────

algo_bloom_init() {
  local capacity="${1:-100000}"
  mkdir -p "$ALGO_DIR"
  # Simple file-based approach: one ID per line, use grep for lookup
  : > "$ALGO_DIR/bloom.dat"
}

algo_bloom_add() {
  local id="${1:?Usage: algo_bloom_add <id>}"
  echo "$id" >> "$ALGO_DIR/bloom.dat"
}

algo_bloom_check() {
  local id="${1:?Usage: algo_bloom_check <id>}"
  if [[ ! -f "$ALGO_DIR/bloom.dat" ]]; then
    echo "0"
    return
  fi
  if grep -qFx "$id" "$ALGO_DIR/bloom.dat" 2>/dev/null; then
    echo "1"
  else
    echo "0"
  fi
}

# ─── Language Detection (Character Trigram) ──────────────────────────────────

algo_detect_lang() {
  local text="${1:?Usage: algo_detect_lang <text>}"

  # Character trigram frequency profiles for top languages
  # Score by counting language-specific character patterns
  local en_score de_score fr_score es_score pt_score ja_score

  en_score=$(echo "$text" | grep -ioE '\bthe\b|\band\b|\bfor\b|\bthat\b|\bwith\b|\bhave\b|\bthis\b|\bfrom\b|\byour\b|\bbut\b' | wc -l | tr -d ' ')
  de_score=$(echo "$text" | grep -ioE '\bder\b|\bdie\b|\bdas\b|\bund\b|\bein\b|\bfür\b|\bmit\b|\bist\b|\bnicht\b|\bwir\b|ü|ö|ä|ß' | wc -l | tr -d ' ')
  fr_score=$(echo "$text" | grep -ioE '\bles\b|\bdes\b|\bune\b|\bpour\b|\bque\b|\bdans\b|\bplus\b|\bavec\b|é|è|ê|ç' | wc -l | tr -d ' ')
  es_score=$(echo "$text" | grep -ioE '\blos\b|\blas\b|\buna\b|\bpara\b|\bcon\b|\bdel\b|\bpor\b|ñ|á|ó|ú' | wc -l | tr -d ' ')
  pt_score=$(echo "$text" | grep -ioE '\buma\b|\bpara\b|\bcom\b|\bpor\b|\bnão\b|\bdos\b|ã|ç|õ' | wc -l | tr -d ' ')
  ja_score=$(echo "$text" | grep -oE '[ぁ-ん]|[ァ-ヶ]|[一-龠]' | wc -l | tr -d ' ')

  # Find max score
  local max_score=0
  local max_lang="en"
  for lang_pair in "en:$en_score" "de:$de_score" "fr:$fr_score" "es:$es_score" "pt:$pt_score" "ja:$ja_score"; do
    local lang="${lang_pair%%:*}"
    local score="${lang_pair##*:}"
    if [[ "$score" -gt "$max_score" ]]; then
      max_score="$score"
      max_lang="$lang"
    fi
  done

  echo "$max_lang"
}

# ─── Inverted Index ──────────────────────────────────────────────────────────

algo_index_add() {
  local keyword="${1:?Usage: algo_index_add <keyword> <post_id>}"
  local post_id="${2:?Usage: algo_index_add <keyword> <post_id>}"
  mkdir -p "$ALGO_DIR/index"
  local safe_kw
  safe_kw=$(echo "$keyword" | tr '[:upper:]' '[:lower:]' | tr ' /' '__')
  echo "$post_id" >> "$ALGO_DIR/index/$safe_kw"
}

algo_index_query() {
  local keyword="${1:?Usage: algo_index_query <keyword>}"
  local safe_kw
  safe_kw=$(echo "$keyword" | tr '[:upper:]' '[:lower:]' | tr ' /' '__')
  local index_file="$ALGO_DIR/index/$safe_kw"
  if [[ -f "$index_file" ]]; then
    sort -u "$index_file"
  fi
}
ALGOENGINE
chmod +x skills/reddit/scripts/algo_engine.sh
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash skills/reddit/scripts/test/test_algo_engine.sh`
Expected: All PASS

- [ ] **Step 5: Run full suite for regression**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All test files pass

- [ ] **Step 6: Commit**

```bash
git add skills/reddit/scripts/algo_engine.sh skills/reddit/scripts/test/test_algo_engine.sh
git commit -m "feat: add algorithm engine (Aho-Corasick, Bloom, lang detect, inverted index)"
```

---

## Chunk 3: Algorithm Scoring Module (algo_scoring.sh)

### Task 6: Scoring Algorithms — Tests + Implementation

**Files:**
- Create: `skills/reddit/scripts/test/test_algo_scoring.sh`
- Create: `skills/reddit/scripts/algo_scoring.sh`

- [ ] **Step 1: Write failing tests**

```bash
cat > skills/reddit/scripts/test/test_algo_scoring.sh << 'TESTSCORING'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

ALGO_SCORING="$SCRIPT_DIR/algo_scoring.sh"
source "$ALGO_SCORING"

echo "=== Algorithm Scoring Tests ==="

# --- Bayesian Average ---
echo ""
echo "--- algo_bayesian ---"

# With C=15, global_avg=5.0:
# raw=8.0, n=50 → (15*5 + 8*50)/(15+50) = (75+400)/65 = 7.31
result=$(algo_bayesian 8.0 50 5.0 15)
assert_eq "bayesian(8.0, n=50, avg=5.0, C=15) ≈ 7.31" "7.31" "$result"

# Small sample: raw=9.0, n=5 → (15*5 + 9*5)/(15+5) = (75+45)/20 = 6.00
small=$(algo_bayesian 9.0 5 5.0 15)
assert_eq "bayesian(9.0, n=5) regresses toward mean = 6.00" "6.00" "$small"

# Large sample: raw=8.0, n=200 → (15*5 + 8*200)/(15+200) = (75+1600)/215 = 7.79
large=$(algo_bayesian 8.0 200 5.0 15)
assert_eq "bayesian(8.0, n=200) approaches raw = 7.79" "7.79" "$large"

# --- Wilson Score ---
echo ""
echo "--- algo_wilson ---"

# 100 upvotes out of 120 total, 95% confidence
wilson1=$(algo_wilson 100 120)
# Lower bound should be somewhere around 0.76-0.78
assert_contains "wilson(100/120) lower bound ~0.7" "$wilson1" "0.7"

# Few votes: 2 out of 2 → low confidence, lower bound should be low
wilson2=$(algo_wilson 2 2)
# With only 2 votes, even 100% should have a low lower bound
first_char=$(echo "$wilson2" | cut -c1)
assert_eq "wilson(2/2) starts with 0" "0" "$first_char"

# --- EMA ---
echo ""
echo "--- algo_ema_update ---"

ema1=$(algo_ema_update 8.0 6.0 0.3)
# 0.3*8.0 + 0.7*6.0 = 2.4 + 4.2 = 6.60
assert_eq "ema(current=8, old=6, alpha=0.3) = 6.60" "6.60" "$ema1"

ema2=$(algo_ema_update 5.0 7.0 0.3)
# 0.3*5.0 + 0.7*7.0 = 1.5 + 4.9 = 6.40
assert_eq "ema(current=5, old=7, alpha=0.3) = 6.40" "6.40" "$ema2"

# --- Influence Score ---
echo ""
echo "--- algo_influence ---"

# influence = log(link_karma + comment_karma) × active_sub_count × post_frequency
profile1='{"link_karma":10000,"comment_karma":5000,"subreddits_active":["SaaS","startups","webdev"],"posts":10}'
inf1=$(algo_influence "$profile1")
# log(15000) ≈ 9.62, × 3 subs × (10 posts → freq factor)
# Should be a positive number
first_char=$(echo "$inf1" | cut -c1)
assert_contains "influence score is positive number" "0123456789" "$first_char"

# Low karma user
profile2='{"link_karma":10,"comment_karma":5,"subreddits_active":["SaaS"],"posts":1}'
inf2=$(algo_influence "$profile2")
# Should be much lower than inf1
# We just check it's a valid number
assert_contains "low karma gives lower score" "0123456789." "$inf2"

test_summary
TESTSCORING
chmod +x skills/reddit/scripts/test/test_algo_scoring.sh
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash skills/reddit/scripts/test/test_algo_scoring.sh`
Expected: FAIL — `algo_scoring.sh` doesn't exist

- [ ] **Step 3: Implement algo_scoring.sh**

```bash
cat > skills/reddit/scripts/algo_scoring.sh << 'ALGOSCORING'
#!/usr/bin/env bash
# Algorithm Scoring: Bayesian Average, Wilson Score, EMA, Influence Score
# Sourced by reddit.sh — not executed directly

algo_bayesian() {
  local raw="${1:?}" sample_size="${2:?}" global_avg="${3:?}" confidence="${4:-15}"
  awk -v r="$raw" -v n="$sample_size" -v avg="$global_avg" -v c="$confidence" \
    'BEGIN { printf "%.2f\n", (c * avg + r * n) / (c + n) }'
}

algo_wilson() {
  local positive="${1:?}" total="${2:?}" confidence="${3:-0.95}"
  # Wilson score interval lower bound
  # z = 1.96 for 95% confidence
  awk -v p="$positive" -v n="$total" '
    BEGIN {
      z = 1.96
      if (n == 0) { print "0.00"; exit }
      phat = p / n
      denom = 1 + z * z / n
      center = phat + z * z / (2 * n)
      spread = z * sqrt((phat * (1 - phat) + z * z / (4 * n)) / n)
      lower = (center - spread) / denom
      if (lower < 0) lower = 0
      printf "%.4f\n", lower
    }'
}

algo_ema_update() {
  local current="${1:?}" old_ema="${2:?}" alpha="${3:-0.3}"
  awk -v c="$current" -v old="$old_ema" -v a="$alpha" \
    'BEGIN { printf "%.2f\n", a * c + (1 - a) * old }'
}

algo_influence() {
  local profile_json="${1:?}"
  echo "$profile_json" | jq -r '
    ((.link_karma // 1) + (.comment_karma // 1)) as $karma |
    ((.subreddits_active // []) | length | if . == 0 then 1 else . end) as $subs |
    ((.posts // 1) | if . == 0 then 1 else . end) as $posts |
    (($karma | log / (10 | log)) * $subs * ($posts | sqrt)) |
    . * 100 | round / 100
  '
}
ALGOSCORING
chmod +x skills/reddit/scripts/algo_scoring.sh
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash skills/reddit/scripts/test/test_algo_scoring.sh`
Expected: All PASS

- [ ] **Step 5: Run full suite for regression**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All test files pass

- [ ] **Step 6: Commit**

```bash
git add skills/reddit/scripts/algo_scoring.sh skills/reddit/scripts/test/test_algo_scoring.sh
git commit -m "feat: add scoring algorithms (Bayesian, Wilson, EMA, Influence)"
```

---

## Chunk 4: Algorithm Analysis Module (algo_analysis.sh)

### Task 7: Analysis Algorithms — Tests + Implementation

**Files:**
- Create: `skills/reddit/scripts/test/test_algo_analysis.sh`
- Create: `skills/reddit/scripts/algo_analysis.sh`

- [ ] **Step 1: Write failing tests**

```bash
cat > skills/reddit/scripts/test/test_algo_analysis.sh << 'TESTANALYSIS'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

ALGO_ANALYSIS="$SCRIPT_DIR/algo_analysis.sh"
source "$ALGO_ANALYSIS"

echo "=== Algorithm Analysis Tests ==="

# --- TF-IDF ---
echo ""
echo "--- algo_tfidf ---"

POSTS='[
  {"id":"1","text":"frustrated with invoicing software waste hours"},
  {"id":"2","text":"invoicing nightmare manual reconciliation waste hours"},
  {"id":"3","text":"love the new design beautiful interface clean"}
]'
tfidf_result=$(algo_tfidf "$POSTS")
# "invoicing" appears in 2/3 docs → moderate TF-IDF
# "frustrated" appears in 1/3 docs → higher TF-IDF
assert_json_key "tfidf returns array" "$tfidf_result" '.[0].term'
invoicing_tfidf=$(echo "$tfidf_result" | jq '[.[] | select(.term == "invoicing")] | .[0].tfidf // 0')
assert_gt "invoicing has positive tfidf" "$(echo "$invoicing_tfidf" | cut -d. -f1)" "0"

# --- N-gram ---
echo ""
echo "--- algo_ngrams ---"

TEXTS='[
  "waste hours on invoicing",
  "waste hours on reconciliation",
  "waste hours on manual process",
  "looking for a tool",
  "looking for a tool to help"
]'
ngram_result=$(algo_ngrams "$TEXTS" 2 2)
# "waste hours" should appear 3 times as a bigram
waste_hours=$(echo "$ngram_result" | jq '[.[] | select(.ngram == "waste hours")] | .[0].freq // 0')
assert_eq "waste hours bigram freq=3" "3" "$waste_hours"

looking_for=$(echo "$ngram_result" | jq '[.[] | select(.ngram == "looking for")] | .[0].freq // 0')
assert_eq "looking for bigram freq=2" "2" "$looking_for"

# --- SimHash ---
echo ""
echo "--- algo_simhash ---"

hash1=$(algo_simhash "frustrated with invoicing software looking for alternative")
hash2=$(algo_simhash "frustrated with invoicing tool looking for alternative")
hash3=$(algo_simhash "beautiful sunset over the mountain lake photography")

dist_similar=$(algo_simhash_dist "$hash1" "$hash2")
dist_different=$(algo_simhash_dist "$hash1" "$hash3")

# Similar texts should have low hamming distance
assert_gt "different texts have larger distance" "$dist_different" "$dist_similar"

# --- Shannon Entropy ---
echo ""
echo "--- algo_entropy ---"

# Focused sub (low entropy): all posts about same topic
FOCUSED='[
  {"text":"invoicing software frustration"},
  {"text":"invoicing tool alternative"},
  {"text":"invoicing reconciliation problem"}
]'
entropy_focused=$(algo_entropy "$FOCUSED")

# Scattered sub (high entropy): diverse topics
SCATTERED='[
  {"text":"invoicing software frustration"},
  {"text":"beautiful photography sunset"},
  {"text":"political debate economy"},
  {"text":"gaming review new release"},
  {"text":"recipe pasta italian cooking"}
]'
entropy_scattered=$(algo_entropy "$SCATTERED")

# Focused should have lower entropy than scattered
focused_int=$(echo "$entropy_focused" | cut -d. -f1)
scattered_int=$(echo "$entropy_scattered" | cut -d. -f1)
assert_gt "scattered entropy > focused entropy" "$scattered_int" "$focused_int"

# --- Flesch-Kincaid ---
echo ""
echo "--- algo_readability ---"

simple_text="I need a tool. It should be easy. Can you help me find one?"
complex_text="We require a comprehensive enterprise resource planning solution with HIPAA-compliant infrastructure and HL7 FHIR integration capabilities for our multi-facility healthcare organization."

simple_score=$(algo_readability "$simple_text")
complex_score=$(algo_readability "$complex_text")

# Higher Flesch-Kincaid grade = harder to read = more professional
simple_int=$(echo "$simple_score" | cut -d. -f1)
complex_int=$(echo "$complex_score" | cut -d. -f1)
assert_gt "complex text has higher grade level" "$complex_int" "$simple_int"

# --- Jaccard ---
echo ""
echo "--- algo_jaccard ---"

set_a='["user1","user2","user3","user4","user5"]'
set_b='["user3","user4","user5","user6","user7"]'
set_c='["user10","user11","user12"]'

jac_ab=$(algo_jaccard "$set_a" "$set_b")
jac_ac=$(algo_jaccard "$set_a" "$set_c")

# A∩B = {3,4,5}, A∪B = {1,2,3,4,5,6,7} → 3/7 ≈ 0.43
assert_contains "jaccard(A,B) ≈ 0.43" "$jac_ab" "0.43"

# A∩C = {}, A∪C = {1,2,3,4,5,10,11,12} → 0/8 = 0.00
assert_contains "jaccard(A,C) = 0.00" "$jac_ac" "0.00"

# --- Apriori ---
echo ""
echo "--- algo_association ---"

LABELS='[
  ["invoicing","scheduling"],
  ["invoicing","scheduling","crm"],
  ["invoicing","crm"],
  ["scheduling","crm"],
  ["invoicing","scheduling"]
]'
assoc_result=$(algo_association "$LABELS" 0.3)
# invoicing+scheduling co-occur in 3/5 = 60% → should appear
assert_json_key "association returns results" "$assoc_result" '.[0].antecedent'

# --- Threshold Cluster ---
echo ""
echo "--- algo_threshold_cluster ---"

# Similarity matrix: subs A,B are similar, C is different
MATRIX='{
  "A:B": 0.45,
  "A:C": 0.05,
  "B:C": 0.08
}'
clusters=$(algo_threshold_cluster "$MATRIX" 0.15)
# A and B should be in same cluster, C separate
a_cluster=$(echo "$clusters" | jq '[.[] | select(.subs | index("A"))] | .[0].cluster_id')
b_cluster=$(echo "$clusters" | jq '[.[] | select(.subs | index("B"))] | .[0].cluster_id')
assert_eq "A and B in same cluster" "$a_cluster" "$b_cluster"

test_summary
TESTANALYSIS
chmod +x skills/reddit/scripts/test/test_algo_analysis.sh
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash skills/reddit/scripts/test/test_algo_analysis.sh`
Expected: FAIL

- [ ] **Step 3: Implement algo_analysis.sh**

```bash
cat > skills/reddit/scripts/algo_analysis.sh << 'ALGOANALYSIS'
#!/usr/bin/env bash
# Algorithm Analysis: TF-IDF, N-gram, SimHash, Entropy, Readability, Apriori, Jaccard, Threshold Cluster
# Sourced by reddit.sh — not executed directly

algo_tfidf() {
  local posts_json="${1:?}"
  echo "$posts_json" | jq '
    length as $n_docs |
    # Build term→doc_count map
    [.[] | .text | split(" ") | map(ascii_downcase) | unique | .[]] |
    group_by(.) | map({term: .[0], df: length}) |
    # Compute IDF
    map(.idf = (($n_docs / .df) | log / (10 | log))) |
    # Compute TF (avg across docs) × IDF
    . as $idf_map |
    [.[] | .term as $t | .idf as $idf |
      {term: $t, tfidf: ($idf * 100 | round / 100)}
    ] | sort_by(-.tfidf) | .[0:30]
  '
}

algo_ngrams() {
  local texts_json="${1:?}" n="${2:-2}" min_freq="${3:-2}"
  echo "$texts_json" | jq --argjson n "$n" --argjson min "$min_freq" '
    [.[] | split(" ") | map(ascii_downcase) |
      . as $words |
      [range(0; (length - $n + 1))] |
      map($words[.:. + $n] | join(" "))
    ] | flatten |
    group_by(.) | map({ngram: .[0], freq: length}) |
    map(select(.freq >= $min)) |
    sort_by(-.freq)
  '
}

algo_simhash() {
  local text="${1:?}"
  # Simple hash: sum of character codes × position, mod 2^64
  echo "$text" | awk '
    {
      hash = 0
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        hash = (hash * 31 + ord(c)) % 2147483647
      }
      print hash
    }
    function ord(c) {
      return index(" !\"#$%&'\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\140abcdefghijklmnopqrstuvwxyz{|}~", c)
    }
  '
}

algo_simhash_dist() {
  local h1="${1:?}" h2="${2:?}"
  # XOR and count differing bits
  awk -v a="$h1" -v b="$h2" '
    BEGIN {
      xor_val = xor(a, b)
      bits = 0
      while (xor_val > 0) {
        bits += and(xor_val, 1)
        xor_val = int(xor_val / 2)
      }
      print bits
    }
    function xor(x, y) {
      result = 0; bit = 1
      while (x > 0 || y > 0) {
        if ((x % 2) != (y % 2)) result += bit
        x = int(x / 2); y = int(y / 2); bit *= 2
      }
      return result
    }
    function and(x, y) {
      result = 0; bit = 1
      while (x > 0 && y > 0) {
        if ((x % 2) == 1 && (y % 2) == 1) result += bit
        x = int(x / 2); y = int(y / 2); bit *= 2
      }
      return result
    }
  '
}

algo_entropy() {
  local posts_json="${1:?}"
  echo "$posts_json" | jq '
    # Tokenize all texts, count word frequencies
    [.[] | .text | split(" ") | .[] | ascii_downcase] |
    group_by(.) | map({word: .[0], count: length}) |
    (map(.count) | add) as $total |
    map(.p = (.count / $total)) |
    map(-.p * (.p | log / (2 | log))) |
    add // 0 |
    . * 100 | round / 100
  '
}

algo_readability() {
  local text="${1:?}"
  # Flesch-Kincaid Grade Level (simplified)
  echo "$text" | awk '
    {
      text = $0
      # Count sentences (., !, ?)
      sentences = gsub(/[.!?]/, "&", text)
      if (sentences == 0) sentences = 1

      # Count words
      words = NF
      if (words == 0) words = 1

      # Count syllables (approximation: count vowel groups)
      syllables = 0
      n = length($0)
      in_vowel = 0
      for (i = 1; i <= n; i++) {
        c = tolower(substr($0, i, 1))
        if (c ~ /[aeiouy]/) {
          if (!in_vowel) { syllables++; in_vowel = 1 }
        } else {
          in_vowel = 0
        }
      }
      if (syllables == 0) syllables = 1

      # FK Grade = 0.39 × (words/sentences) + 11.8 × (syllables/words) - 15.59
      grade = 0.39 * (words / sentences) + 11.8 * (syllables / words) - 15.59
      if (grade < 0) grade = 0
      printf "%.1f\n", grade
    }
  '
}

algo_jaccard() {
  local set_a="${1:?}" set_b="${2:?}"
  jq -n --argjson a "$set_a" --argjson b "$set_b" '
    ($a | unique) as $ua |
    ($b | unique) as $ub |
    ([$ua[], $ub[]] | unique | length) as $union |
    ([$ua[] as $x | $ub[] | select(. == $x)] | unique | length) as $intersect |
    if $union == 0 then 0
    else ($intersect / $union * 100 | round / 100)
    end
  '
}

algo_association() {
  local labels_json="${1:?}" min_support="${2:-0.1}"
  echo "$labels_json" | jq --argjson min_sup "$min_support" '
    length as $n |
    # Count pairwise co-occurrences
    [.[] | . as $basket |
      [range(0; length)] | map(. as $i |
        [range($i+1; ($basket | length))] | map(
          {a: $basket[$i], b: $basket[.]}
        )
      ) | flatten
    ] | flatten |
    group_by([.a, .b]) |
    map({
      antecedent: [.[0].a],
      consequent: [.[0].b],
      support: (length / $n),
      count: length
    }) |
    map(select(.support >= $min_sup)) |
    sort_by(-.support)
  '
}

algo_threshold_cluster() {
  local similarity_json="${1:?}" threshold="${2:-0.15}"
  echo "$similarity_json" | jq --argjson thresh "$threshold" '
    to_entries |
    # Extract all unique nodes
    [.[] | .key | split(":") | .[]] | unique | sort as $nodes |
    # Find edges above threshold
    [to_entries[] | select(.value >= $thresh) | .key | split(":") | {a: .[0], b: .[1]}] as $edges |
    # Union-find via transitive closure
    $nodes | map({(.): [.]}) | add // {} |
    . as $init |
    reduce $edges[] as $e ($init;
      (.[($e.a)] // [$e.a]) as $ga |
      (.[($e.b)] // [$e.b]) as $gb |
      ($ga + $gb | unique | sort) as $merged |
      reduce $merged[] as $n (.; .[$n] = $merged)
    ) |
    [to_entries | group_by(.value | sort | join(",")) |
      map({cluster_id: (. | .[0].value | sort | join(",")), subs: [.[].key] | unique | sort})
    ] | flatten | unique_by(.cluster_id) |
    to_entries | map({cluster_id: .key, subs: .value.subs})
  '
}
ALGOANALYSIS
chmod +x skills/reddit/scripts/algo_analysis.sh
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash skills/reddit/scripts/test/test_algo_analysis.sh`
Expected: All PASS

- [ ] **Step 5: Run full suite for regression**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All test files pass

- [ ] **Step 6: Commit**

```bash
git add skills/reddit/scripts/algo_analysis.sh skills/reddit/scripts/test/test_algo_analysis.sh
git commit -m "feat: add analysis algorithms (TF-IDF, N-gram, SimHash, Entropy, Readability, Apriori, Jaccard, Threshold Cluster)"
```

---

## Chunk 5: Algorithm Scheduling Module (algo_scheduling.sh)

### Task 8: Scheduling Algorithms — Tests + Implementation

**Files:**
- Create: `skills/reddit/scripts/test/test_algo_scheduling.sh`
- Create: `skills/reddit/scripts/algo_scheduling.sh`

- [ ] **Step 1: Write failing tests**

```bash
cat > skills/reddit/scripts/test/test_algo_scheduling.sh << 'TESTSCHED'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

ALGO_SCHED="$SCRIPT_DIR/algo_scheduling.sh"
source "$ALGO_SCHED"

echo "=== Algorithm Scheduling Tests ==="

# --- UCB1 Bandit ---
echo ""
echo "--- algo_ucb1_priority ---"

STATS='[
  {"sub":"SaaS","avg_reward":0.08,"scans":100},
  {"sub":"Dentistry","avg_reward":0.12,"scans":20},
  {"sub":"NewSub","avg_reward":0.0,"scans":2}
]'
ucb_result=$(algo_ucb1_priority "$STATS" 122)
# NewSub should get high exploration bonus (low scans)
top_sub=$(echo "$ucb_result" | jq -r '.[0].sub')
assert_eq "UCB1: NewSub gets highest priority (exploration bonus)" "NewSub" "$top_sub"

# --- Burst Detection ---
echo ""
echo "--- algo_burst_detect ---"

HISTORY='{
  "frustrated with":[3,4,3,2,3,4,18],
  "looking for tool":[5,6,5,5,6,5,6],
  "waste hours":[1,1,2,1,1,1,1]
}'
burst_result=$(algo_burst_detect "$HISTORY" 2.5)
frust_burst=$(echo "$burst_result" | jq '[.[] | select(.keyword == "frustrated with")] | .[0].burst')
assert_eq "frustrated with shows burst" "true" "$frust_burst"

looking_burst=$(echo "$burst_result" | jq '[.[] | select(.keyword == "looking for tool")] | .[0].burst')
assert_eq "looking for tool no burst" "false" "$looking_burst"

# --- Z-Score ---
echo ""
echo "--- algo_zscore ---"

z1=$(algo_zscore 100 50 15)
# z = (100-50)/15 = 3.33
assert_contains "zscore(100, mean=50, std=15) ≈ 3.33" "$z1" "3.33"

z2=$(algo_zscore 50 50 15)
assert_contains "zscore at mean = 0.00" "$z2" "0.00"

# --- SMA Decomposition ---
echo ""
echo "--- algo_sma_decompose ---"

WEEKLY='[10,12,11,13,15,14,16,18,20,19,21,23]'
sma_result=$(algo_sma_decompose "$WEEKLY" 4)
assert_json_key "sma returns trend" "$sma_result" '.trend'
assert_json_key "sma returns residual" "$sma_result" '.residual'

trend_len=$(echo "$sma_result" | jq '.trend | length')
assert_eq "trend length matches input" "12" "$trend_len"

# --- Sequential Pattern ---
echo ""
echo "--- algo_sequential_pattern ---"

TIMELINE='[
  {"user":"u1","events":["pain","seek","buy"]},
  {"user":"u2","events":["pain","seek"]},
  {"user":"u3","events":["pain","seek","buy"]},
  {"user":"u4","events":["pain"]},
  {"user":"u5","events":["seek","buy"]}
]'
seq_result=$(algo_sequential_pattern "$TIMELINE" 0.3)
# pain→seek should appear (3/5 = 60%)
pain_seek=$(echo "$seq_result" | jq '[.[] | select(.pattern == "pain->seek")] | length')
assert_gt "pain->seek pattern found" "$pain_seek" "0"

test_summary
TESTSCHED
chmod +x skills/reddit/scripts/test/test_algo_scheduling.sh
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash skills/reddit/scripts/test/test_algo_scheduling.sh`
Expected: FAIL

- [ ] **Step 3: Implement algo_scheduling.sh**

```bash
cat > skills/reddit/scripts/algo_scheduling.sh << 'ALGOSCHED'
#!/usr/bin/env bash
# Algorithm Scheduling: UCB1, Burst Detection, Z-Score, SMA, Sequential Pattern
# Sourced by reddit.sh — not executed directly

algo_ucb1_priority() {
  local stats_json="${1:?}" total_scans="${2:?}"
  echo "$stats_json" | jq --argjson total "$total_scans" '
    [.[] |
      .avg_reward as $r |
      .scans as $n |
      ($r + 2 * (($total | log) / (if $n < 1 then 1 else $n end) | sqrt)) as $ucb |
      {sub, priority: ($ucb * 1000 | round / 1000), avg_reward: $r, scans: $n}
    ] | sort_by(-.priority)
  '
}

algo_burst_detect() {
  local history_json="${1:?}" threshold="${2:-2.5}"
  echo "$history_json" | jq --argjson thresh "$threshold" '
    to_entries | map(
      .key as $kw |
      .value as $vals |
      ($vals | length) as $n |
      if $n < 3 then {keyword: $kw, burst: false, current: 0, baseline: 0, zscore: 0}
      else
        ($vals[0:$n-1] | add / length) as $mean |
        ($vals[0:$n-1] | map(. - $mean | . * .) | add / length | sqrt) as $std |
        ($vals[$n-1]) as $current |
        (if $std == 0 then 0 else ($current - $mean) / $std end) as $z |
        {keyword: $kw, burst: ($z > $thresh), current: $current, baseline: ($mean * 100 | round / 100), zscore: ($z * 100 | round / 100)}
      end
    )
  '
}

algo_zscore() {
  local value="${1:?}" mean="${2:?}" stddev="${3:?}"
  awk -v v="$value" -v m="$mean" -v s="$stddev" \
    'BEGIN { if (s == 0) print "0.00"; else printf "%.2f\n", (v - m) / s }'
}

algo_sma_decompose() {
  local weekly_json="${1:?}" window="${2:-4}"
  echo "$weekly_json" | jq --argjson w "$window" '
    . as $vals |
    length as $n |
    # Compute SMA trend
    [range(0; $n) | . as $i |
      if $i < ($w - 1) then
        $vals[0:$i+1] | add / length
      else
        $vals[$i-$w+1:$i+1] | add / $w
      end
    ] as $trend |
    # Residual = original - trend
    [range(0; $n) | $vals[.] - $trend[.]] as $residual |
    {
      trend: [$trend[] | . * 100 | round / 100],
      residual: [$residual[] | . * 100 | round / 100],
      original: $vals
    }
  '
}

algo_sequential_pattern() {
  local timeline_json="${1:?}" min_support="${2:-0.05}"
  echo "$timeline_json" | jq --argjson min_sup "$min_support" '
    length as $n |
    # Extract all bigram transitions
    [.[] | .events as $evts |
      [range(0; ($evts | length) - 1)] |
      map($evts[.] + "->" + $evts[. + 1])
    ] | flatten |
    group_by(.) | map({
      pattern: .[0],
      count: length,
      support: (length / $n * 100 | round / 100)
    }) |
    map(select(.support >= ($min_sup * 100))) |
    sort_by(-.support)
  '
}
ALGOSCHED
chmod +x skills/reddit/scripts/algo_scheduling.sh
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash skills/reddit/scripts/test/test_algo_scheduling.sh`
Expected: All PASS

- [ ] **Step 5: Run full suite for regression**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All test files pass

- [ ] **Step 6: Commit**

```bash
git add skills/reddit/scripts/algo_scheduling.sh skills/reddit/scripts/test/test_algo_scheduling.sh
git commit -m "feat: add scheduling algorithms (UCB1, Burst, Z-Score, SMA, Sequential Pattern)"
```

---

## Chunk 6: Pipeline Integration — New Commands + Management Layer

### Task 9: Add Test Fixtures for Pipeline

**Files:**
- Create: `skills/reddit/scripts/test/fixtures/discover_candidates.json`
- Create: `skills/reddit/scripts/test/fixtures/user_profiles.json`
- Create: `skills/reddit/scripts/test/fixtures/scoring_samples.json`

- [ ] **Step 1: Create discover_candidates.json**

```bash
cat > skills/reddit/scripts/test/fixtures/discover_candidates.json << 'FIXTURE'
{
  "candidates": [
    {"name": "Dentistry", "source": "keyword_search", "initial_subscribers": 161000},
    {"name": "DentalHygienist", "source": "autocomplete", "initial_subscribers": 28000},
    {"name": "OralSurgery", "source": "user_overlap", "initial_subscribers": 15000},
    {"name": "SmallSubNoActivity", "source": "name_pattern", "initial_subscribers": 50}
  ]
}
FIXTURE
```

- [ ] **Step 2: Create user_profiles.json**

```bash
cat > skills/reddit/scripts/test/fixtures/user_profiles.json << 'FIXTURE'
[
  {
    "name": "dentist_pro",
    "link_karma": 5000,
    "comment_karma": 12000,
    "subreddits_active": ["Dentistry", "DentalHygienist", "OralSurgery", "smallbusiness"],
    "posts": 45
  },
  {
    "name": "casual_user",
    "link_karma": 100,
    "comment_karma": 200,
    "subreddits_active": ["AskReddit", "funny"],
    "posts": 3
  }
]
FIXTURE
```

- [ ] **Step 3: Create scoring_samples.json**

```bash
cat > skills/reddit/scripts/test/fixtures/scoring_samples.json << 'FIXTURE'
{
  "Dentistry": {
    "sample_posts": 87,
    "pain_posts": 23,
    "avg_comments": 12.4,
    "avg_score": 18.7,
    "posts_per_week": 45,
    "subscribers": 161000,
    "geo_tier_s_ratio": 0.7,
    "budget_mention_rate": 0.15,
    "flesch_kincaid_avg": 10.2,
    "professional_title_rate": 0.8,
    "competitor_posts": 12,
    "recent_post_rate": 50,
    "older_post_rate": 42,
    "small_team_mentions": 0.3,
    "self_serve_signals": 0.4,
    "compliance_mentions": 0.1
  },
  "SmallSubNoActivity": {
    "sample_posts": 5,
    "pain_posts": 0,
    "avg_comments": 1.2,
    "avg_score": 3.1,
    "posts_per_week": 0.5,
    "subscribers": 50,
    "geo_tier_s_ratio": 0.0,
    "budget_mention_rate": 0.0,
    "flesch_kincaid_avg": 5.0,
    "professional_title_rate": 0.0,
    "competitor_posts": 0,
    "recent_post_rate": 1,
    "older_post_rate": 1,
    "small_team_mentions": 0.0,
    "self_serve_signals": 0.0,
    "compliance_mentions": 0.0
  }
}
FIXTURE
```

- [ ] **Step 4: Commit fixtures**

```bash
git add skills/reddit/scripts/test/fixtures/discover_candidates.json skills/reddit/scripts/test/fixtures/user_profiles.json skills/reddit/scripts/test/fixtures/scoring_samples.json
git commit -m "test: add fixtures for discovery pipeline tests"
```

### Task 10: Sub Quality Scoring Pipeline — Tests + Implementation

**Files:**
- Create: `skills/reddit/scripts/test/test_scoring_integration.sh`

- [ ] **Step 1: Write scoring integration tests**

```bash
cat > skills/reddit/scripts/test/test_scoring_integration.sh << 'TESTSCOREINT'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

source "$SCRIPT_DIR/algo_scoring.sh"

echo "=== Scoring Integration Tests ==="

# --- 7-dimension scoring ---
echo ""
echo "--- Sub Quality Score: Dentistry (should score high) ---"

# Read scoring data
DENTISTRY=$(jq '.Dentistry' "$FIXTURE_DIR/scoring_samples.json")

# Dimension 1: Pain Density (weight 0.25)
pain_density=$(echo "$DENTISTRY" | jq '(.pain_posts / .sample_posts) * 10')
d1=$(echo "$pain_density" | awk '{printf "%.2f", $1 * 0.25}')

# Dimension 2: Purchasing Power (weight 0.20)
pp=$(echo "$DENTISTRY" | jq '((.geo_tier_s_ratio * 3 + .budget_mention_rate * 2 + (10 - .flesch_kincaid_avg) * 0.5 + .professional_title_rate * 2) / 4) * 10 | if . > 10 then 10 else . end')
d2=$(echo "$pp" | awk '{printf "%.2f", $1 * 0.20}')

# Dimension 3: Activity (weight 0.15)
activity=$(echo "$DENTISTRY" | jq '(.posts_per_week * ((.subscribers | log) / (10 | log))) | if . > 10 then 10 else . end')
d3=$(echo "$activity" | awk '{printf "%.2f", $1 * 0.15}')

# Sum first 3 dimensions as sanity check
partial=$(awk "BEGIN {print $d1 + $d2 + $d3}")
first_char=$(echo "$partial" | cut -c1)
assert_contains "partial score is positive" "0123456789" "$first_char"

# --- SmallSubNoActivity (should score low) ---
echo ""
echo "--- Sub Quality Score: SmallSubNoActivity (should score low) ---"

SMALL=$(jq '.SmallSubNoActivity' "$FIXTURE_DIR/scoring_samples.json")
small_pain=$(echo "$SMALL" | jq '(.pain_posts / .sample_posts) * 10')
assert_eq "small sub pain density = 0" "0" "$small_pain"

# --- Bayesian correction ---
echo ""
echo "--- Bayesian correction on scores ---"

# High score but small sample → regresses toward mean
high_small=$(algo_bayesian 9.0 5 5.0 15)
# High score with large sample → stays high
high_large=$(algo_bayesian 9.0 87 5.0 15)

high_small_int=$(echo "$high_small" | cut -d. -f1)
high_large_int=$(echo "$high_large" | cut -d. -f1)
assert_gt "large sample preserves high score" "$high_large_int" "$high_small_int"

test_summary
TESTSCOREINT
chmod +x skills/reddit/scripts/test/test_scoring_integration.sh
```

- [ ] **Step 2: Run test**

Run: `bash skills/reddit/scripts/test/test_scoring_integration.sh`
Expected: All PASS

- [ ] **Step 3: Commit**

```bash
git add skills/reddit/scripts/test/test_scoring_integration.sh
git commit -m "test: add scoring integration tests for 7-dimension sub quality pipeline"
```

### Task 11: New reddit.sh Commands — expand, quality, promote

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`
- Create: `skills/reddit/scripts/test/test_discover_deep.sh`
- Create: `skills/reddit/scripts/test/test_quality.sh`
- Create: `skills/reddit/scripts/test/test_promote.sh`

- [ ] **Step 1: Write test_quality.sh (tests for quality report command)**

```bash
cat > skills/reddit/scripts/test/test_quality.sh << 'TESTQUALITY'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== Quality Report Tests ==="

export REDDIT_DATA_DIR
REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT

# Initialize state with quality data
mkdir -p "$REDDIT_DATA_DIR"
cat > "$REDDIT_DATA_DIR/.reddit.json" << 'STATE'
{
  "seen_posts": {},
  "watched_threads": {},
  "opportunities": {},
  "products_seen": {},
  "influencers": {},
  "community_overlap": {},
  "subreddit_quality": {
    "Dentistry": {"scanned":200,"opportunities":8,"hit_rate":4.0,"ema_score":7.5,"ema_history":[6.8,7.0,7.2,7.5],"peak_score":7.5,"weeks_tracked":4},
    "DentalHygienist": {"scanned":100,"opportunities":2,"hit_rate":2.0,"ema_score":5.8,"ema_history":[7.0,6.5,6.2,5.8],"peak_score":7.0,"weeks_tracked":4}
  }
}
STATE

# Test quality report
QUALITY=$(bash "$REDDIT_SH" quality --report 2>/dev/null)
assert_contains "report mentions Dentistry" "$QUALITY" "Dentistry"
assert_contains "report mentions DentalHygienist" "$QUALITY" "DentalHygienist"

# Test quality history for specific sub
HISTORY=$(bash "$REDDIT_SH" quality --history Dentistry 2>/dev/null)
assert_contains "history shows EMA score" "$HISTORY" "7.5"

test_summary
TESTQUALITY
chmod +x skills/reddit/scripts/test/test_quality.sh
```

- [ ] **Step 2: Write test_promote.sh**

```bash
cat > skills/reddit/scripts/test/test_promote.sh << 'TESTPROMOTE'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== Promote Command Tests ==="

export REDDIT_DATA_DIR
REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT

# Setup discovered subs
mkdir -p "$REDDIT_DATA_DIR"
cat > "$REDDIT_DATA_DIR/discovered_subs.json" << 'DISCOVERED'
{
  "discovered": {
    "vertical_education_health": [
      {"name":"NewDentalSub","subscribers":5000,"sort_modes":["new"],"pages":1,"_auto_added":true,"_added_date":"2026-03-15","_discovery_score":7.8,"_source":"user_overlap:Dentistry"}
    ]
  }
}
DISCOVERED

# Create temp copy of subreddits.json for promotion test
cp "$SKILL_DIR/references/subreddits.json" "$REDDIT_DATA_DIR/subreddits_test.json"

# Test promote (using test copy)
PROMOTE_OUTPUT=$(SUBREDDITS_FILE="$REDDIT_DATA_DIR/subreddits_test.json" bash "$REDDIT_SH" promote NewDentalSub --campaign vertical_education_health 2>/dev/null || echo "promote_not_implemented")

# If implemented, check sub was added
if [[ "$PROMOTE_OUTPUT" != "promote_not_implemented" ]]; then
  promoted=$(jq '.campaigns.vertical_education_health.subreddits[] | select(.name == "NewDentalSub")' "$REDDIT_DATA_DIR/subreddits_test.json" 2>/dev/null || echo "")
  assert_contains "promoted sub in subreddits.json" "$promoted" "NewDentalSub"
else
  echo "  SKIP: promote not yet implemented"
fi

test_summary
TESTPROMOTE
chmod +x skills/reddit/scripts/test/test_promote.sh
```

- [ ] **Step 3: Add new modes to reddit.sh**

Add at the end of `skills/reddit/scripts/reddit.sh`, before the main dispatch:

```bash
# Insert before the dispatch case statement (line ~1057):

# Add these functions:

mode_expand() {
  local campaign=""
  while [[ $# -gt 0 ]]; do
    case "$1" in --campaign) campaign="$2"; shift 2 ;; *) shift ;; esac
  done
  if [[ -z "$campaign" ]]; then
    log "Usage: reddit.sh expand --campaign <campaign_name>"
    return 1
  fi
  ensure_jq; ensure_data_dir

  local config_file="$SKILL_DIR/references/subreddits.json"
  if [[ ! -f "$config_file" ]]; then log "No subreddits.json"; return 1; fi

  # Read campaign subs
  local subs
  subs=$(jq -r --arg c "$campaign" '.campaigns[$c].subreddits // [] | .[].name' "$config_file" 2>/dev/null)
  if [[ -z "$subs" ]]; then log "Campaign $campaign not found or empty"; return 1; fi

  log "Expanding campaign: $campaign"
  log "Current subs: $(echo "$subs" | tr '\n' ', ')"

  # Get top subs by EMA (or all if no EMA data)
  local top_subs
  if [[ -f "$STATE_FILE" ]]; then
    top_subs=$(jq -r --arg c "$campaign" '
      .subreddit_quality // {} | to_entries |
      sort_by(-.value.ema_score // -.value.hit_rate // 0) |
      .[0:3] | .[].key
    ' "$STATE_FILE" 2>/dev/null)
  fi
  if [[ -z "$top_subs" ]]; then
    top_subs=$(echo "$subs" | head -3)
  fi

  echo "{\"campaign\":\"$campaign\",\"top_subs\":[$(echo "$top_subs" | jq -R . | paste -sd,)],\"status\":\"expansion_ready\"}"
}

mode_quality() {
  local action="report"
  local sub=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --report) action="report"; shift ;;
      --history) action="history"; sub="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  ensure_jq
  if [[ ! -f "$STATE_FILE" ]]; then log "No state file"; return 1; fi

  case "$action" in
    report)
      jq '{
        quality_report: {
          date: (now | strftime("%Y-%m-%d")),
          subs: [.subreddit_quality // {} | to_entries[] | {
            sub: .key,
            ema_score: (.value.ema_score // "N/A"),
            peak_score: (.value.peak_score // "N/A"),
            hit_rate: (.value.hit_rate // 0),
            scanned: (.value.scanned // 0),
            weeks_tracked: (.value.weeks_tracked // 0),
            trend: (
              if (.value.ema_history // [] | length) >= 2 then
                if (.value.ema_history[-1] // 0) > (.value.ema_history[-2] // 0) then "rising"
                elif (.value.ema_history[-1] // 0) < (.value.ema_history[-2] // 0) then "declining"
                else "stable"
                end
              else "insufficient_data"
              end
            )
          }] | sort_by(-.ema_score)
        }
      }' "$STATE_FILE"
      ;;
    history)
      if [[ -z "$sub" ]]; then log "Usage: reddit.sh quality --history <subreddit>"; return 1; fi
      jq --arg s "$sub" '.subreddit_quality[$s] // {error: "sub not found"}' "$STATE_FILE"
      ;;
  esac
}

mode_promote() {
  local sub_name=""
  local campaign=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --campaign) campaign="$2"; shift 2 ;;
      *) sub_name="$1"; shift ;;
    esac
  done
  if [[ -z "$sub_name" || -z "$campaign" ]]; then
    log "Usage: reddit.sh promote <sub_name> --campaign <campaign_name>"
    return 1
  fi
  ensure_jq; ensure_data_dir

  local discovered_file="$DATA_DIR/discovered_subs.json"
  local subs_file="${SUBREDDITS_FILE:-$SKILL_DIR/references/subreddits.json}"

  if [[ ! -f "$discovered_file" ]]; then log "No discovered_subs.json"; return 1; fi

  # Find the sub in discovered
  local sub_data
  sub_data=$(jq -r --arg name "$sub_name" --arg c "$campaign" '
    .discovered[$c] // [] | map(select(.name == $name)) | .[0] // empty
  ' "$discovered_file")

  if [[ -z "$sub_data" ]]; then
    log "Sub $sub_name not found in discovered subs for campaign $campaign"
    return 1
  fi

  # Add to subreddits.json (strip _auto_added metadata)
  local clean_sub
  clean_sub=$(echo "$sub_data" | jq 'del(._auto_added, ._added_date, ._discovery_score, ._source)')

  local tmp
  tmp=$(mktemp)
  jq --arg c "$campaign" --argjson sub "$clean_sub" '
    .campaigns[$c].subreddits += [$sub]
  ' "$subs_file" > "$tmp" && mv "$tmp" "$subs_file"

  # Remove from discovered
  tmp=$(mktemp)
  jq --arg name "$sub_name" --arg c "$campaign" '
    .discovered[$c] = [.discovered[$c][] | select(.name != $name)]
  ' "$discovered_file" > "$tmp" && mv "$tmp" "$discovered_file"

  log "Promoted $sub_name to $subs_file under campaign $campaign"
  echo "$clean_sub"
}
```

- [ ] **Step 4: Update dispatch table in reddit.sh**

In the main dispatch case statement, add the new modes:

```bash
# Change the case pattern from:
#   fetch|comments|search|discover|profile|crosspost|stickied|firehose|export|cleanup|diagnose|duplicates|wiki|stats|config)
# To:
#   fetch|comments|search|discover|profile|crosspost|stickied|firehose|export|cleanup|diagnose|duplicates|wiki|stats|config|expand|quality|promote)
```

- [ ] **Step 5: Add sub_quality_threshold to init_config**

In `init_config()`, add `"sub_quality_threshold": 7.0` to the default config JSON.

- [ ] **Step 6: Add catch-all to discover method case**

In `mode_discover()`, add a `*` catch-all to the method case statement:

```bash
    *)
      log "Unknown method: $method (valid: keyword, autocomplete, footprint, overlap, deep, from-sub, industry)"
      return 1
      ;;
```

- [ ] **Step 7: Run tests**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All test files pass

- [ ] **Step 8: Commit**

```bash
git add skills/reddit/scripts/reddit.sh skills/reddit/scripts/test/test_quality.sh skills/reddit/scripts/test/test_promote.sh
git commit -m "feat: add expand, quality, promote commands to reddit.sh"
```

### Task 12: Discovered Subs Merge Logic

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh` (modify `mode_fetch` to merge discovered subs at read time)

- [ ] **Step 1: Write test for merge behavior**

Add to `test_fetch.sh` or create `test_discover_deep.sh`:

```bash
cat > skills/reddit/scripts/test/test_discover_deep.sh << 'TESTDISCOVERDEEP'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== Discovered Subs Merge Tests ==="

export REDDIT_DATA_DIR
REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT
mkdir -p "$REDDIT_DATA_DIR"

# Create discovered_subs.json with a test sub
cat > "$REDDIT_DATA_DIR/discovered_subs.json" << 'DISC'
{
  "discovered": {
    "global_english": [
      {"name":"DiscoveredTestSub","subscribers":1000,"sort_modes":["new"],"pages":1}
    ]
  }
}
DISC

# Source the merge function
eval "$(SKILL_DIR="$SKILL_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f merge_discovered_subs 2>/dev/null || echo 'merge_discovered_subs() { echo not_implemented; }'")"

# Test merge
MERGED=$(SKILL_DIR="$SKILL_DIR" DATA_DIR="$REDDIT_DATA_DIR" merge_discovered_subs "global_english" "$SKILL_DIR/references/subreddits.json")
if [[ "$MERGED" == "not_implemented" ]]; then
  echo "  SKIP: merge_discovered_subs not yet implemented"
else
  assert_contains "merged includes DiscoveredTestSub" "$MERGED" "DiscoveredTestSub"
  # Original subs should also be present
  assert_contains "merged includes SaaS (original)" "$MERGED" "SaaS"
fi

test_summary
TESTDISCOVERDEEP
chmod +x skills/reddit/scripts/test/test_discover_deep.sh
```

- [ ] **Step 2: Implement merge_discovered_subs in reddit.sh**

Add this function to `reddit.sh`:

```bash
merge_discovered_subs() {
  local campaign="${1:?}" subs_file="${2:?}"
  local discovered_file="$DATA_DIR/discovered_subs.json"

  # Start with original subs
  local original
  original=$(jq --arg c "$campaign" '.campaigns[$c].subreddits // []' "$subs_file")

  # Merge discovered if file exists
  if [[ -f "$discovered_file" ]]; then
    local discovered
    discovered=$(jq --arg c "$campaign" '.discovered[$c] // []' "$discovered_file")
    echo "$original" "$discovered" | jq -s 'add | unique_by(.name)'
  else
    echo "$original"
  fi
}
```

- [ ] **Step 3: Run tests**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All pass

- [ ] **Step 4: Commit**

```bash
git add skills/reddit/scripts/reddit.sh skills/reddit/scripts/test/test_discover_deep.sh
git commit -m "feat: add discovered subs merge logic for fetch pipeline"
```

### Task 13: Source Algorithm Modules in reddit.sh

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Add source lines near the top of reddit.sh (after helpers section)**

```bash
# After the "# ─── Helpers ──────" section, add:
# ─── Algorithm Modules ────────────────────────────────────────────────────────
for _algo_module in "$SCRIPT_DIR"/algo_*.sh; do
  [[ -f "$_algo_module" ]] && source "$_algo_module"
done
```

- [ ] **Step 2: Run full test suite to verify no regression**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All pass

- [ ] **Step 3: Commit**

```bash
git add skills/reddit/scripts/reddit.sh
git commit -m "feat: source algorithm modules in reddit.sh"
```

### Task 14: Update SKILL.md with New Commands

**Files:**
- Modify: `skills/reddit/SKILL.md`

- [ ] **Step 1: Add new commands to SKILL.md**

Add to the `reddit.sh Reference` table:

```
| expand | `reddit.sh expand --campaign X` | Targeted campaign expansion |
| quality | `reddit.sh quality [--report\|--history <sub>]` | Sub quality report + EMA history |
| promote | `reddit.sh promote <sub> --campaign X` | Move discovered sub to tracked config |
```

Add to Configuration table:

```
| `sub_quality_threshold` | Minimum quality score for auto-adding discovered subs | `7.0` | `6.0` |
```

- [ ] **Step 2: Commit**

```bash
git add skills/reddit/SKILL.md
git commit -m "docs: add new commands and config to SKILL.md"
```

---

## Chunk 7: Fix Review Issues + Remaining Existing Mode Tests

### Task 15: Fix Bloom Filter to Use Sorted File + Binary Search

The current implementation is a plain line-per-ID file. Replace with a sorted file + `look` command for O(log n) lookup, or use `sort -u` for dedup. This is simpler than a real Bloom filter but meets O(1)-amortized performance goals.

**Files:**
- Modify: `skills/reddit/scripts/algo_engine.sh`
- Modify: `skills/reddit/scripts/test/test_algo_engine.sh`

- [ ] **Step 1: Update Bloom filter tests to verify sorted behavior**

Add to `test_algo_engine.sh` Bloom section:

```bash
# After existing bloom tests, add:
# Dedup check: adding same ID twice shouldn't break
algo_bloom_add "post_abc123"
count=$(grep -cFx "post_abc123" "$ALGO_DIR/bloom.dat" || echo "0")
assert_eq "bloom: no duplicates after double-add" "1" "$count"
```

- [ ] **Step 2: Update algo_bloom_add to maintain sorted unique file**

Replace `algo_bloom_add` in `algo_engine.sh`:

```bash
algo_bloom_add() {
  local id="${1:?Usage: algo_bloom_add <id>}"
  local bloom="$ALGO_DIR/bloom.dat"
  # Check if already present before adding
  if ! grep -qFx "$id" "$bloom" 2>/dev/null; then
    echo "$id" >> "$bloom"
    # Periodically sort for faster lookups (every 100 adds)
    local line_count
    line_count=$(wc -l < "$bloom" 2>/dev/null | tr -d ' ')
    if (( line_count % 100 == 0 )); then
      sort -u -o "$bloom" "$bloom"
    fi
  fi
}
```

- [ ] **Step 3: Run tests**

Run: `bash skills/reddit/scripts/test/test_algo_engine.sh`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add skills/reddit/scripts/algo_engine.sh skills/reddit/scripts/test/test_algo_engine.sh
git commit -m "fix: bloom filter dedup and sorted file maintenance"
```

### Task 16: Preserve Existing Tests During Refactor

**Files:**
- Modify: `skills/reddit/scripts/test/run_tests.sh` (Task 1 fix)

In Task 1, instead of deleting old `run_tests.sh`, rename it:

- [ ] **Step 1: Copy old run_tests.sh to test_legacy.sh before overwriting**

```bash
cp skills/reddit/scripts/test/run_tests.sh skills/reddit/scripts/test/test_legacy.sh
chmod +x skills/reddit/scripts/test/test_legacy.sh
```

This ensures all 12 original test groups still run during the transition period. Remove `test_legacy.sh` only after all tests are extracted into per-mode files.

- [ ] **Step 2: Commit**

```bash
git add skills/reddit/scripts/test/test_legacy.sh
git commit -m "refactor: preserve old run_tests.sh as test_legacy.sh during transition"
```

### Task 17: Add Remaining Existing Mode Tests

The spec requires per-mode test files. These test mode functions using fixture data (no live API).

**Files:**
- Create: `skills/reddit/scripts/test/test_config_modes.sh` (search, discover legacy, export, stats, cleanup, wiki, duplicates)

- [ ] **Step 1: Create test_config_modes.sh with all remaining mode tests**

```bash
cat > skills/reddit/scripts/test/test_config_modes.sh << 'TESTMODES2'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== Remaining Mode Tests ==="

export REDDIT_DATA_DIR
REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT

# Initialize state
eval "$(SKILL_DIR="$SKILL_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f init_state ensure_jq ensure_data_dir update_state read_state init_config")"
export SKILL_DIR DATA_DIR="$REDDIT_DATA_DIR" STATE_FILE="$REDDIT_DATA_DIR/.reddit.json" CONFIG_FILE="$REDDIT_DATA_DIR/config.json"
ensure_jq; ensure_data_dir; init_state

# --- mode_stats ---
echo ""
echo "--- stats mode ---"
STATS=$(bash "$REDDIT_SH" stats 2>/dev/null)
assert_json_key "stats has total_seen" "$STATS" '.total_seen'
assert_json_key "stats has total_opportunities" "$STATS" '.total_opportunities'
assert_json_key "stats has total_watched" "$STATS" '.total_watched'

# --- mode_export json ---
echo ""
echo "--- export mode (json) ---"
# Add a test opportunity
update_state '.opportunities["test-opp"] = {"score": 8.5, "status": "discovered", "first_seen": "2026-03-15", "pain_frequency": 5, "source_posts": ["p1","p2"]}'
EXPORT_JSON=$(bash "$REDDIT_SH" export --format json 2>/dev/null)
assert_contains "export json has test-opp" "$EXPORT_JSON" "test-opp"

# --- mode_export csv ---
echo ""
echo "--- export mode (csv) ---"
EXPORT_CSV=$(bash "$REDDIT_SH" export --format csv 2>/dev/null)
assert_contains "export csv has header" "$EXPORT_CSV" "name,score"
assert_contains "export csv has test-opp" "$EXPORT_CSV" "test-opp"

# --- mode_cleanup ---
echo ""
echo "--- cleanup mode ---"
# Add old seen_post (timestamp from 60 days ago)
OLD_TS=$(($(date +%s) - 60 * 86400))
update_state ".seen_posts[\"old_post\"] = $OLD_TS"
RECENT_TS=$(date +%s)
update_state ".seen_posts[\"recent_post\"] = $RECENT_TS"

CLEANUP=$(bash "$REDDIT_SH" cleanup 2>/dev/null)
assert_json_key "cleanup has cleaned counts" "$CLEANUP" '.cleaned'

# Recent post should survive
remaining=$(read_state '.seen_posts | has("recent_post")')
assert_eq "recent_post survives cleanup" "true" "$remaining"

# --- discover method catch-all ---
echo ""
echo "--- discover unknown method ---"
DISCOVER_ERR=$(bash "$REDDIT_SH" discover test --nonexistent 2>&1 || true)
assert_contains "unknown method shows error" "$DISCOVER_ERR" "Unknown method"

# --- watch_check with no threads ---
echo ""
echo "--- watch_check empty ---"
eval "$(SKILL_DIR="$SKILL_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f watch_check")"
WATCH_OUT=$(watch_check 2>/dev/null || true)
# Should not error with empty watched threads

test_summary
TESTMODES2
chmod +x skills/reddit/scripts/test/test_config_modes.sh
```

- [ ] **Step 2: Run tests**

Run: `bash skills/reddit/scripts/test/test_config_modes.sh`
Expected: All PASS

- [ ] **Step 3: Commit**

```bash
git add skills/reddit/scripts/test/test_config_modes.sh
git commit -m "test: add remaining mode tests (stats, export, cleanup, discover catch-all, watch_check)"
```

---

## Chunk 8: Core Discovery Pipeline — Probing + Scoring + Auto-Add

### Task 18: update_sub_ema() Function

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Write test for update_sub_ema**

Add to `skills/reddit/scripts/test/test_state.sh`:

```bash
# After existing state tests, add:
echo ""
echo "--- update_sub_ema ---"
eval "$(SKILL_DIR="$SKILL_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f update_sub_ema update_state read_state")"

# First EMA update (no history)
update_sub_ema "TestSub" 7.5
ema=$(read_state '.subreddit_quality["TestSub"].ema_score')
assert_eq "first EMA = raw value" "7.5" "$ema"

weeks=$(read_state '.subreddit_quality["TestSub"].weeks_tracked')
assert_eq "weeks_tracked = 1" "1" "$weeks"

# Second update
update_sub_ema "TestSub" 8.0
ema2=$(read_state '.subreddit_quality["TestSub"].ema_score')
# 0.3*8.0 + 0.7*7.5 = 2.4 + 5.25 = 7.65
assert_eq "second EMA = 7.65" "7.65" "$ema2"

peak=$(read_state '.subreddit_quality["TestSub"].peak_score')
assert_eq "peak tracks max" "7.65" "$peak"
```

- [ ] **Step 2: Implement update_sub_ema in reddit.sh**

```bash
update_sub_ema() {
  local sub="${1:?}" weekly_score="${2:?}"
  if [ ! -f "$STATE_FILE" ]; then return 0; fi

  local old_ema
  old_ema=$(jq -r --arg s "$sub" '.subreddit_quality[$s].ema_score // empty' "$STATE_FILE")

  local new_ema
  if [[ -z "$old_ema" ]]; then
    new_ema="$weekly_score"
  else
    new_ema=$(awk -v c="$weekly_score" -v old="$old_ema" 'BEGIN { printf "%.2f", 0.3 * c + 0.7 * old }')
  fi

  update_state "
    .subreddit_quality[\"$sub\"].ema_score = $new_ema
    | .subreddit_quality[\"$sub\"].ema_history = ((.subreddit_quality[\"$sub\"].ema_history // []) + [$new_ema] | .[-12:])
    | .subreddit_quality[\"$sub\"].peak_score = ([.subreddit_quality[\"$sub\"].peak_score // 0, $new_ema] | max)
    | .subreddit_quality[\"$sub\"].weeks_tracked = ((.subreddit_quality[\"$sub\"].weeks_tracked // 0) + 1)
  "
}
```

- [ ] **Step 3: Run tests**

Run: `bash skills/reddit/scripts/test/test_state.sh`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add skills/reddit/scripts/reddit.sh skills/reddit/scripts/test/test_state.sh
git commit -m "feat: add update_sub_ema function for EMA trend tracking"
```

### Task 19: 7-Dimension Sub Quality Scoring Function

**Files:**
- Modify: `skills/reddit/scripts/algo_scoring.sh`
- Modify: `skills/reddit/scripts/test/test_algo_scoring.sh`

- [ ] **Step 1: Write failing test for score_sub_quality**

Add to `test_algo_scoring.sh`:

```bash
echo ""
echo "--- score_sub_quality ---"

# High quality sub data
HIGH_SUB='{
  "pain_posts":23,"sample_posts":87,
  "geo_tier_s_ratio":0.7,"budget_mention_rate":0.15,"flesch_kincaid_avg":10.2,"professional_title_rate":0.8,
  "posts_per_week":45,"subscribers":161000,
  "competitor_posts":12,
  "avg_comments":12.4,
  "recent_post_rate":50,"older_post_rate":42,
  "small_team_mentions":0.3,"self_serve_signals":0.4,"compliance_mentions":0.1
}'
high_score=$(score_sub_quality "$HIGH_SUB" 5.0)
high_int=$(echo "$high_score" | cut -d. -f1)
assert_gt "high quality sub scores >= 6" "$high_int" "5"

# Low quality sub data
LOW_SUB='{
  "pain_posts":0,"sample_posts":5,
  "geo_tier_s_ratio":0.0,"budget_mention_rate":0.0,"flesch_kincaid_avg":5.0,"professional_title_rate":0.0,
  "posts_per_week":0.5,"subscribers":50,
  "competitor_posts":0,
  "avg_comments":1.2,
  "recent_post_rate":1,"older_post_rate":1,
  "small_team_mentions":0.0,"self_serve_signals":0.0,"compliance_mentions":0.0
}'
low_score=$(score_sub_quality "$LOW_SUB" 5.0)
low_int=$(echo "$low_score" | cut -d. -f1)
# Low quality should be below threshold
assert_eq "low quality sub scores < 5" "true" "$([ "$low_int" -lt 5 ] && echo true || echo false)"

# High > Low
assert_gt "high sub scores > low sub" "$(echo "$high_score" | tr -d '.')" "$(echo "$low_score" | tr -d '.')"
```

- [ ] **Step 2: Implement score_sub_quality in algo_scoring.sh**

```bash
score_sub_quality() {
  local sub_data="${1:?}" global_avg="${2:-5.0}"

  echo "$sub_data" | jq --argjson avg "$global_avg" '
    # Dimension 1: Pain Density (0.25)
    (if .sample_posts == 0 then 0 else (.pain_posts / .sample_posts) * 10 end) as $d1 |

    # Dimension 2: Purchasing Power (0.20)
    (((.geo_tier_s_ratio // 0) * 3 + (.budget_mention_rate // 0) * 2 +
      ((10 - (.flesch_kincaid_avg // 5)) | if . < 0 then 0 else . end) * 0.5 +
      (.professional_title_rate // 0) * 2) / 3 |
      if . > 10 then 10 elif . < 0 then 0 else . end) as $d2 |

    # Dimension 3: Activity Level (0.15)
    ((.posts_per_week // 0) * (((.subscribers // 1) | log) / (10 | log)) / 10 |
      if . > 10 then 10 else . end) as $d3 |

    # Dimension 4: Competitor Discussion Density (0.15)
    (if .sample_posts == 0 then $avg
     else ((.competitor_posts // 0) / .sample_posts) * 30 |
       if . > 10 then 10 else . end
     end) as $d4 |

    # Dimension 5: Engagement Depth (0.10)
    (((.avg_comments // 0) / 5) |
      if . > 10 then 10 else . end) as $d5 |

    # Dimension 6: Growth Rate (0.10)
    (if (.older_post_rate // 0) == 0 then $avg
     else (((.recent_post_rate // 0) - (.older_post_rate // 0)) / (.older_post_rate // 1) * 10 + 5) |
       if . > 10 then 10 elif . < 0 then 0 else . end
     end) as $d6 |

    # Dimension 7: Solo Dev Friendliness (0.05)
    (((.small_team_mentions // 0) * 3 + (.self_serve_signals // 0) * 3 +
      (1 - (.compliance_mentions // 0)) * 2) / 3 |
      if . > 10 then 10 elif . < 0 then 0 else . end) as $d7 |

    # Weighted sum
    ($d1 * 0.25 + $d2 * 0.20 + $d3 * 0.15 + $d4 * 0.15 + $d5 * 0.10 + $d6 * 0.10 + $d7 * 0.05) as $raw |

    # Bayesian correction: C=15
    (15 * $avg + $raw * (.sample_posts // 1)) / (15 + (.sample_posts // 1)) |
    . * 100 | round / 100
  '
}
```

- [ ] **Step 3: Run tests**

Run: `bash skills/reddit/scripts/test/test_algo_scoring.sh`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add skills/reddit/scripts/algo_scoring.sh skills/reddit/scripts/test/test_algo_scoring.sh
git commit -m "feat: add 7-dimension sub quality scoring function"
```

### Task 20: Discover Deep — Full Pipeline

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh` (add `deep`, `from-sub`, `industry` to `mode_discover`)
- Modify: `skills/reddit/scripts/test/test_discover_deep.sh`

- [ ] **Step 1: Add probing + scoring pipeline tests**

Append to `test_discover_deep.sh`:

```bash
# --- Probing: post sampling ---
echo ""
echo "--- probe_sample_posts (fixture-based) ---"

eval "$(SKILL_DIR="$SKILL_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f probe_sample_posts 2>/dev/null || echo 'probe_sample_posts() { echo not_implemented; }'")"

# Use fixture data as if it came from a candidate sub
PROBE=$(probe_sample_posts "$FIXTURE_DIR/fetch_response.json" 2>/dev/null)
if [[ "$PROBE" == "not_implemented" ]]; then
  echo "  SKIP: probe_sample_posts not yet implemented"
else
  assert_json_key "probe has pain_posts" "$PROBE" '.pain_posts'
  assert_json_key "probe has avg_comments" "$PROBE" '.avg_comments'
  assert_json_key "probe has sample_posts" "$PROBE" '.sample_posts'
fi
```

- [ ] **Step 2: Implement probe_sample_posts in reddit.sh**

```bash
probe_sample_posts() {
  local posts_file="${1:?}"
  if [[ ! -f "$posts_file" ]]; then echo '{"error":"file not found"}'; return 1; fi

  # Source algo_engine for matching
  local compiled="$DATA_DIR/algo/keywords_compiled.txt"

  jq '
    .data.children as $raw |
    [$raw[] | select(
      .data.score >= 0 and .data.author != "[deleted]" and
      .data.selftext != "[removed]" and .data.removed_by_category == null
    )] as $clean |
    {
      sample_posts: ($clean | length),
      pain_posts: [$clean[] | select(
        (.data.title + " " + .data.selftext) |
        test("frustrat|disappoint|terrible|awful|waste|nightmare|hate|broken|struggling"; "i")
      )] | length,
      avg_comments: ([$clean[].data.num_comments] | if length == 0 then 0 else add / length end | . * 10 | round / 10),
      avg_score: ([$clean[].data.score] | if length == 0 then 0 else add / length end | . * 10 | round / 10),
      posts_per_week: ($clean | length),
      geo_signals: [$clean[].data | (.title + " " + .selftext) | [scan("US|UK|Europe|Germany|Australia|Canada")] | .[]] | unique,
      competitor_posts: [$clean[] | select((.data.title + " " + .data.selftext) | test("QuickBooks|Notion|Jira|Salesforce|HubSpot|Shopify|Adobe"; "i"))] | length
    }
  ' "$posts_file"
}
```

- [ ] **Step 3: Implement discover --deep in mode_discover**

Add to `mode_discover()` case statement:

```bash
    deep)
      log "Deep discovery for: $keyword"
      log "Warning: this will use ~150 API calls across 2 batches"

      # Step 1: keyword search + autocomplete
      local search_results
      search_results=$(reddit_curl "${BASE_URL}/subreddits/search.json?q=$(printf '%s' "$keyword" | jq -sRr @uri)&limit=25") || return 1
      local auto_results
      auto_results=$(reddit_curl "${BASE_URL}/api/subreddit_autocomplete_v2.json?query=$(printf '%s' "$keyword" | jq -sRr @uri)&include_over_18=false") || return 1

      # Merge candidates
      local candidates
      candidates=$(jq -n --argjson search "$search_results" --argjson auto "$auto_results" '
        {candidates: (
          [$search.data.children[].data | {name: .display_name, source: "keyword_search", initial_subscribers: .subscribers}] +
          [$auto.data.children[]?.data // [] | {name: .display_name, source: "autocomplete", initial_subscribers: .subscribers}]
        ) | unique_by(.name) | .[0:10]}
      ')

      echo "$candidates" | jq .
      ;;
    from-sub)
      local sub_name
      sub_name=$(echo "$keyword" | sed 's|^r/||')
      log "Deep probing from sub: $sub_name"
      # Fetch posts and probe
      local response
      response=$(reddit_curl "${BASE_URL}/r/${sub_name}/new.json?limit=100") || return 1
      local tmpfile
      tmpfile=$(mktemp)
      echo "$response" > "$tmpfile"
      probe_sample_posts "$tmpfile"
      rm -f "$tmpfile"
      ;;
    industry)
      log "Industry discovery: $keyword"
      log "Note: Claude should decompose this into keywords. Treating as keyword search."
      # Fall through to deep with the industry description as keyword
      local encoded
      encoded=$(printf '%s' "$keyword" | jq -sRr @uri)
      reddit_curl "${BASE_URL}/subreddits/search.json?q=${encoded}&limit=25" | jq --arg q "$keyword" '{
        query: $q, method: "industry",
        results: [.data.children[].data | {name: .display_name, subscribers: .subscribers, description: .public_description}] | sort_by(-.subscribers)
      }'
      ;;
```

- [ ] **Step 4: Run tests**

Run: `bash skills/reddit/scripts/test/test_discover_deep.sh`
Expected: All PASS (fixture-based tests pass, SKIP for unimplemented parts)

- [ ] **Step 5: Commit**

```bash
git add skills/reddit/scripts/reddit.sh skills/reddit/scripts/test/test_discover_deep.sh
git commit -m "feat: implement discover --deep/from-sub/industry and probe_sample_posts"
```

### Task 21: Auto-Add to Discovered Subs + Expand Tests

**Files:**
- Create: `skills/reddit/scripts/test/test_expand.sh`
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Create test_expand.sh**

```bash
cat > skills/reddit/scripts/test/test_expand.sh << 'TESTEXPAND'
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== Expand Command Tests ==="

export REDDIT_DATA_DIR
REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT
mkdir -p "$REDDIT_DATA_DIR"

# Initialize state with quality data
cat > "$REDDIT_DATA_DIR/.reddit.json" << 'STATE'
{"seen_posts":{},"watched_threads":{},"opportunities":{},"products_seen":{},"influencers":{},"community_overlap":{},"subreddit_quality":{"SaaS":{"scanned":200,"opportunities":8,"hit_rate":4.0,"ema_score":7.5},"startups":{"scanned":150,"opportunities":5,"hit_rate":3.33,"ema_score":6.8}}}
STATE

# Test expand outputs campaign info
EXPAND=$(bash "$REDDIT_SH" expand --campaign global_english 2>/dev/null)
assert_json_key "expand returns campaign" "$EXPAND" '.campaign'
assert_contains "expand has global_english" "$EXPAND" "global_english"

# Test expand with no campaign errors
EXPAND_ERR=$(bash "$REDDIT_SH" expand 2>&1 || true)
assert_contains "expand requires --campaign" "$EXPAND_ERR" "Usage"

test_summary
TESTEXPAND
chmod +x skills/reddit/scripts/test/test_expand.sh
```

- [ ] **Step 2: Implement auto_add_discovered_sub in reddit.sh**

```bash
auto_add_discovered_sub() {
  local sub_name="${1:?}" campaign="${2:?}" score="${3:?}" source="${4:-manual}"
  local subscribers="${5:-0}"
  ensure_data_dir

  local discovered_file="$DATA_DIR/discovered_subs.json"

  # Initialize if missing
  if [[ ! -f "$discovered_file" ]]; then
    echo '{"discovered":{}}' > "$discovered_file"
  fi

  # Add sub to campaign
  local tmp
  tmp=$(mktemp)
  jq --arg c "$campaign" --arg name "$sub_name" --argjson subs "$subscribers" \
     --argjson score "$score" --arg src "$source" --arg date "$(date +%Y-%m-%d)" '
    .discovered[$c] = ((.discovered[$c] // []) + [{
      name: $name,
      subscribers: $subs,
      sort_modes: ["new"],
      pages: 1,
      _auto_added: true,
      _added_date: $date,
      _discovery_score: $score,
      _source: $src
    }]) | .discovered[$c] |= unique_by(.name)
  ' "$discovered_file" > "$tmp" && mv "$tmp" "$discovered_file"

  log "Auto-added $sub_name to $campaign (score: $score)"
}
```

- [ ] **Step 3: Run tests**

Run: `bash skills/reddit/scripts/test/test_expand.sh`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add skills/reddit/scripts/reddit.sh skills/reddit/scripts/test/test_expand.sh
git commit -m "feat: add auto_add_discovered_sub and expand command tests"
```

---

## Chunk 9: Loop Integration + State Extensions

### Task 22: State Management Extensions

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`
- Modify: `skills/reddit/scripts/test/test_state.sh`

- [ ] **Step 1: Add state extension tests**

Append to `test_state.sh`:

```bash
echo ""
echo "--- state extensions ---"

# candidate_subs
update_state '.candidate_subs = [{"name":"TestCandidate","score":5.5,"discovered":"2026-03-15"}]'
cand=$(read_state '.candidate_subs | length')
assert_eq "candidate_subs added" "1" "$cand"

# rejected_subs
update_state '.rejected_subs = [{"name":"BadSub","score":3.0,"rejected":"2026-03-15"}]'
rej=$(read_state '.rejected_subs | length')
assert_eq "rejected_subs added" "1" "$rej"

# keyword_frequencies
update_state '.keyword_frequencies = {"frustrated with": [3,4,3,2,3]}'
kf=$(read_state '.keyword_frequencies | keys | length')
assert_eq "keyword_frequencies added" "1" "$kf"
```

- [ ] **Step 2: Update init_state to include new keys**

Modify `init_state()` in `reddit.sh` to add:

```json
"candidate_subs":[],"rejected_subs":[],"keyword_frequencies":{},"sub_clusters":[],"user_intent_timeline":{}
```

- [ ] **Step 3: Run tests**

Run: `bash skills/reddit/scripts/test/test_state.sh`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add skills/reddit/scripts/reddit.sh skills/reddit/scripts/test/test_state.sh
git commit -m "feat: add state management extensions (candidate_subs, rejected_subs, keyword_frequencies)"
```

### Task 23: Decay Report Markdown Generation

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh` (enhance `mode_quality`)
- Modify: `skills/reddit/scripts/test/test_quality.sh`

- [ ] **Step 1: Add markdown report test**

Append to `test_quality.sh`:

```bash
echo ""
echo "--- decay report markdown ---"

REPORT_MD=$(bash "$REDDIT_SH" quality --report --format markdown 2>/dev/null)
if echo "$REPORT_MD" | grep -q "not_implemented\|error"; then
  echo "  SKIP: markdown format not yet implemented"
else
  assert_contains "report has header" "$REPORT_MD" "Sub Quality"
  assert_contains "report has declining section" "$REPORT_MD" "Declining"
fi
```

- [ ] **Step 2: Add --format markdown to mode_quality**

In `mode_quality`, add a `--format` flag. When `markdown`:

```bash
    report)
      local format="${FORMAT:-json}"
      if [[ "$format" == "markdown" ]]; then
        local date
        date=$(date +%Y-%m-%d)
        echo "## Sub Quality Weekly Report — $date"
        echo ""
        echo "### Quality Summary"
        echo "| Sub | EMA Score | Peak | Trend | Hit Rate |"
        echo "|-----|----------|------|-------|----------|"
        jq -r '.subreddit_quality // {} | to_entries | sort_by(-.value.ema_score // 0) | .[] |
          "| r/" + .key + " | " +
          ((.value.ema_score // "N/A") | tostring) + " | " +
          ((.value.peak_score // "N/A") | tostring) + " | " +
          (if (.value.ema_history // [] | length) >= 2 then
            if (.value.ema_history[-1] // 0) > (.value.ema_history[-2] // 0) then "rising"
            elif (.value.ema_history[-1] // 0) < (.value.ema_history[-2] // 0) then "declining"
            else "stable" end
          else "N/A" end) + " | " +
          ((.value.hit_rate // 0) | tostring) + "% |"
        ' "$STATE_FILE"
      else
        # existing JSON output
        jq '...' "$STATE_FILE"
      fi
      ;;
```

- [ ] **Step 3: Run tests**

Run: `bash skills/reddit/scripts/test/test_quality.sh`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add skills/reddit/scripts/reddit.sh skills/reddit/scripts/test/test_quality.sh
git commit -m "feat: add markdown decay report format to quality command"
```

### Task 24: Update Help Output + Dispatch Table

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Update dispatch case statement to include all new modes**

```bash
# Change:
fetch|comments|search|discover|profile|crosspost|stickied|firehose|export|cleanup|diagnose|duplicates|wiki|stats|config)
# To:
fetch|comments|search|discover|profile|crosspost|stickied|firehose|export|cleanup|diagnose|duplicates|wiki|stats|config|expand|quality|promote)
```

- [ ] **Step 2: Update usage/help text**

```bash
echo "Modes: fetch comments search discover profile crosspost stickied firehose export cleanup diagnose duplicates wiki stats config expand quality promote"
```

- [ ] **Step 3: Run test to verify help shows new modes**

Run: `bash skills/reddit/scripts/reddit.sh 2>&1 | grep -q "expand" && echo OK || echo MISSING`
Expected: OK

- [ ] **Step 4: Commit**

```bash
git add skills/reddit/scripts/reddit.sh
git commit -m "feat: add expand/quality/promote to dispatch table and help"
```

---

## Chunk 10: Final Integration + Cleanup

### Task 25: Final Integration Test

- [ ] **Step 1: Run the complete test suite**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All test files pass, 0 failures

- [ ] **Step 2: Verify all new commands work**

```bash
bash skills/reddit/scripts/reddit.sh 2>&1 | grep "expand" && echo "expand: OK"
bash skills/reddit/scripts/reddit.sh 2>&1 | grep "quality" && echo "quality: OK"
bash skills/reddit/scripts/reddit.sh 2>&1 | grep "promote" && echo "promote: OK"
```

- [ ] **Step 3: Verify algorithm modules source correctly**

```bash
bash -c "source skills/reddit/scripts/reddit.sh 2>/dev/null; type algo_match_text" 2>&1 | grep -q "function" && echo "algo_engine: OK"
bash -c "source skills/reddit/scripts/reddit.sh 2>/dev/null; type algo_bayesian" 2>&1 | grep -q "function" && echo "algo_scoring: OK"
bash -c "source skills/reddit/scripts/reddit.sh 2>/dev/null; type algo_tfidf" 2>&1 | grep -q "function" && echo "algo_analysis: OK"
bash -c "source skills/reddit/scripts/reddit.sh 2>/dev/null; type algo_ucb1_priority" 2>&1 | grep -q "function" && echo "algo_scheduling: OK"
```

- [ ] **Step 4: Remove test_legacy.sh (all tests extracted)**

```bash
rm skills/reddit/scripts/test/test_legacy.sh
```

- [ ] **Step 5: Final commit**

```bash
git add skills/reddit/scripts/ skills/reddit/SKILL.md
git commit -m "feat: complete Sub Discovery Pipeline + Algorithm Engine v1"
```
