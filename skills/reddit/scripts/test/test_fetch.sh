#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

# ─── Test group 1: Spam/Bot filtering ─────────────────────────────────────────
echo ""
echo "=== Test group 1: Spam/Bot filtering ==="

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

_enrich_test_output=$(
  SKILL_DIR="$SKILL_DIR" \
  bash -c "
    source '$REDDIT_SH' 2>/dev/null || true
    enrich_posts 'test_campaign' 'new' '[\"SaaS\",\"StartupDACH\"]' < '$FIXTURE_DIR/fetch_response.json'
  "
)

# 9a: correct post count after filtering
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

# 9c: abc123 has all three expected tags
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

# 9e: tech_stack detection on abc123
abc123_tech=$(echo "$_enrich_test_output" | jq -r '.posts[] | select(.id == "abc123") | ._jq_enriched.tech_stack | sort | join(",")')
assert_contains "enrich_posts: abc123 tech_stack contains supabase" "$abc123_tech" "supabase"
assert_contains "enrich_posts: abc123 tech_stack contains next.js" "$abc123_tech" "next.js"

# 9f: revenue_mentions on abc123
abc123_revenue=$(echo "$_enrich_test_output" | jq -r '.posts[] | select(.id == "abc123") | ._jq_enriched.revenue_mentions | join(",")')
assert_contains "enrich_posts: abc123 revenue_mentions contains \$5k MRR" "$abc123_revenue" "5k MRR"

# 9g: ger001 is_question should be true
ger001_is_q=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "ger001") | ._jq_enriched.is_question')
assert_eq "enrich_posts: ger001 is_question is true (ends with ?)" "true" "$ger001_is_q"

# 9h: def456 is_question should be true
def456_is_q=$(echo "$_enrich_test_output" | jq '.posts[] | select(.id == "def456") | ._jq_enriched.is_question')
assert_eq "enrich_posts: def456 is_question is true" "true" "$def456_is_q"

# 9i: geo_signals on def456
def456_geo=$(echo "$_enrich_test_output" | jq -r '.posts[] | select(.id == "def456") | ._jq_enriched.geo_signals | join(",")')
assert_contains "enrich_posts: def456 geo_signals contains US" "$def456_geo" "US"

test_summary
