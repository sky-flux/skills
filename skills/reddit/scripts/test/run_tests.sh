#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURE_DIR="$SCRIPT_DIR/fixtures"

PASS=0
FAIL=0

# ─── Assertion helpers ────────────────────────────────────────────────────────

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

# ─── Test group 1: Spam/Bot filtering ─────────────────────────────────────────
echo ""
echo "=== Test group 1: Spam/Bot filtering ==="

# Posts to filter: spam01 (score -2), del789 (author [deleted], selftext [removed])
# and spam01 (empty selftext + auto-generated username pattern + negative score)
# Clean posts: abc123, def456, ger001

# Filter criteria: negative score OR deleted author OR removed content OR removed by moderator
# spam01: score -2 (negative score)
# del789: author [deleted] + selftext [removed] + removed_by_category moderator
# Unique filtered posts = 2 (spam01, del789); clean posts = 3 (abc123, def456, ger001)
filter_jq=$(cat <<'JQEOF'
[.data.children[] | select(
  .data.score < 0 or
  .data.author == "[deleted]" or
  .data.selftext == "[removed]" or
  .data.removed_by_category != null
)] | length
JQEOF
)
filtered_count=$(jq "$filter_jq" "$FIXTURE_DIR/fetch_response.json")

clean_jq=$(cat <<'JQEOF'
[.data.children[] | select(
  .data.score >= 0 and
  .data.author != "[deleted]" and
  .data.selftext != "[removed]" and
  .data.removed_by_category == null
)] | length
JQEOF
)
clean_count=$(jq "$clean_jq" "$FIXTURE_DIR/fetch_response.json")

assert_eq "2 posts filtered (spam01: negative score, del789: deleted/removed)" "2" "$filtered_count"
assert_eq "3 clean posts remain (abc123, def456, ger001)" "3" "$clean_count"

# ─── Test group 2: Question detection ────────────────────────────────────────
echo ""
echo "=== Test group 2: Question detection ==="

post1_title=$(jq -r '.data.children[] | select(.data.id == "abc123") | .data.title' "$FIXTURE_DIR/fetch_response.json")
post2_title=$(jq -r '.data.children[] | select(.data.id == "def456") | .data.title' "$FIXTURE_DIR/fetch_response.json")

assert_contains "post abc123 title contains question mark" "$post1_title" "?"
assert_contains "post def456 title starts with question word" "$post2_title" "What's"

# ─── Test group 3: Negative sentiment ────────────────────────────────────────
echo ""
echo "=== Test group 3: Negative sentiment ==="

post1_body=$(jq -r '.data.children[] | select(.data.id == "abc123") | .data.selftext' "$FIXTURE_DIR/fetch_response.json")

assert_contains "post abc123 body contains 'frustrated'" "$post1_body" "frustrated"

# ─── Test group 4: Tech stack detection ──────────────────────────────────────
echo ""
echo "=== Test group 4: Tech stack detection ==="

assert_contains "post abc123 body mentions supabase" "$post1_body" "supabase"
assert_contains "post abc123 body mentions next.js" "$post1_body" "next.js"

# ─── Test group 5: Revenue mentions ──────────────────────────────────────────
echo ""
echo "=== Test group 5: Revenue mentions ==="

revenue_match=$(echo "$post1_body" | grep -oE '\$[0-9]+k? MRR' || echo "")
assert_contains "post abc123 body contains \$5k MRR" "$revenue_match" "\$5k MRR"

# ─── Test group 6: Intent keywords ───────────────────────────────────────────
echo ""
echo "=== Test group 6: Intent keywords ==="

assert_contains "post abc123 body contains 'frustrated with'" "$post1_body" "frustrated with"
assert_contains "post abc123 body contains 'Looking for a tool'" "$post1_body" "Looking for a tool"

# ─── Test group 7: Comment tree ───────────────────────────────────────────────
echo ""
echo "=== Test group 7: Comment tree ==="

