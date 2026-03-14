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

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "=================================================="
echo "Results: $PASS passed, $FAIL failed"
echo "=================================================="

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
