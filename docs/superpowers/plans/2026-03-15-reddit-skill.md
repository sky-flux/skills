# Reddit Opportunity Hunter — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a skill that monitors Reddit communities worldwide to discover niche product opportunities (unmet pain points in developed markets) via curl+jq data pipeline + Claude analysis.

**Architecture:** A bash script (`reddit.sh`) with 14 modes handles all Reddit API interaction via unauthenticated JSON endpoints with browser UA spoofing. Reference JSON files configure subreddits, keywords, and patterns. `SKILL.md` orchestrates Claude's analysis of the jq-enriched data through a 4-phase pipeline (fetch → analyze → verify → report).

**Tech Stack:** bash, curl, jq, Reddit JSON API (unauthenticated)

**Spec:** `docs/superpowers/specs/2026-03-15-reddit-skill-design.md`

---

## Chunk 1: Script Foundation & Test Fixtures

### Task 1: Project skeleton and test fixtures

**Files:**
- Create: `skills/reddit/scripts/reddit.sh`
- Create: `skills/reddit/scripts/test/fixtures/fetch_response.json`
- Create: `skills/reddit/scripts/test/fixtures/comments_response.json`
- Create: `skills/reddit/scripts/test/run_tests.sh`

- [ ] **Step 1: Create project directory structure**

```bash
mkdir -p skills/reddit/scripts/test/fixtures
mkdir -p skills/reddit/references
```

- [ ] **Step 2: Create test fixtures — sample Reddit API responses**

Create `skills/reddit/scripts/test/fixtures/fetch_response.json` — a realistic Reddit listing response with ~5 posts covering different scenarios (question post, pain post, spam post, deleted post, normal post). This fixture is used by all fetch-related tests.

```json
{
  "kind": "Listing",
  "data": {
    "after": "t3_xyz789",
    "children": [
      {
        "kind": "t3",
        "data": {
          "id": "abc123",
          "subreddit": "SaaS",
          "title": "Anyone struggling to orchestrate multiple AI agents?",
          "selftext": "I've been frustrated with trying to coordinate multiple AI agents. We're a solo team with $5k MRR using supabase and next.js. Looking for a tool that handles this. Already tried LangChain but it's too complex.",
          "author": "real_user_42",
          "score": 12,
          "num_comments": 8,
          "upvote_ratio": 0.89,
          "created_utc": 1710499000,
          "permalink": "/r/SaaS/comments/abc123/anyone_struggling/",
          "link_flair_text": "B2B SaaS",
          "is_self": true,
          "edited": false,
          "removed_by_category": null,
          "num_crossposts": 0,
          "subreddit_subscribers": 620000,
          "crosspost_parent": null
        }
      },
      {
        "kind": "t3",
        "data": {
          "id": "def456",
          "subreddit": "SaaS",
          "title": "What's the best CRM for small teams?",
          "selftext": "We're a 5 person team in the US, looking for something under $20/month per seat. Already tried Salesforce (too expensive) and HubSpot (too limited).",
          "author": "startup_founder",
          "score": 25,
          "num_comments": 15,
          "upvote_ratio": 0.95,
          "created_utc": 1710490000,
          "permalink": "/r/SaaS/comments/def456/best_crm/",
          "link_flair_text": null,
          "is_self": true,
          "edited": false,
          "removed_by_category": null,
          "num_crossposts": 2,
          "subreddit_subscribers": 620000,
          "crosspost_parent": null
        }
      },
      {
        "kind": "t3",
        "data": {
          "id": "spam01",
          "subreddit": "SaaS",
          "title": "Check out my new AI tool!!!",
          "selftext": "",
          "author": "Bright-Funny1234",
          "score": -2,
          "num_comments": 0,
          "upvote_ratio": 0.2,
          "created_utc": 1710498000,
          "permalink": "/r/SaaS/comments/spam01/check_out/",
          "link_flair_text": null,
          "is_self": true,
          "edited": false,
          "removed_by_category": null,
          "num_crossposts": 0,
          "subreddit_subscribers": 620000,
          "crosspost_parent": null
        }
      },
      {
        "kind": "t3",
        "data": {
          "id": "del789",
          "subreddit": "SaaS",
          "title": "Deleted post",
          "selftext": "[removed]",
          "author": "[deleted]",
          "score": 5,
          "num_comments": 3,
          "upvote_ratio": 0.75,
          "created_utc": 1710480000,
          "permalink": "/r/SaaS/comments/del789/deleted/",
          "link_flair_text": null,
          "is_self": true,
          "edited": false,
          "removed_by_category": "moderator",
          "num_crossposts": 0,
          "subreddit_subscribers": 620000,
          "crosspost_parent": null
        }
      },
      {
        "kind": "t3",
        "data": {
          "id": "ger001",
          "subreddit": "StartupDACH",
          "title": "Alternative zu Notion für kleine Teams?",
          "selftext": "Wir sind frustriert mit Notion. Suche Tool für unser 3-Personen Startup. Empfehlung für einfaches Projektmanagement?",
          "author": "berlin_dev",
          "score": 8,
          "num_comments": 5,
          "upvote_ratio": 0.88,
          "created_utc": 1710496000,
          "permalink": "/r/StartupDACH/comments/ger001/alternative/",
          "link_flair_text": null,
          "is_self": true,
          "edited": false,
          "removed_by_category": null,
          "num_crossposts": 0,
          "subreddit_subscribers": 14900,
          "crosspost_parent": null
        }
      }
    ]
  }
}
```

Create `skills/reddit/scripts/test/fixtures/comments_response.json`:

```json
[
  {
    "kind": "Listing",
    "data": {
      "children": [
        {
          "kind": "t3",
          "data": {
            "id": "abc123",
            "title": "Anyone struggling to orchestrate multiple AI agents?",
            "selftext": "Looking for a tool...",
            "author": "real_user_42",
            "score": 12,
            "num_comments": 3
          }
        }
      ]
    }
  },
  {
    "kind": "Listing",
    "data": {
      "children": [
        {
          "kind": "t1",
          "data": {
            "id": "c001",
            "author": "helpful_dev",
            "body": "Have you tried CrewAI? I switched from LangChain and it's much simpler. Willing to pay $50/mo for something that just works.",
            "score": 8,
            "created_utc": 1710499500,
            "replies": {
              "kind": "Listing",
              "data": {
                "children": [
                  {
                    "kind": "t1",
                    "data": {
                      "id": "c002",
                      "author": "real_user_42",
                      "body": "Thanks! Budget for us is around $30/mo. Will check it out.",
                      "score": 3,
                      "created_utc": 1710500000,
                      "replies": ""
                    }
                  }
                ]
              }
            }
          }
        },
        {
          "kind": "t1",
          "data": {
            "id": "c003",
            "author": "ai_builder",
            "body": "We built our own orchestration layer on top of AWS Step Functions. Took about 2 weeks but works great for our use case.",
            "score": 5,
            "created_utc": 1710500500,
            "replies": ""
          }
        }
      ]
    }
  }
]
```

- [ ] **Step 3: Create reddit.sh with shared foundation**

Create `skills/reddit/scripts/reddit.sh` with:
- Shebang, `set -euo pipefail`
- Constants: `UA`, `BASE_URL`, `RATE_LIMIT_MIN=10`, `SLEEP_BETWEEN=3`
- `SCRIPT_DIR` resolution (for finding config files)
- `SKILL_DIR` (parent of scripts/)
- `DATA_DIR` defaults to `$PWD/.reddit-leads/` (user's project root)
- `STATE_FILE` defaults to `$DATA_DIR/.reddit.json`
- Helper functions:
  - `log()` — stderr logger with timestamp
  - `ensure_jq()` — check jq is installed
  - `ensure_data_dir()` — create `.reddit-leads/` structure if missing
  - `init_state()` — create empty `.reddit.json` if missing
  - `reddit_curl()` — curl wrapper with UA, rate limit header reading, sleep, retry on 429/403/5xx
  - `read_state()` — jq read from state file
  - `update_state()` — jq write to state file (via tmp + mv for atomicity)
- Main dispatch: `case "$1" in fetch|comments|search|...) shift; mode_$1 "$@" ;; esac`
- Stub functions for all 14 modes (just `log "TODO: $MODE"`)

Key implementation detail for `reddit_curl()`:

```bash
reddit_curl() {
  local url="$1"
  shift
  local response_file
  response_file=$(mktemp)
  local header_file
  header_file=$(mktemp)
  trap "rm -f '$response_file' '$header_file'" RETURN

  local retries=0
  while [ $retries -lt 2 ]; do
    local http_code
    http_code=$(curl -s -w "%{http_code}" -o "$response_file" -D "$header_file" \
      -H "User-Agent: $UA" \
      "$@" \
      "$url")

    # Read rate limit headers
    local remaining
    remaining=$(grep -i "x-ratelimit-remaining" "$header_file" 2>/dev/null | tr -d '\r' | awk '{print $2}' || echo "99")
    remaining=${remaining%%.*}  # truncate to int

    if [ "${remaining:-99}" -lt "$RATE_LIMIT_MIN" ]; then
      local reset
      reset=$(grep -i "x-ratelimit-reset" "$header_file" 2>/dev/null | tr -d '\r' | awk '{print $2}' || echo "60")
      reset=${reset%%.*}
      log "Rate limit low ($remaining remaining), waiting ${reset}s..."
      sleep "$reset"
    fi

    case "$http_code" in
      200) cat "$response_file"; sleep "$SLEEP_BETWEEN"; return 0 ;;
      302)
        # Subreddit name change/redirect — log new location
        local new_loc
        new_loc=$(grep -i "^location:" "$header_file" 2>/dev/null | tr -d '\r' | awk '{print $2}')
        log "HTTP 302 — redirect to $new_loc (subreddit may have been renamed)"
        # Follow redirect manually
        if [ -n "$new_loc" ]; then
          reddit_curl "$new_loc"
          return $?
        fi
        return 1
        ;;
      429)
        local retry_after
        retry_after=$(grep -i "retry-after" "$header_file" 2>/dev/null | tr -d '\r' | awk '{print $2}' || echo "60")
        retry_after=${retry_after%%.*}
        log "HTTP 429 — rate limited, waiting ${retry_after}s..."
        sleep "$retry_after"
        retries=$((retries + 1))
        ;;
      403)
        # Check for private/quarantine subreddit
        local reason
        reason=$(jq -r '.reason // empty' "$response_file" 2>/dev/null || true)
        if [ "$reason" = "private" ]; then
          log "HTTP 403 — subreddit is private: $url"
          return 2  # special exit code for private
        elif [ "$reason" = "quarantined" ]; then
          log "HTTP 403 — subreddit is quarantined: $url"
          return 2
        elif [ $retries -eq 0 ]; then
          log "HTTP 403 — switching UA and retrying..."
          UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
          retries=$((retries + 1))
        else
          log "HTTP 403 — access denied for $url"
          return 1
        fi
        ;;
      404) log "HTTP 404 — not found: $url"; return 1 ;;
      5*) log "HTTP $http_code — server error for $url, skipping"; return 1 ;;
      *) log "HTTP $http_code — unexpected for $url"; return 1 ;;
    esac
  done
  log "Max retries reached for $url"
  return 1
}
```

- [ ] **Step 4: Make script executable**

Run: `chmod +x skills/reddit/scripts/reddit.sh`

- [ ] **Step 5: Create test runner script**

Create `skills/reddit/scripts/test/run_tests.sh` that sources reddit.sh functions and validates:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURE_DIR="$SCRIPT_DIR/fixtures"
PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc"
    echo "     expected: $expected"
    echo "     actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -q "$needle"; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc — '$needle' not found"
    FAIL=$((FAIL + 1))
  fi
}