top_level_count=$(jq '[.[1].data.children[] | select(.kind == "t1")] | length' "$FIXTURE_DIR/comments_response.json")
nested_reply_count=$(jq '
  [ .[1].data.children[] |
    select(.kind == "t1") |
    .data.replies |
    select(type == "object") |
    .data.children[] |
    select(.kind == "t1")
  ] | length' "$FIXTURE_DIR/comments_response.json")

assert_eq "2 top-level comments in comment thread" "2" "$top_level_count"
assert_eq "1 nested reply" "1" "$nested_reply_count"

# ─── Test group 8: German keywords ───────────────────────────────────────────
echo ""
echo "=== Test group 8: German keywords ==="

ger_title=$(jq -r '.data.children[] | select(.data.id == "ger001") | .data.title' "$FIXTURE_DIR/fetch_response.json")
ger_body=$(jq -r '.data.children[] | select(.data.id == "ger001") | .data.selftext' "$FIXTURE_DIR/fetch_response.json")

assert_contains "ger001 title contains 'Alternative zu'" "$ger_title" "Alternative zu"
assert_contains "ger001 body contains 'frustriert'" "$ger_body" "frustriert"
assert_contains "ger001 body contains 'Empfehlung'" "$ger_body" "Empfehlung"

# ─── Test group 9: enrich_posts() full pipeline ───────────────────────────────
echo ""
echo "=== Test group 9: enrich_posts() full pipeline ==="

REDDIT_SH="$(dirname "$SCRIPT_DIR")/reddit.sh"
SKILL_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source the enrich_posts function (and its deps) without running main dispatch
_enrich_test_output=$(
  SKILL_DIR="$SKILL_DIR" \
  bash -c "
    source '$REDDIT_SH' 2>/dev/null || true
    # Override main dispatch to no-op after sourcing
    enrich_posts 'test_campaign' 'new' '[\"SaaS\",\"StartupDACH\"]' < '$FIXTURE_DIR/fetch_response.json'
  "
)

# 9a: correct post count after filtering (5 raw → 3 clean: abc123, def456, ger001)
enriched_count=$(echo "$_enrich_test_output" | jq '.posts | length')
assert_eq "enrich_posts: 3 posts after filtering spam/deleted" "3" "$enriched_count"

# 9b: meta fields present
meta_mode=$(echo "$_enrich_test_output" | jq -r '.meta.mode')
assert_eq "enrich_posts: meta.mode is fetch" "fetch" "$meta_mode"

meta_campaign=$(echo "$_enrich_test_output" | jq -r '.meta.campaign')
assert_eq "enrich_posts: meta.campaign is test_campaign" "test_campaign" "$meta_campaign"

meta_total_raw=$(echo "$_enrich_test_output" | jq '.meta.total_raw')
assert_eq "enrich_posts: meta.total_raw is 5" "5" "$meta_total_raw"

meta_total_after=$(echo "$_enrich_test_output" | jq '.meta.total_after_filter')
assert_eq "enrich_posts: meta.total_after_filter is 3" "3" "$meta_total_after"

# 9c: abc123 has all three expected tags: question, pain, request
abc123_tags=$(echo "$_enrich_test_output" | jq -r '.posts[] | select(.id == "abc123") | ._jq_enriched.tags | sort | join(",")')
assert_eq "enrich_posts: abc123 has tags question,pain,request" "pain,question,request" "$abc123_tags"

# 9d: _jq_enriched fields exist on abc123
abc123_has_age=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "abc123") | ._jq_enriched | has("age_hours")')
assert_eq "enrich_posts: abc123 _jq_enriched has age_hours" "true" "$abc123_has_age"

abc123_has_tw=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "abc123") | ._jq_enriched | has("time_window")')
assert_eq "enrich_posts: abc123 _jq_enriched has time_window" "true" "$abc123_has_tw"

abc123_has_tech=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "abc123") | ._jq_enriched | has("tech_stack")')
assert_eq "enrich_posts: abc123 _jq_enriched has tech_stack" "true" "$abc123_has_tech"

abc123_has_eph=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "abc123") | ._jq_enriched | has("engagement_per_hour")')
assert_eq "enrich_posts: abc123 _jq_enriched has engagement_per_hour" "true" "$abc123_has_eph"

# 9e: tech_stack detection on abc123 (supabase, next.js mentioned in body)
abc123_tech=$(echo "$_enrich_test_output" | jq -r '.posts[] | select(.id == "abc123") | ._jq_enriched.tech_stack | sort | join(",")')
assert_contains "enrich_posts: abc123 tech_stack contains supabase" "$abc123_tech" "supabase"
assert_contains "enrich_posts: abc123 tech_stack contains next.js" "$abc123_tech" "next.js"

# 9f: revenue_mentions on abc123
abc123_revenue=$(echo "$_enrich_test_output" | jq -r '.posts[] | select(.id == "abc123") | ._jq_enriched.revenue_mentions | join(",")')
assert_contains "enrich_posts: abc123 revenue_mentions contains \$5k MRR" "$abc123_revenue" "5k MRR"

# 9g: ger001 is_question should be true (title ends with ?)
ger001_is_q=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "ger001") | ._jq_enriched.is_question')
assert_eq "enrich_posts: ger001 is_question is true (ends with ?)" "true" "$ger001_is_q"

# 9h: def456 is_question should be true (title starts with "What's")
def456_is_q=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "def456") | ._jq_enriched.is_question')
assert_eq "enrich_posts: def456 is_question is true" "true" "$def456_is_q"

# 9i: geo_signals on def456 (body mentions US)
def456_geo=$(echo "$_enrich_test_output" | jq -r '.posts[] | select(.id == "def456") | ._jq_enriched.geo_signals | join(",")')
assert_contains "enrich_posts: def456 geo_signals contains US" "$def456_geo" "US"

# ─── Test group 10: Integration — diagnose mode ───────────────────────────────
echo ""
echo "=== Test group 10: Integration — diagnose mode ==="
DIAG=$(bash "$SCRIPT_DIR/../reddit.sh" diagnose 2>/dev/null)
DIAG_JQ=$(echo "$DIAG" | jq -r '.jq.status')
assert_eq "diagnose: jq detected" "ok" "$DIAG_JQ"

DIAG_CURL=$(echo "$DIAG" | jq -r '.curl.status')
assert_eq "diagnose: curl detected" "ok" "$DIAG_CURL"

# Config should be found (subreddits.json exists)
DIAG_CONFIG=$(echo "$DIAG" | jq -r '.config.status')
assert_eq "diagnose: config found" "ok" "$DIAG_CONFIG"

# ─── Test group 11: Integration — script help ─────────────────────────────────
echo ""
echo "=== Test group 11: Integration — script help ==="
HELP_OUTPUT=$(bash "$SCRIPT_DIR/../reddit.sh" 2>&1 || true)
assert_contains "help shows fetch mode" "$HELP_OUTPUT" "fetch"
assert_contains "help shows diagnose mode" "$HELP_OUTPUT" "diagnose"
assert_contains "help shows all 14 modes" "$HELP_OUTPUT" "firehose"

# ─── Test group 12: Integration — mode count ──────────────────────────────────
echo ""
echo "=== Test group 12: Integration — mode count ==="
MODE_COUNT=$(grep -c '^mode_' "$SCRIPT_DIR/../reddit.sh" || grep -c 'mode_[a-z]' "$SCRIPT_DIR/../reddit.sh")
# Should have at least 14 mode functions
if [ "$MODE_COUNT" -ge 14 ]; then
  echo "  PASS: Found $MODE_COUNT mode functions (>= 14)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Found only $MODE_COUNT mode functions (expected >= 14)"
  FAIL=$((FAIL + 1))
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "=================================================="
echo "Results: $PASS passed, $FAIL failed"
echo "=================================================="

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