# Test 1: Spam filtering
echo "=== Test: Spam/Bot filtering ==="
SPAM_COUNT=$(jq '[.data.children[].data | select(
  (.author | test("^[A-Z][a-z]+-[A-Z][a-z]+[0-9]+$"))
  or (.is_self == true and .selftext == "")
  or (.author == "[deleted]" or .selftext == "[removed]" or .removed_by_category != null)
  or (.score < 0)
)] | length' "$FIXTURE_DIR/fetch_response.json")
assert_eq "Filters spam/deleted/negative posts" "3" "$SPAM_COUNT"

CLEAN_COUNT=$(jq '[.data.children[].data | select(
  ((.author | test("^[A-Z][a-z]+-[A-Z][a-z]+[0-9]+$")) | not)
  and ((.is_self == true and .selftext == "") | not)
  and (.author != "[deleted]" and .selftext != "[removed]" and .removed_by_category == null)
  and (.score >= 0)
)] | length' "$FIXTURE_DIR/fetch_response.json")
assert_eq "Keeps clean posts" "2" "$CLEAN_COUNT"

# Test 2: Question detection
echo "=== Test: Question detection ==="
Q1=$(jq -r '.data.children[0].data.title | test("\\?$|^How |^What |^Why |^Where |^Which |^Has anyone|^Does anyone|^Anyone |^Is there|^Can you|^Should I"; "i")' "$FIXTURE_DIR/fetch_response.json")
assert_eq "Detects 'Anyone struggling...' as question" "true" "$Q1"

Q2=$(jq -r '.data.children[1].data.title | test("\\?$|^How |^What |^Why |^Where |^Which |^Has anyone|^Does anyone|^Anyone |^Is there|^Can you|^Should I"; "i")' "$FIXTURE_DIR/fetch_response.json")
assert_eq "Detects 'What\\'s the best...' as question" "true" "$Q2"

# Test 3: Negative sentiment extraction
echo "=== Test: Negative sentiment ==="
NEG=$(jq -r '[.data.children[0].data.selftext | scan("(?i)(frustrat|disappoint|terrible|awful|waste of|regret|mistake|fail|broke|crash|bug|lost|scam|ripoff|overcharg)\\w*")] | flatten | unique | join(",")' "$FIXTURE_DIR/fetch_response.json")
assert_contains "Extracts 'frustrated' from post" "frustrated" "$NEG"

# Test 4: Tech stack detection
echo "=== Test: Tech stack detection ==="
TECH=$(jq -r '[.data.children[0].data.selftext | scan("(?i)(react|next\\.?js|vue|angular|node|python|django|rails|stripe|aws|vercel|supabase|firebase|postgres|mongo|redis|docker|kubernetes|tailwind|typescript|graphql|prisma|drizzle)")] | flatten | unique | sort | join(",")' "$FIXTURE_DIR/fetch_response.json")
assert_contains "Detects supabase" "supabase" "$TECH"
assert_contains "Detects next.js" "next.js" "$TECH"

# Test 5: Revenue mentions
echo "=== Test: Revenue mentions ==="
REV=$(jq -r '[.data.children[0].data.selftext | scan("(?i)\\$[0-9,]+k?\\s*(mrr|arr|revenue|/month|per month)")] | flatten | join(",")' "$FIXTURE_DIR/fetch_response.json")
assert_contains "Extracts MRR mention" "5k MRR" "$REV"

# Test 6: Intent keywords
echo "=== Test: Intent keywords ==="
INTENT=$(jq -r '[.data.children[0].data | (.title + " " + .selftext) | scan("(?i)(willing to pay|budget for|looking for a tool|anyone know|recommend a|help me find|switching from|need alternative|frustrated with|struggling with|what do you use for)")] | flatten | unique | join(",")' "$FIXTURE_DIR/fetch_response.json")
assert_contains "Detects 'frustrated with'" "frustrated with" "$INTENT"
assert_contains "Detects 'Looking for a tool'" "Looking for a tool" "$INTENT"

# Test 7: Comment tree parsing
echo "=== Test: Comment tree parsing ==="
COMMENT_COUNT=$(jq '[.[1].data.children[] | select(.kind == "t1")] | length' "$FIXTURE_DIR/comments_response.json")
assert_eq "Parses top-level comments" "2" "$COMMENT_COUNT"

REPLY_COUNT=$(jq '[.[1].data.children[0].data.replies.data.children[] | select(.kind == "t1")] | length' "$FIXTURE_DIR/comments_response.json")
assert_eq "Parses nested replies" "1" "$REPLY_COUNT"

# Test 8: German keyword detection
echo "=== Test: Multi-language keywords ==="
DE_INTENT=$(jq -r '[.data.children[4].data | (.title + " " + .selftext) | scan("(?i)(frustriert|Problem mit|Alternative zu|zu teuer|suche Tool|wer kennt|Empfehlung für|welches Tool|Erfahrungen mit)")] | flatten | unique | join(",")' "$FIXTURE_DIR/fetch_response.json")
assert_contains "Detects German 'Alternative zu'" "Alternative zu" "$DE_INTENT"
assert_contains "Detects German 'frustriert'" "frustriert" "$DE_INTENT"
assert_contains "Detects German 'Empfehlung'" "Empfehlung" "$DE_INTENT"

# Summary
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] || exit 1
```

- [ ] **Step 6: Run tests to verify fixtures and jq filters work**

Run: `chmod +x skills/reddit/scripts/test/run_tests.sh && bash skills/reddit/scripts/test/run_tests.sh`
Expected: All tests pass (8 test groups)

- [ ] **Step 7: Commit foundation**

```bash
git add skills/reddit/scripts/reddit.sh skills/reddit/scripts/test/
git commit -m "feat(reddit): add script foundation with shared infra and test fixtures"
```

---

### Task 2: diagnose mode

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Implement `mode_diagnose`**

Replace the stub with:

```bash
mode_diagnose() {
  local results="{}"

  # Check jq
  if command -v jq &>/dev/null; then
    results=$(echo "$results" | jq --arg v "$(jq --version 2>&1)" '.jq = {status: "ok", version: $v}')
  else
    results=$(echo "$results" | jq '.jq = {status: "missing", fix: "brew install jq"}')
  fi

  # Check curl
  if command -v curl &>/dev/null; then
    results=$(echo "$results" | jq --arg v "$(curl --version 2>&1 | head -1)" '.curl = {status: "ok", version: $v}')
  else
    results=$(echo "$results" | jq '.curl = {status: "missing"}')
  fi

  # Check network + rate limit
  local header_file
  header_file=$(mktemp)
  trap "rm -f '$header_file'" RETURN
  local http_code
  http_code=$(curl -s -w "%{http_code}" -o /dev/null -D "$header_file" \
    -H "User-Agent: $UA" \
    "https://www.reddit.com/r/SaaS/new.json?limit=1" 2>/dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local remaining reset
    remaining=$(grep -i "x-ratelimit-remaining" "$header_file" 2>/dev/null | tr -d '\r' | awk '{print $2}' || echo "unknown")
    reset=$(grep -i "x-ratelimit-reset" "$header_file" 2>/dev/null | tr -d '\r' | awk '{print $2}' || echo "unknown")
    results=$(echo "$results" | jq --arg r "$remaining" --arg s "$reset" \
      '.network = {status: "ok"} | .rate_limit = {remaining: $r, reset_seconds: $s}')
  else
    results=$(echo "$results" | jq --arg c "$http_code" '.network = {status: "error", http_code: $c}')
  fi

  # Check config
  local config_file="$SKILL_DIR/references/subreddits.json"
  if [ -f "$config_file" ]; then
    local campaign_count
    campaign_count=$(jq '.campaigns | keys | length' "$config_file" 2>/dev/null || echo "0")
    results=$(echo "$results" | jq --arg c "$campaign_count" '.config = {status: "ok", campaigns: ($c | tonumber)}')
  else
    results=$(echo "$results" | jq '.config = {status: "missing", path: "references/subreddits.json"}')
  fi

  # Check data dir
  if [ -d "$DATA_DIR" ]; then
    local size
    size=$(du -sk "$DATA_DIR" 2>/dev/null | awk '{print $1}')
    results=$(echo "$results" | jq --arg s "$size" '.data_dir = {status: "ok", size_kb: ($s | tonumber)}')
  else
    results=$(echo "$results" | jq '.data_dir = {status: "not_initialized", fix: "run any reddit.sh command to auto-create"}')
  fi

  echo "$results" | jq .
}
```

- [ ] **Step 2: Test diagnose mode**

Run: `bash skills/reddit/scripts/reddit.sh diagnose`
Expected: JSON output with `jq`, `curl`, `network`, `rate_limit`, `config`, `data_dir` fields.

- [ ] **Step 3: Commit**

```bash
git add skills/reddit/scripts/reddit.sh
git commit -m "feat(reddit): implement diagnose mode"
```

---

## Chunk 2: Core Data Pipeline (fetch + comments + search)

### Task 3: fetch mode with full jq enrichment

This is the most important mode — it fetches posts from configured subreddits and enriches them with jq-computed fields per the data contract in the spec.

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Add jq enrichment filter as a function**

Add `enrich_posts()` function that takes raw Reddit listing JSON on stdin and outputs the spec's data contract format:

```bash
enrich_posts() {
  local campaign="${1:-unknown}"
  local sort_mode="${2:-new}"
  local subreddits_str="${3:-}"

  # Build combined intent keyword regex from intent_keywords.json (all languages)
  local keywords_file="$SKILL_DIR/references/intent_keywords.json"
  local intent_regex=""
  if [ -f "$keywords_file" ]; then
    # Flatten all keywords across all languages into a single regex pattern
    intent_regex=$(jq -r '[.languages | to_entries[] | .value | to_entries[] | .value[]] | map(gsub("[\\\\.*+?^${}()|\\[\\]]"; "\\\\\\(.)"  )) | join("|")' "$keywords_file")
  fi
  # Fallback to English-only if no keywords file
  if [ -z "$intent_regex" ]; then
    intent_regex="willing to pay|budget for|what.s the pricing|free trial|need this ASAP|looking for a tool|anyone know|recommend a|help me find|switching from|need alternative|frustrated with|struggling with|what do you use for|how do you handle"
  fi

  jq --arg campaign "$campaign" --arg sort "$sort_mode" --arg subs "$subreddits_str" --arg now "$(date +%s)" --arg intent_re "$intent_regex" '
  {
    meta: {
      mode: "fetch",
      campaign: $campaign,
      sort: $sort,
      timestamp: ($now | tonumber),
      subreddits_scanned: ($subs | split(",")),
      total_raw: [.data.children[]] | length,
      total_after_filter: null,
      errors: []
    },
    posts: [
      .data.children[].data
      | select(
          ((.author | test("^[A-Z][a-z]+-[A-Z][a-z]+[0-9]+$")) | not)
          and ((.is_self == true and .selftext == "") | not)
          and (.author != "[deleted]" and .selftext != "[removed]" and .removed_by_category == null)
          and (.score >= 0)
        )
      | {
          id,
          subreddit,
          title,
          selftext,
          author,
          score,
          num_comments,
          upvote_ratio,
          created_utc,
          permalink,
          link_flair_text,
          is_self,
          edited,
          crosspost_parent,
          num_crossposts,
          subreddit_subscribers,
          _jq_enriched: {
            age_hours: (((($now | tonumber) - .created_utc) / 3600) * 100 | floor / 100),
            time_window: (
              (($now | tonumber) - .created_utc) / 3600
              | if . < 1 then "URGENT"
                elif . < 4 then "HOT"
                elif . < 24 then "WARM"
                elif . < 72 then "COOL"
                else "OLD"
                end
            ),
            is_question: (.title | test("\\?$|^How |^What |^Why |^Where |^Which |^Has anyone|^Does anyone|^Anyone |^Is there|^Can you|^Should I"; "i")),
            tags: (
              [
                (if (.title | test("\\?$|^How |^What |^Why |^Where |^Which |^Has anyone|^Does anyone|^Anyone |^Is there|^Can you|^Should I"; "i")) then "question" else empty end),
                (if ([(.title + " " + .selftext) | scan("(?i)(frustrat|disappoint|terrible|awful|waste of|regret|mistake|fail|broke|crash|bug|lost|scam|ripoff|overcharg)\\w*")] | flatten | length > 0) then "pain" else empty end),
                (if ([(.title + " " + .selftext) | scan("(?i)(willing to pay|budget for|looking for a tool|anyone know|recommend a|help me find|switching from|need alternative|frustrated with|struggling with|what do you use for|how do you handle|where do I sign up|take my money|need this ASAP|free trial|what.s the pricing)")] | flatten | length > 0) then "request" else empty end)
              ]
            ),
            intent_keywords_matched: (
              [(.title + " " + .selftext) | scan("(?i)(" + $intent_re + ")")] | flatten | unique
            ),
            negative_signals: (
              [(.title + " " + .selftext) | scan("(?i)(frustrat|disappoint|terrible|awful|waste of|regret|mistake|fail|broke|crash|bug|lost|scam|ripoff|overcharg)\\w*")] | flatten | unique
            ),
            tech_stack: (
              [(.title + " " + .selftext) | scan("(?i)(react|next\\.?js|vue|angular|node|python|django|rails|stripe|aws|vercel|supabase|firebase|postgres|mongo|redis|docker|kubernetes|tailwind|typescript|graphql|prisma|drizzle)")] | flatten | unique
            ),
            company_stage: (
              [(.title + " " + .selftext) | scan("(?i)(\\$[0-9,]+k?\\s*(?:mrr|arr|revenue|/month|per month)|solo|[0-9]+ (?:person|people|employee|team))")] | flatten
            ),
            geo_signals: (
              [(.title + " " + .selftext) | scan("(?i)(US|UK|Europe|India|Australia|Canada|Germany|France|Brazil|Asia|LATAM|APAC|EMEA)")] | flatten | unique
            ),
            revenue_mentions: (
              [(.title + " " + .selftext) | scan("(?i)\\$[0-9,]+k?\\s*(?:mrr|arr|revenue|/month|per month)")] | flatten
            ),
            is_spam: false,
            engagement_per_hour: (
              ((.score + .num_comments) / ([((($now | tonumber) - .created_utc) / 3600), 0.1] | max))
              | . * 100 | floor / 100
            )
          }
        }
    ]
  }
  | .meta.total_after_filter = (.posts | length)
  '
}
```

- [ ] **Step 2: Test enrichment against fixture**

Add to `run_tests.sh`:

```bash
echo "=== Test: Full enrichment pipeline ==="
# Source the enrich function from reddit.sh
ENRICHED=$(cat "$FIXTURE_DIR/fetch_response.json" | bash -c "
  source '$SCRIPT_DIR/../reddit.sh' --source-only 2>/dev/null || true
  # Inline test since sourcing may not work — just run jq directly
  jq --arg now '1710500000' '...'
")
# Alternatively, test the jq filter directly on fixtures
ENRICHED=$(jq --arg now "1710500000" --arg campaign "test" --arg sort "new" --arg subs "SaaS" '
  ... (same filter as above)
' "$FIXTURE_DIR/fetch_response.json")

POST_COUNT=$(echo "$ENRICHED" | jq '.posts | length')
assert_eq "Enrichment outputs 2 clean posts (filters 3 spam/deleted)" "2" "$POST_COUNT"

FIRST_TAGS=$(echo "$ENRICHED" | jq -r '.posts[0]._jq_enriched.tags | sort | join(",")')
assert_contains "First post tagged as question" "question" "$FIRST_TAGS"
assert_contains "First post tagged as pain" "pain" "$FIRST_TAGS"
assert_contains "First post tagged as request" "request" "$FIRST_TAGS"
```

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All enrichment tests pass.

- [ ] **Step 3: Implement `mode_fetch`**

```bash
mode_fetch() {
  local sort="new"
  local pages=1
  local campaign=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --sort) sort="$2"; shift 2 ;;
      --pages) pages="$2"; shift 2 ;;
      --campaign) campaign="$2"; shift 2 ;;
      *) log "Unknown option: $1"; return 1 ;;
    esac
  done

  ensure_jq
  ensure_data_dir

  # If campaign specified, read subreddits from config
  if [ -n "$campaign" ]; then
    local config_file="$SKILL_DIR/references/subreddits.json"
    if [ ! -f "$config_file" ]; then
      log "Config file not found: $config_file"
      return 1
    fi

    # Get subreddit names for this campaign
    local subs_json
    subs_json=$(jq -r --arg c "$campaign" '.campaigns[$c].subreddits // []' "$config_file")

    # Filter out search_only subreddits
    local sub_names
    sub_names=$(echo "$subs_json" | jq -r '[.[] | select(.sort_modes != ["search_only"]) | .name] | join("+")')

    if [ -z "$sub_names" ]; then
      log "No fetchable subreddits in campaign: $campaign"
      return 1
    fi

    local all_results=""
    local after=""
    local page=1

    while [ $page -le $pages ]; do
      local url="https://www.reddit.com/r/${sub_names}/${sort}.json?limit=100"
      [ -n "$after" ] && url="${url}&after=${after}"

      local response
      response=$(reddit_curl "$url") || { log "Fetch failed for page $page"; break; }

      after=$(echo "$response" | jq -r '.data.after // empty')

      if [ -z "$all_results" ]; then
        all_results="$response"
      else
        # Merge children arrays
        all_results=$(echo "$all_results" "$response" | jq -s '
          .[0].data.children += .[1].data.children | .[0]
        ')
      fi

      [ -z "$after" ] && break
      page=$((page + 1))
    done

    # Deduplicate against seen_posts
    local seen_ids=""
    if [ -f "$STATE_FILE" ]; then
      seen_ids=$(jq -r '.seen_posts // {} | keys | join("|")' "$STATE_FILE")
    fi

    # Enrich and output
    local sub_names_csv
    sub_names_csv=$(echo "$sub_names" | tr '+' ',')
    echo "$all_results" | enrich_posts "$campaign" "$sort" "$sub_names_csv"

    # Update seen_posts
    if [ -f "$STATE_FILE" ]; then
      local new_ids
      new_ids=$(echo "$all_results" | jq -r '[.data.children[].data.id] | join("\n")')
      local now
      now=$(date +%s)
      for id in $new_ids; do
        update_state ".seen_posts[\"$id\"] = $now"
      done
    fi

  else
    # No campaign — expect subreddit names via stdin or positional args
    log "Usage: reddit.sh fetch --campaign <name> [--sort new|hot|rising|top|controversial] [--pages N]"
    return 1
  fi
}
```

- [ ] **Step 4: Test fetch mode with live API (small scale)**

Run: `bash skills/reddit/scripts/reddit.sh fetch --campaign global_english --sort new --pages 1 2>/dev/null | jq '.meta'`
Expected: JSON with mode "fetch", non-zero `total_raw` and `total_after_filter`. (Requires `subreddits.json` — will test after Task 7.)

- [ ] **Step 5: Commit**

```bash
git add skills/reddit/scripts/reddit.sh skills/reddit/scripts/test/
git commit -m "feat(reddit): implement fetch mode with full jq enrichment pipeline"
```

---

### Task 4: comments mode

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Implement `mode_comments`**

```bash
mode_comments() {
  local post_id="${1:?Usage: reddit.sh comments <post_id> <subreddit>}"
  local subreddit="${2:?Usage: reddit.sh comments <post_id> <subreddit>}"
  local limit="${3:-200}"
  local depth="${4:-10}"

  ensure_jq

  local url="https://www.reddit.com/r/${subreddit}/comments/${post_id}.json?limit=${limit}&depth=${depth}"
  local response
  response=$(reddit_curl "$url") || return 1

  # Parse the 2-element array [post, comments]
  # Recursively flatten comment tree
  echo "$response" | jq '
    def flatten_comments:
      . as $items
      | [ $items[]
          | select(.kind == "t1")
          | .data
          | {
              id,
              author,
              body,
              score,
              created_utc,
              depth: (.depth // 0),
              replies: (
                if .replies == "" or .replies == null then []
                else [.replies.data.children | flatten_comments]
                end
              )
            }
        ];
    {
      post: .[0].data.children[0].data | {id, subreddit, title, selftext, author, score, num_comments, permalink},
      comments: [.[1].data.children | flatten_comments] | flatten
    }
  '
}
```

Note: The `replies` field inconsistency (object vs empty string `""`) is handled by the `if .replies == ""` check.

- [ ] **Step 2: Test against fixture**

Add to test runner:

```bash
echo "=== Test: Comments mode parsing ==="
PARSED=$(jq '
  def flatten_comments:
    . as $items
    | [ $items[]
        | select(.kind == "t1")
        | .data
        | {id, author, body, score, depth: (.depth // 0),
           replies: (if .replies == "" or .replies == null then [] else [.replies.data.children | flatten_comments] end)}
      ];
  {
    post: .[0].data.children[0].data | {id, title},
    comments: [.[1].data.children | flatten_comments] | flatten
  }
' "$FIXTURE_DIR/comments_response.json")

TOTAL_COMMENTS=$(echo "$PARSED" | jq '.comments | length')
assert_eq "Parses all comments including nested" "3" "$TOTAL_COMMENTS"

BUDGET_MENTION=$(echo "$PARSED" | jq -r '[.comments[].body | select(test("(?i)willing to pay|budget"))] | length')
assert_eq "Finds budget/payment signals in comments" "2" "$BUDGET_MENTION"
```

Run: `bash skills/reddit/scripts/test/run_tests.sh`

- [ ] **Step 3: Commit**

```bash
git add skills/reddit/scripts/reddit.sh skills/reddit/scripts/test/
git commit -m "feat(reddit): implement comments mode with nested reply parsing"
```

---

### Task 5: search mode

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Implement `mode_search`**

```bash
mode_search() {
  local query=""
  local type="post"
  local global=false
  local subreddit=""
  local sort="new"
  local time_filter="week"

  while [ $# -gt 0 ]; do
    case "$1" in
      --type) type="$2"; shift 2 ;;
      --global) global=true; shift ;;
      --subreddit) subreddit="$2"; shift 2 ;;
      --sort) sort="$2"; shift 2 ;;
      --time) time_filter="$2"; shift 2 ;;
      *) query="$1"; shift ;;
    esac
  done

  if [ -z "$query" ]; then
    log "Usage: reddit.sh search <query> [--type post|user|subreddit] [--global] [--subreddit X]"
    return 1
  fi

  ensure_jq

  local encoded_query
  encoded_query=$(printf '%s' "$query" | jq -sRr @uri)

  local url
  case "$type" in
    post)
      if [ "$global" = true ] || [ -z "$subreddit" ]; then
        url="https://www.reddit.com/search.json?q=${encoded_query}&sort=${sort}&t=${time_filter}&limit=100"
      else
        url="https://www.reddit.com/r/${subreddit}/search.json?q=${encoded_query}&restrict_sr=on&sort=${sort}&t=${time_filter}&limit=100"
      fi
      ;;
    user)
      url="https://www.reddit.com/search.json?q=${encoded_query}&type=user&limit=100"
      ;;
    subreddit)
      url="https://www.reddit.com/subreddits/search.json?q=${encoded_query}&limit=100"
      ;;
    *)
      log "Unknown type: $type (use post, user, or subreddit)"
      return 1
      ;;
  esac

  local response
  response=$(reddit_curl "$url") || return 1

  # Output in unified format
  echo "$response" | jq --arg q "$query" --arg t "$type" '{
    query: $q,
    type: $t,
    results: [.data.children[].data | if $t == "subreddit" then
      {name: .display_name, subscribers: .subscribers, description: .public_description, subreddit_type: .subreddit_type}
    elif $t == "user" then
      {name, link_karma, comment_karma, created_utc}
    else
      {id, subreddit, title, selftext, author, score, num_comments, permalink, created_utc}
    end]
  }'
}
```

- [ ] **Step 2: Commit**

```bash
git add skills/reddit/scripts/reddit.sh
git commit -m "feat(reddit): implement search mode (post/user/subreddit)"
```

---

## Chunk 3: Discovery & Analysis Modes

### Task 6: discover mode

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Implement `mode_discover`**

Supports 4 methods: keyword (default), autocomplete, footprint (search for subreddit mentions in known subs), overlap (check crosspost patterns).

```bash
mode_discover() {
  local keyword=""
  local method="keyword"

  while [ $# -gt 0 ]; do
    case "$1" in
      --method) method="$2"; shift 2 ;;
      *) keyword="$1"; shift ;;
    esac
  done

  if [ -z "$keyword" ]; then
    log "Usage: reddit.sh discover <keyword> [--method keyword|autocomplete|footprint|overlap]"
    return 1
  fi

  ensure_jq

  case "$method" in
    keyword)
      local encoded
      encoded=$(printf '%s' "$keyword" | jq -sRr @uri)
      local response
      response=$(reddit_curl "https://www.reddit.com/subreddits/search.json?q=${encoded}&limit=25") || return 1
      echo "$response" | jq --arg q "$keyword" '{
        query: $q,
        method: "keyword",
        results: [.data.children[].data | {
          name: .display_name,
          subscribers: .subscribers,
          description: .public_description,
          created_utc: .created_utc,
          subreddit_type: .subreddit_type,
          health_score: (
            if .subscribers > 10000 then "potentially_high"
            elif .subscribers > 1000 then "potentially_medium"
            else "potentially_low"
            end
          )
        }] | sort_by(-.subscribers)
      }'
      ;;
    autocomplete)
      local encoded
      encoded=$(printf '%s' "$keyword" | jq -sRr @uri)
      local response
      response=$(reddit_curl "https://www.reddit.com/api/subreddit_autocomplete_v2.json?query=${encoded}&include_over_18=false") || return 1
      echo "$response" | jq --arg q "$keyword" '{
        query: $q,
        method: "autocomplete",
        results: [.data.children[].data | {
          name: .display_name,
          subscribers: .subscribers,
          description: .public_description
        }]
      }'
      ;;
    footprint|overlap)
      # These require state data — output what we have
      if [ -f "$STATE_FILE" ]; then
        jq --arg q "$keyword" '{
          query: $q,
          method: "overlap",
          community_overlap: .community_overlap,
          suggestion: "High overlap communities may be worth monitoring"
        }' "$STATE_FILE"
      else
        echo '{"error": "No state file — run fetch first to build overlap data"}'
      fi
      ;;
  esac
}
```

- [ ] **Step 2: Commit**

```bash
git add skills/reddit/scripts/reddit.sh
git commit -m "feat(reddit): implement discover mode (keyword/autocomplete/overlap)"
```

---

### Task 7: profile mode

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Implement `mode_profile`**

```bash
mode_profile() {
  local username=""
  local enrich=false

  while [ $# -gt 0 ]; do
    case "$1" in
      --enrich) enrich=true; shift ;;
      *) username="$1"; shift ;;
    esac
  done

  if [ -z "$username" ]; then
    log "Usage: reddit.sh profile <username> [--enrich]"
    return 1
  fi

  ensure_jq

  # Fetch user about
  local about
  about=$(reddit_curl "https://www.reddit.com/user/${username}/about.json") || {
    echo "{\"error\": \"User not found or suspended: $username\"}"
    return 1
  }

  local user_info
  user_info=$(echo "$about" | jq '{
    name: .data.name,
    link_karma: .data.link_karma,
    comment_karma: .data.comment_karma,
    created_utc: .data.created_utc,
    is_gold: .data.is_gold,
    verified: .data.verified
  }')

  if [ "$enrich" = true ]; then
    # Fetch recent posts
    local posts
    posts=$(reddit_curl "https://www.reddit.com/user/${username}/submitted.json?limit=25&sort=new") || posts='{"data":{"children":[]}}'

    # Fetch recent comments
    local comments
    comments=$(reddit_curl "https://www.reddit.com/user/${username}/comments.json?limit=25&sort=new") || comments='{"data":{"children":[]}}'

    # Combine
    echo "$user_info" "$posts" "$comments" | jq -s '{
      user: .[0],
      posts: [.[1].data.children[].data | {id, subreddit, title, score, num_comments, created_utc, permalink}],
      comments: [.[2].data.children[].data | {id, subreddit, body: (.body | .[0:200]), score, created_utc, link_title}],
      subreddits_active: (
        ([.[1].data.children[].data.subreddit] + [.[2].data.children[].data.subreddit]) | unique
      ),
      urls_found: (
        [.[1].data.children[].data.selftext, .[2].data.children[].data.body]
        | map(select(. != null) | scan("https?://[^\\s)\"]+"))
        | flatten | unique
      )
    }'
  else
    echo "$user_info"
  fi
}
```

- [ ] **Step 2: Commit**

```bash
git add skills/reddit/scripts/reddit.sh
git commit -m "feat(reddit): implement profile mode with optional enrichment"
```

---

### Task 8: crosspost, stickied, firehose modes

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Implement `mode_crosspost`**

Detects users who post similar content across multiple subreddits.

```bash
mode_crosspost() {
  local campaign=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --campaign) campaign="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  ensure_jq
  ensure_data_dir

  # Run a fresh fetch and pipe to crosspost analysis
  # This ensures we always have data to analyze
  log "Fetching posts for crosspost analysis..."
  local fetch_output
  if [ -n "$campaign" ]; then
    fetch_output=$(mode_fetch --campaign "$campaign" --pages 1 2>/dev/null)
  else
    fetch_output=$(mode_fetch --campaign global_english --pages 1 2>/dev/null)
  fi

  if [ -z "$fetch_output" ]; then
    log "No fetch data available for crosspost analysis"
    return 1
  fi

  # Find authors who appear in multiple subreddits
  local result
  result=$(echo "$fetch_output" | jq '{
    multi_posters: [
      [.posts[]] | group_by(.author)
      | map(select(length > 1))
      | .[]
      | {
          author: .[0].author,
          post_count: length,
          subreddits: [.[].subreddit] | unique,
          titles: [.[].title]
        }
      | select(.subreddits | length > 1)
    ]
  }')

  echo "$result"

  # Update community_overlap in state file
  if [ -f "$STATE_FILE" ]; then
    echo "$fetch_output" | jq -r '
      [.posts[] | {author, subreddit}]
      | group_by(.author)
      | map(select(length > 1))
      | map([.[].subreddit] | unique | combinations(2) | sort | join("+"))
      | flatten | group_by(.) | map({key: .[0], value: length}) | from_entries
    ' | while IFS= read -r overlap_json; do
      if [ -n "$overlap_json" ] && [ "$overlap_json" != "{}" ]; then
        update_state ".community_overlap = (.community_overlap // {} | . * ($overlap_json | fromjson? // {}))"
      fi
    done
  fi
}
```

- [ ] **Step 2: Implement `mode_stickied`**

```bash
mode_stickied() {
  local subreddit="${1:-}"
  ensure_jq

  if [ -z "$subreddit" ]; then
    # Get stickied from all configured Tier S subs
    local config_file="$SKILL_DIR/references/subreddits.json"
    if [ ! -f "$config_file" ]; then
      log "No config file. Specify a subreddit: reddit.sh stickied <subreddit>"
      return 1
    fi
    # Just do the first few high-value subs
    local subs
    subs=$(jq -r '[.campaigns[].subreddits[].name] | .[0:5] | .[]' "$config_file")
    for sub in $subs; do
      log "Fetching stickied from r/$sub..."
      local response
      response=$(reddit_curl "https://www.reddit.com/r/${sub}/hot.json?limit=5") || continue
      local stickied
      stickied=$(echo "$response" | jq --arg sub "$sub" '[.data.children[].data | select(.stickied == true) | {id, subreddit: $sub, title, num_comments, permalink}]')
      echo "$stickied"
    done | jq -s 'flatten'
  else
    # Fetch hot (stickied are always first in hot)
    local response
    response=$(reddit_curl "https://www.reddit.com/r/${subreddit}/hot.json?limit=5") || return 1

    # Get stickied posts
    local stickied_ids
    stickied_ids=$(echo "$response" | jq -r '[.data.children[].data | select(.stickied == true) | .id] | .[]')

    # For each stickied post, fetch comments
    for post_id in $stickied_ids; do
      log "Fetching comments for stickied post $post_id in r/$subreddit..."
      mode_comments "$post_id" "$subreddit"
    done
  fi
}
```

- [ ] **Step 3: Implement `mode_firehose`**

```bash
mode_firehose() {
  local subreddits="${1:-}"
  ensure_jq

  if [ -z "$subreddits" ]; then
    # Use first few configured subs
    local config_file="$SKILL_DIR/references/subreddits.json"
    if [ ! -f "$config_file" ]; then
      log "Specify subreddits: reddit.sh firehose <sub1+sub2+sub3>"
      return 1
    fi
    subreddits=$(jq -r '[.campaigns[].subreddits[].name] | .[0:8] | join("+")' "$config_file")
  fi

  local url="https://www.reddit.com/r/${subreddits}/comments.json?limit=100"
  local response
  response=$(reddit_curl "$url") || return 1

  # Deduplicate against last known comment ID
  local last_id=""
  if [ -f "$STATE_FILE" ]; then
    last_id=$(jq -r '.last_firehose_comment_id // ""' "$STATE_FILE")
  fi

  echo "$response" | jq --arg last "$last_id" '{
    subreddits: ($ARGS.positional // []),
    comments: [
      .data.children[].data
      | {
          id,
          author,
          body,
          subreddit,
          link_title,
          link_permalink,
          score,
          created_utc,
          urls: ([.body | scan("https?://[^\\s)\"]+")]? // [])
        }
    ]
  }' --args -- $(echo "$subreddits" | tr '+' ' ')

  # Update last comment ID
  local newest_id
  newest_id=$(echo "$response" | jq -r '.data.children[0].data.id // empty')
  if [ -n "$newest_id" ] && [ -f "$STATE_FILE" ]; then
    update_state ".last_firehose_comment_id = \"$newest_id\""
  fi
}
```

- [ ] **Step 4: Commit**

```bash
git add skills/reddit/scripts/reddit.sh
git commit -m "feat(reddit): implement crosspost, stickied, firehose modes"
```

---

### Task 9: duplicates, wiki, stats, export, cleanup modes

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Implement `mode_duplicates`**

```bash
mode_duplicates() {
  local post_id="${1:?Usage: reddit.sh duplicates <post_id>}"
  ensure_jq

  local response
  response=$(reddit_curl "https://www.reddit.com/duplicates/${post_id}.json") || return 1

  echo "$response" | jq --arg id "$post_id" '{
    post_id: $id,
    duplicates: [.[1].data.children[].data | {subreddit, title, score, num_comments, permalink, created_utc}]
  }'
}
```

- [ ] **Step 2: Implement `mode_wiki`**

```bash
mode_wiki() {
  local subreddit="${1:?Usage: reddit.sh wiki <subreddit> [page]}"
  local page="${2:-}"
  ensure_jq

  if [ -z "$page" ]; then
    # List wiki pages
    local response
    response=$(reddit_curl "https://www.reddit.com/r/${subreddit}/wiki/pages.json") || {
      echo "{\"error\": \"Wiki not available for r/$subreddit\"}"
      return 1
    }
    echo "$response" | jq --arg sub "$subreddit" '{subreddit: $sub, pages: .data}'
  else
    # Get specific page
    local response
    response=$(reddit_curl "https://www.reddit.com/r/${subreddit}/wiki/${page}.json") || {
      echo "{\"error\": \"Wiki page not found: $page\"}"
      return 1
    }
    echo "$response" | jq --arg sub "$subreddit" --arg p "$page" '{
      subreddit: $sub,
      page: $p,
      content_md: .data.content_md,
      revision_date: .data.revision_date
    }'
  fi
}
```

- [ ] **Step 3: Implement `mode_stats`**

```bash
mode_stats() {
  ensure_jq

  if [ ! -f "$STATE_FILE" ]; then
    echo '{"error": "No state file. Run fetch first."}'
    return 1
  fi

  local size_kb
  size_kb=$(du -sk "$DATA_DIR" 2>/dev/null | awk '{print $1}')

  jq --arg size "$size_kb" '{
    total_seen: (.seen_posts // {} | keys | length),
    total_opportunities: (.opportunities // {} | keys | length),
    total_watched: (.watched_threads // {} | keys | length),
    subreddits_configured: "check references/subreddits.json",
    data_size_kb: ($size | tonumber),
    opportunity_breakdown: (.opportunities // {} | to_entries | group_by(.value.status) | map({(.[0].value.status): length}) | add // {}),
    influencers_tracked: (.influencers // {} | keys | length),
    products_seen: (.products_seen // {} | keys | length)
  }' "$STATE_FILE"
}
```

- [ ] **Step 4: Implement `mode_export`**

```bash
mode_export() {
  local format="json"
  while [ $# -gt 0 ]; do
    case "$1" in
      --format) format="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  ensure_jq

  if [ ! -f "$STATE_FILE" ]; then
    log "No state file. Nothing to export."
    return 1
  fi

  case "$format" in
    json)
      jq '.opportunities // {}' "$STATE_FILE"
      ;;
    csv)
      echo "name,score,status,first_seen,pain_frequency,source_post_count"
      jq -r '.opportunities // {} | to_entries[] | [.key, .value.score, .value.status, .value.first_seen, .value.pain_frequency, (.value.source_posts | length)] | @csv' "$STATE_FILE"
      ;;
    *)
      log "Unknown format: $format (use json or csv)"
      return 1
      ;;
  esac
}
```

- [ ] **Step 5: Implement `mode_cleanup`**

```bash
mode_cleanup() {
  ensure_jq

  if [ ! -f "$STATE_FILE" ]; then
    log "No state file. Nothing to clean."
    return 0
  fi

  local now
  now=$(date +%s)
  local thirty_days_ago=$((now - 30 * 86400))
  local sixty_days_ago=$((now - 60 * 86400))

  # Count before
  local before_seen before_watched before_products
  before_seen=$(jq '.seen_posts // {} | keys | length' "$STATE_FILE")
  before_watched=$(jq '.watched_threads // {} | keys | length' "$STATE_FILE")
  before_products=$(jq '.products_seen // {} | keys | length' "$STATE_FILE")

  # Clean seen_posts (30d), watched_threads (expired), products_seen (60d)
  local tmp_file
  tmp_file=$(mktemp)
  jq --arg cutoff30 "$thirty_days_ago" --arg cutoff60 "$sixty_days_ago" '
    .seen_posts = (.seen_posts // {} | to_entries | map(select(.value > ($cutoff30 | tonumber))) | from_entries)
    | .watched_threads = (.watched_threads // {} | to_entries | map(select(.value.watch_until > (now | floor))) | from_entries)
    | .products_seen = (.products_seen // {} | to_entries | map(select(
        (.value.first_seen | strptime("%Y-%m-%d") | mktime) > ($cutoff60 | tonumber)
        or .value.mention_count > 5
      )) | from_entries)
  ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"

  # Count after
  local after_seen after_watched after_products
  after_seen=$(jq '.seen_posts // {} | keys | length' "$STATE_FILE")
  after_watched=$(jq '.watched_threads // {} | keys | length' "$STATE_FILE")
  after_products=$(jq '.products_seen // {} | keys | length' "$STATE_FILE")

  jq -n --arg bs "$before_seen" --arg as "$after_seen" --arg bw "$before_watched" --arg aw "$after_watched" --arg bp "$before_products" --arg ap "$after_products" '{
    cleaned: {
      seen_posts: (($bs | tonumber) - ($as | tonumber)),
      watched_threads: (($bw | tonumber) - ($aw | tonumber)),
      products_seen: (($bp | tonumber) - ($ap | tonumber))
    },
    remaining: {
      seen_posts: ($as | tonumber),
      watched_threads: ($aw | tonumber),
      products_seen: ($ap | tonumber)
    }
  }'
}
```

- [ ] **Step 6: Commit**

```bash
git add skills/reddit/scripts/reddit.sh
git commit -m "feat(reddit): implement duplicates, wiki, stats, export, cleanup modes"
```

---

### Task 9b: watched threads checker, competitor queries, subreddit quality, .gitignore prompt

These are features identified in the spec that were missing from initial task decomposition.

**Files:**
- Modify: `skills/reddit/scripts/reddit.sh`

- [ ] **Step 1: Add `mode_watch_check` helper (called during loop)**

This is not a user-facing mode — it's a helper called by SKILL.md during `/loop` to check watched threads for new comments.

```bash
watch_check() {
  ensure_jq

  if [ ! -f "$STATE_FILE" ]; then
    return 0
  fi

  local now
  now=$(date +%s)

  # Get active watched threads (not expired)
  local threads
  threads=$(jq -r --arg now "$now" '
    .watched_threads // {} | to_entries[]
    | select(.value.watch_until > ($now | tonumber))
    | [.key, .value.subreddit, .value.last_comment_count] | @tsv
  ' "$STATE_FILE")

  if [ -z "$threads" ]; then
    log "No active watched threads"
    return 0
  fi

  local updates="[]"
  while IFS=$'\t' read -r post_id subreddit last_count; do
    local response
    response=$(reddit_curl "https://www.reddit.com/r/${subreddit}/comments/${post_id}.json?limit=1" 2>/dev/null) || continue

    local current_count
    current_count=$(echo "$response" | jq '.[0].data.children[0].data.num_comments // 0')

    if [ "$current_count" -gt "$last_count" ]; then
      local new_comments=$((current_count - last_count))
      log "Thread $post_id in r/$subreddit: $new_comments new comments"

      # Update state
      update_state ".watched_threads[\"$post_id\"].last_comment_count = $current_count | .watched_threads[\"$post_id\"].last_checked = $now"

      updates=$(echo "$updates" | jq --arg id "$post_id" --arg sub "$subreddit" --arg new "$new_comments" --arg total "$current_count" \
        '. + [{post_id: $id, subreddit: $sub, new_comments: ($new | tonumber), total_comments: ($total | tonumber)}]')
    fi
  done <<< "$threads"

  echo "$updates" | jq '{watched_updates: .}'
}
```

- [ ] **Step 2: Add `competitor_search` helper**

Expands `{competitor}` templates from subreddits.json and runs search:

```bash
competitor_search() {
  local campaign="${1:?Usage: competitor_search <campaign>}"
  ensure_jq

  local config_file="$SKILL_DIR/references/subreddits.json"
  if [ ! -f "$config_file" ]; then
    log "No config file"
    return 1
  fi

  local competitors
  competitors=$(jq -r --arg c "$campaign" '.campaigns[$c].competitors // [] | .[]' "$config_file")
  local queries
  queries=$(jq -r --arg c "$campaign" '.campaigns[$c].competitor_queries // [] | .[]' "$config_file")

  if [ -z "$competitors" ]; then
    log "No competitors configured for campaign: $campaign"
    return 0
  fi

  local all_results="[]"
  for comp in $competitors; do
    while IFS= read -r query_template; do
      local query
      query=$(echo "$query_template" | sed "s/{competitor}/$comp/g")
      log "Searching: $query"
      local result
      result=$(mode_search "$query" --global --sort new --time week 2>/dev/null) || continue
      all_results=$(echo "$all_results" "$result" | jq -s '.[0] + [.[1] | {query: .query, results: .results[:5]}]')
    done <<< "$queries"
  done

  echo "$all_results" | jq '{competitor_results: .}'
}
```

- [ ] **Step 3: Add `update_subreddit_quality` helper**

Tracks hit rate per subreddit for dynamic scan priority (spec lines 1162-1176):

```bash
update_subreddit_quality() {
  local subreddit="$1"
  local scanned_count="$2"
  local opportunity_count="${3:-0}"

  if [ ! -f "$STATE_FILE" ]; then return 0; fi

  update_state "
    .subreddit_quality[\"$subreddit\"].scanned = ((.subreddit_quality[\"$subreddit\"].scanned // 0) + $scanned_count)
    | .subreddit_quality[\"$subreddit\"].opportunities = ((.subreddit_quality[\"$subreddit\"].opportunities // 0) + $opportunity_count)
    | .subreddit_quality[\"$subreddit\"].hit_rate = (
        ((.subreddit_quality[\"$subreddit\"].opportunities // 0) + $opportunity_count)
        / ([(.subreddit_quality[\"$subreddit\"].scanned // 0) + $scanned_count, 1] | max)
        * 100 | . * 100 | floor / 100
      )
  "
}
```

- [ ] **Step 4: Add `.gitignore` check to `ensure_data_dir`**

Update `ensure_data_dir()` to also check for `.gitignore` entry:

```bash
ensure_data_dir() {
  if [ ! -d "$DATA_DIR" ]; then
    mkdir -p "$DATA_DIR/reports" "$DATA_DIR/opportunities" "$DATA_DIR/archive"
    init_state
    log "Created $DATA_DIR"

    # Check .gitignore
    if [ -f ".gitignore" ]; then
      if ! grep -q ".reddit-leads" ".gitignore" 2>/dev/null; then
        log "⚠️  Add '.reddit-leads/' to your .gitignore to avoid committing scan data"
      fi
    else
      log "⚠️  No .gitignore found. Create one and add '.reddit-leads/' to avoid committing scan data"
    fi
  fi
}
```

- [ ] **Step 5: Commit**

```bash
git add skills/reddit/scripts/reddit.sh
git commit -m "feat(reddit): add watched thread checker, competitor search, subreddit quality tracking, .gitignore prompt"
```

---

## Chunk 4: Reference Data Files

These files can be built in parallel with the script modes.

### Task 10: subreddits.json

**Files:**
- Create: `skills/reddit/references/subreddits.json`

- [ ] **Step 1: Create full subreddits.json**

Create the file with all campaigns from the spec's Tier S/A/B sections. Each campaign has subreddit configs with `name`, `subscribers`, `sort_modes`, `pages`. Include `search_keywords`, `competitors`, and `competitor_queries` per campaign. Include `scan_priority` section.

This is the largest reference file. Structure it exactly per the spec's `subreddits.json` schema (spec lines 958-1006), with all campaigns:

- `global_english` (14 SaaS/startup subs, Tier S)
- `english_developed` (UK, CA, AU, NZ, IE subs, Tier S)
- `dach` (DE/CH/AT subs, Tier S)
- `france` (FR subs, Tier S)
- `nordics` (SE/NO/DK/FI/IS subs, Tier S)
- `benelux_south_eu` (NL/BE/IT/ES/PT/GR subs, Tier S)
- `east_asia` (JP/KR/TW/HK/SG subs, Tier S)
- `middle_east_premium` (UAE/dubai subs, Tier S)
- `india` (Tier A)
- `brazil` (Tier A)
- `southeast_asia` (Tier A)
- `latam_es` (Tier A)
- `eastern_europe` (Tier A)
- `baltics` (Tier A)
- `africa` (Tier B)
- `south_asia` (Tier B)
- `turkey` (Tier B)

Large national subs (r/de, r/france, r/india, etc.) should have `sort_modes: ["search_only"]`.

- [ ] **Step 2: Validate JSON**

Run: `jq . skills/reddit/references/subreddits.json > /dev/null && echo "Valid JSON"`

- [ ] **Step 3: Commit**

```bash
git add skills/reddit/references/subreddits.json
git commit -m "feat(reddit): add global subreddits.json with 17 campaigns across 50+ countries"
```

---

### Task 11: intent_keywords.json

**Files:**
- Create: `skills/reddit/references/intent_keywords.json`

- [ ] **Step 1: Create intent_keywords.json**

Structure by language, then by tier (1-5). Include all keywords from spec's intent signal tiers (lines 227-262) plus multi-language keywords (lines 412-476).

```json
{
  "$schema": "intent-keywords-v1",
  "languages": {
    "en": {
      "tier_1_purchase_intent": [
        "willing to pay", "budget for", "what's the pricing", "free trial",
        "need this ASAP", "urgent", "deadline", "where do I sign up", "take my money"
      ],
      "tier_2_solution_seeking": [
        "looking for a tool", "anyone know", "recommend a", "help me find",
        "switching from", "need alternative", "vs"
      ],
      "tier_3_pain_expression": [
        "frustrated with", "struggling with", "doesn't support", "too expensive",
        "broken", "can't figure out", "spent hours trying"
      ],
      "tier_4_research": [
        "what do you use for", "how do you handle", "best practices for",
        "thinking about", "considering", "evaluating"
      ]
    },
    "de": {
      "pain": ["frustriert", "Problem mit", "Alternative zu", "zu teuer", "suche Tool"],
      "intent": ["wer kennt", "Empfehlung für", "welches Tool", "Erfahrungen mit"],
      "business": ["Gründung", "Startup", "Mittelstand", "GmbH", "Existenzgründung", "Digitalisierung"],
      "compliance": ["Datenschutz", "DSGVO", "Bürokratie", "GoBD"]
    },
    "fr": {
      "pain": ["frustré", "problème avec", "alternative à", "trop cher", "cherche outil"],
      "intent": ["qui connaît", "recommandation", "quel outil", "retour d'expérience"],
      "business": ["création entreprise", "startup", "French Tech", "BPI", "SARL", "SAS"],
      "compliance": ["RGPD", "charges sociales", "comptabilité"]
    },
    "pt": {
      "pain": ["frustrado", "problema com", "alternativa para", "caro demais", "preciso de ferramenta"],
      "intent": ["alguém conhece", "recomendação", "qual ferramenta", "experiência com"],
      "business": ["startup", "empreendedor", "faturamento", "negócio"]
    },
    "es": {
      "pain": ["frustrado", "problema con", "alternativa a", "demasiado caro", "busco herramienta"],
      "intent": ["alguien conoce", "recomendación", "qué herramienta", "experiencia con"],
      "business": ["emprendedor", "startup", "negocio", "empresa"]
    },
    "ja": {
      "pain": ["困っている", "代替", "高すぎる", "ツール探し"],
      "intent": ["おすすめ", "使っている人", "比較", "経験"],
      "business": ["スタートアップ", "起業", "ベンチャー", "SaaS"],
      "compliance": ["個人情報保護", "電子帳簿保存法"]
    },
    "ko": {
      "pain": ["문제", "대안", "너무 비싼", "도구 찾기"],
      "intent": ["추천", "사용해본", "비교", "경험"]
    },
    "ar": {
      "pain": ["مشكلة", "بديل", "غالي", "أداة"],
      "intent": ["توصية", "تجربة", "مقارنة"]
    },
    "fi": {
      "pain": ["ongelma", "vaihtoehto", "liian kallis", "työkalu"],
      "intent": ["suositus", "kokemus", "vertailu"]
    }
  }
}
```

- [ ] **Step 2: Validate JSON**

Run: `jq . skills/reddit/references/intent_keywords.json > /dev/null && echo "Valid JSON"`

- [ ] **Step 3: Commit**

```bash
git add skills/reddit/references/intent_keywords.json
git commit -m "feat(reddit): add multi-language intent keywords (9 languages, 5 tiers)"
```

---

### Task 12: market_keywords.json and seasonal_patterns.json

**Files:**
- Create: `skills/reddit/references/market_keywords.json`
- Create: `skills/reddit/references/seasonal_patterns.json`

- [ ] **Step 1: Create market_keywords.json**

Business and compliance terms per market, used for detecting market context.

```json
{
  "$schema": "market-keywords-v1",
  "markets": {
    "US": {
      "business": ["LLC", "C-Corp", "S-Corp", "Delaware", "venture", "seed round", "Series A"],
      "compliance": ["SOC 2", "HIPAA", "CCPA", "SOX", "PCI DSS"],
      "currency": "USD"
    },
    "UK": {
      "business": ["Ltd", "Companies House", "SEIS", "EIS", "VAT"],
      "compliance": ["GDPR", "ICO", "FCA"],
      "currency": "GBP"
    },
    "EU": {
      "business": ["GmbH", "BV", "SAS", "SARL", "AB"],
      "compliance": ["GDPR", "DSGVO", "RGPD", "eIDAS", "NIS2", "AI Act"],
      "currency": "EUR"
    },
    "DACH": {
      "business": ["GmbH", "AG", "UG", "Einzelunternehmen", "Mittelstand", "KMU"],
      "compliance": ["DSGVO", "GoBD", "Datenschutz", "Bürokratie"],
      "currency": "EUR/CHF"
    },
    "AU": {
      "business": ["Pty Ltd", "ABN", "GST", "ATO"],
      "compliance": ["Privacy Act", "APRA"],
      "currency": "AUD"
    },
    "CA": {
      "business": ["Inc", "CRA", "HST", "GST"],
      "compliance": ["PIPEDA", "CASL"],
      "currency": "CAD"
    },
    "JP": {
      "business": ["株式会社", "合同会社", "スタートアップ"],
      "compliance": ["個人情報保護法", "電子帳簿保存法"],
      "currency": "JPY"
    }
  }
}
```

- [ ] **Step 2: Create seasonal_patterns.json**

Exactly as specified in spec lines 482-521.

```json
{
  "patterns": [
    {
      "name": "US tax season",
      "regions": ["US"],
      "start_month": 1,
      "end_month": 4,
      "keywords": ["tax", "accounting", "bookkeeping", "CPA", "filing"],
      "note": "Businesses seeking tax/accounting tools"
    },
    {
      "name": "Q4 budget spend",
      "regions": ["US", "UK", "EU"],
      "start_month": 10,
      "end_month": 11,
      "keywords": ["budget", "procurement", "annual plan", "renew"],
      "note": "Use-it-or-lose-it budget → higher purchase willingness"
    },
    {
      "name": "New Year planning",
      "regions": ["global"],
      "start_month": 12,
      "end_month": 1,
      "keywords": ["2027 tools", "new year", "planning", "goals", "resolution"],
      "note": "New tools evaluation cycle"
    },
    {
      "name": "Back to school",
      "regions": ["US", "UK", "AU"],
      "start_month": 8,
      "end_month": 9,
      "keywords": ["education", "student", "school", "LMS", "learning"],
      "note": "EdTech demand spike"
    },
    {
      "name": "GDPR/privacy awareness",
      "regions": ["EU", "UK"],
      "start_month": 5,
      "end_month": 6,
      "keywords": ["GDPR", "privacy", "compliance", "data protection"],
      "note": "Annual GDPR enforcement reports trigger tool searches"
    }
  ]
}
```

- [ ] **Step 3: Validate both**

Run: `jq . skills/reddit/references/market_keywords.json > /dev/null && jq . skills/reddit/references/seasonal_patterns.json > /dev/null && echo "Both valid"`

- [ ] **Step 4: Commit**

```bash
git add skills/reddit/references/market_keywords.json skills/reddit/references/seasonal_patterns.json
git commit -m "feat(reddit): add market keywords and seasonal patterns reference data"
```

---

## Chunk 5: SKILL.md, metadata, README

### Task 13: SKILL.md — Main orchestration prompt

This is the brain of the skill — it tells Claude how to use `reddit.sh` and analyze the data through the 4-phase pipeline.

**Files:**
- Create: `skills/reddit/SKILL.md`

- [ ] **Step 1: Write SKILL.md**

The SKILL.md should cover:

1. **Frontmatter** — name: `reddit`, description (triggering text)
2. **Mission statement** — Product Opportunity Hunting, not lead hunting
3. **First-run setup** — jq check, data dir creation, .gitignore check, connectivity test
4. **Core workflow orchestration** — Phase 1-4 pipeline + Phase 3.5 micro-validation
5. **How to use reddit.sh** — all 14 modes with examples, plus helper functions (watch_check, competitor_search)
6. **Analysis instructions** — scoring algorithm (exact formula with decay), intent classification (Tier 1-5), false positive filtering, solo dev fit assessment
7. **Report templates** — daily/weekly/monthly with trigger conditions (Sunday for weekly, last day of month for monthly, catch-up if missed)
8. **Opportunity card template** — the full product opportunity report format
9. **Loop integration** — how `/loop 30m /reddit` works, including: fetch → watch_check → competitor_search → Claude analysis → report → update subreddit_quality
10. **State management** — .reddit.json structure, opportunity lifecycle state machine
11. **References** — point to subreddits.json, intent_keywords.json, etc.
12. **Score decay** — when rescanning existing opportunities, apply 0.88 weekly decay if no new mentions

Key design: SKILL.md stays under ~500 lines by referencing the JSON config files rather than inlining all data. The scoring algorithm, intent tiers, and report templates are inline because Claude needs them in context.

The description should be "pushy" per skill-creator guidelines:

```yaml
---
name: reddit
description: >-
  Monitor Reddit communities worldwide to discover niche product opportunities
  — unmet pain points, frustrated users, tool-seeking posts — from high-purchasing-power
  markets (US, UK, EU, DACH, Nordics, JP, KR, AU). Use this skill whenever the user
  mentions Reddit, product opportunities, pain point hunting, market research, niche
  discovery, subreddit monitoring, or wants to find SaaS/product ideas from real user
  discussions. Also use for /reddit commands and /loop /reddit scheduled scans.
---
```

Structure the body as:

```markdown
# Reddit Opportunity Hunter

## Mission
[from spec — product opportunity hunting, not lead hunting]

## Quick Start
[first-run: check jq, create dirs, test connectivity via `reddit.sh diagnose`]

## Core Workflow
### Phase 1: Data Collection
[run reddit.sh fetch, explain campaign system]

### Phase 2: Analysis (YOU do this)
[scoring algorithm, intent classification, pain point clustering]
[reference intent_keywords.json and seasonal_patterns.json]

### Phase 3: Deep Verification (score ≥ 8)
[reddit.sh comments, search, profile]

### Phase 3.5: Micro-Validation
[landing page test, cross-platform search]

### Phase 4: Opportunity Report
[full template from spec]

## reddit.sh Reference
[14 modes with usage examples — keep concise, ~2 lines each]

## Scoring Algorithm
[exact formula from spec]

## Report Templates
[daily scan template, brief weekly/monthly note]

## State Management
[.reddit.json structure, cleanup]

## /loop Integration
[how scheduled scanning works]

## Safety
[rate limits, no PII, .gitignore reminder]
```

- [ ] **Step 2: Validate SKILL.md is under 500 lines**

Run: `wc -l skills/reddit/SKILL.md`
Expected: Under 500 lines. If over, move detailed templates to `references/` files.

- [ ] **Step 3: Commit**

```bash
git add skills/reddit/SKILL.md
git commit -m "feat(reddit): add SKILL.md orchestration prompt"
```

---

### Task 14: metadata.json and README.md

**Files:**
- Create: `skills/reddit/metadata.json`
- Create: `skills/reddit/README.md`

- [ ] **Step 1: Create metadata.json**

```json
{
  "name": "reddit",
  "version": "1.0.0",
  "description": "Reddit Opportunity Hunter — discover niche product opportunities from global Reddit communities",
  "author": "martinadamsdev",
  "tags": ["reddit", "market-research", "product-opportunity", "saas", "niche-discovery"],
  "compatibility": {
    "requires": ["bash", "curl", "jq"],
    "optional": ["WebSearch"]
  }
}
```

- [ ] **Step 2: Create README.md**

Brief README covering: what the skill does, prerequisites (jq, curl), quick start (`/reddit` or `reddit.sh diagnose`), available modes table, example workflow.

- [ ] **Step 3: Commit**

```bash
git add skills/reddit/metadata.json skills/reddit/README.md
git commit -m "feat(reddit): add metadata.json and README"
```

---

## Chunk 6: Integration Testing & Polish

### Task 15: End-to-end integration test

**Files:**
- Modify: `skills/reddit/scripts/test/run_tests.sh`

- [ ] **Step 1: Add integration test section**

Add tests that run actual `reddit.sh` commands (requires network):

```bash
echo "=== Integration Tests (requires network) ==="

# Test diagnose
DIAG=$(bash "$SCRIPT_DIR/../reddit.sh" diagnose 2>/dev/null)
DIAG_JQ=$(echo "$DIAG" | jq -r '.jq.status')
assert_eq "diagnose: jq detected" "ok" "$DIAG_JQ"

DIAG_NET=$(echo "$DIAG" | jq -r '.network.status')
assert_eq "diagnose: network connected" "ok" "$DIAG_NET"

# Test fetch (tiny — 1 sub, limit 5)
# Only if network is up
if [ "$DIAG_NET" = "ok" ]; then
  FETCH=$(bash "$SCRIPT_DIR/../reddit.sh" fetch --campaign global_english --sort new --pages 1 2>/dev/null | head -c 50000)
  FETCH_MODE=$(echo "$FETCH" | jq -r '.meta.mode')
  assert_eq "fetch: returns correct mode" "fetch" "$FETCH_MODE"

  FETCH_COUNT=$(echo "$FETCH" | jq '.posts | length')
  echo "  ℹ️  Fetched $FETCH_COUNT posts"

  # Verify enrichment fields exist
  HAS_ENRICHED=$(echo "$FETCH" | jq '.posts[0]._jq_enriched | has("age_hours", "time_window", "tags", "is_spam")' 2>/dev/null || echo "false")
  assert_eq "fetch: posts have _jq_enriched fields" "true" "$HAS_ENRICHED"
fi
```

- [ ] **Step 2: Run full test suite**

Run: `bash skills/reddit/scripts/test/run_tests.sh`
Expected: All unit tests pass. Integration tests pass if network available.

- [ ] **Step 3: Commit**

```bash
git add skills/reddit/scripts/test/run_tests.sh
git commit -m "test(reddit): add integration tests for diagnose and fetch"
```

---

### Task 16: Final review and polish

- [ ] **Step 1: Verify all 14 modes are implemented**

Run: `grep -c 'mode_' skills/reddit/scripts/reddit.sh`
Expected: 14 mode functions.

- [ ] **Step 2: Verify all reference files exist**

Run: `ls skills/reddit/references/`
Expected: `subreddits.json`, `intent_keywords.json`, `market_keywords.json`, `seasonal_patterns.json`

- [ ] **Step 3: Verify script is executable and help works**

Run: `bash skills/reddit/scripts/reddit.sh`
Expected: Usage message showing all 14 modes.

- [ ] **Step 4: Final commit**

```bash
git add -A skills/reddit/
git commit -m "feat(reddit): complete Reddit Opportunity Hunter skill v1.0"
```

---

## Dependency Graph

```
Task 1 (foundation + fixtures)
  ├── Task 2 (diagnose) ──────────────────────────────┐
  ├── Task 3 (fetch + enrichment) ──┐                  │
  │   ├── Task 4 (comments) ────────┤                  │
  │   └── Task 5 (search) ─────────┤                  │
  ├── Task 6 (discover) ───────────┤                  │
  ├── Task 7 (profile) ───────────┤                  │
  ├── Task 8 (crosspost/stickied/  │                  │
  │         firehose) ─────────────┤                  │
  ├── Task 9 (duplicates/wiki/     │                  │
  │         stats/export/cleanup) ─┤                  │
  └── Task 9b (watch_check/        │                  │
            competitor_search/     │                  │
            subreddit_quality) ────┤                  │
                                   │                  │
Task 10 (subreddits.json) ────────┤  (parallel)      │
Task 11 (intent_keywords.json) ───┤                  │
Task 12 (market + seasonal) ──────┤                  │
                                   │                  │
                                   ▼                  │
                        Task 13 (SKILL.md) ◄──────────┘
                                   │
                        Task 14 (metadata + README)
                                   │
                        Task 15 (integration tests)
                                   │
                        Task 16 (final review)
```

**Parallelization opportunities:**
- After Task 1: Tasks 2-9b (all script modes + helpers) can run in parallel, Tasks 10-12 (reference data) can run in parallel with script tasks
- Task 3 depends on Task 11 (intent_keywords.json) for multi-language keyword matching — but can fall back to hardcoded English if run before Task 11
- Task 8 (crosspost) calls mode_fetch internally, so depends on Task 3
- Task 13 (SKILL.md) depends on all modes and reference data being done
- Tasks 14-16 are sequential at the end
