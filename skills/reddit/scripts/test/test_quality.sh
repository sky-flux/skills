#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo ""
echo "=== Quality Mode Tests ==="

# ─── Setup: temp data dir with pre-populated state ──────────────────────────

REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT
export REDDIT_DATA_DIR

STATE_FILE="$REDDIT_DATA_DIR/.reddit.json"

cat > "$STATE_FILE" <<'EOF'
{
  "seen_posts": {},
  "watched_threads": {},
  "opportunities": {},
  "products_seen": {},
  "influencers": {},
  "community_overlap": {},
  "subreddit_quality": {
    "SaaS": {
      "scanned": 150,
      "opportunities": 12,
      "hit_rate": 8.0,
      "ema_score": 7.5,
      "peak_score": 8.2,
      "weeks_tracked": 4,
      "ema_history": [6.0, 7.0, 7.5]
    },
    "startups": {
      "scanned": 200,
      "opportunities": 8,
      "hit_rate": 4.0,
      "ema_score": 5.2,
      "peak_score": 6.0,
      "weeks_tracked": 3,
      "ema_history": [5.5, 5.2]
    },
    "webdev": {
      "scanned": 50,
      "opportunities": 1,
      "hit_rate": 2.0,
      "ema_score": 3.0,
      "peak_score": 3.5,
      "weeks_tracked": 1,
      "ema_history": [3.0]
    }
  }
}
EOF

# ─── Test group 1: quality --report ──────────────────────────────────────────
echo ""
echo "--- Test group 1: quality --report ---"

report_output=$(bash "$REDDIT_SH" quality --report 2>/dev/null)

assert_json_key "report has quality_report key" "$report_output" "quality_report"

# Check that subs are present
subs_count=$(echo "$report_output" | jq '.quality_report.subs | length')
assert_eq "report contains 3 subs" "3" "$subs_count"

# Check sorted by ema_score descending (SaaS should be first)
first_sub=$(echo "$report_output" | jq -r '.quality_report.subs[0].sub')
assert_eq "first sub is SaaS (highest ema_score)" "SaaS" "$first_sub"

# Check trend detection
saas_trend=$(echo "$report_output" | jq -r '.quality_report.subs[0].trend')
assert_eq "SaaS trend is rising (7.5 > 7.0)" "rising" "$saas_trend"

startups_trend=$(echo "$report_output" | jq -r '.quality_report.subs[1].trend')
assert_eq "startups trend is declining (5.2 < 5.5)" "declining" "$startups_trend"

webdev_trend=$(echo "$report_output" | jq -r '.quality_report.subs[2].trend')
assert_eq "webdev trend is insufficient_data (only 1 entry)" "insufficient_data" "$webdev_trend"

# Check date is present
has_date=$(echo "$report_output" | jq -r '.quality_report.date' | grep -c '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}')
assert_eq "report has a date field" "1" "$has_date"

# ─── Test group 2: quality --history ─────────────────────────────────────────
echo ""
echo "--- Test group 2: quality --history ---"

history_output=$(bash "$REDDIT_SH" quality --history SaaS 2>/dev/null)

assert_json_key "history has scanned" "$history_output" "scanned"
assert_json_key "history has ema_score" "$history_output" "ema_score"
assert_json_key "history has ema_history" "$history_output" "ema_history"

scanned=$(echo "$history_output" | jq '.scanned')
assert_eq "SaaS scanned is 150" "150" "$scanned"

ema=$(echo "$history_output" | jq '.ema_score')
assert_eq "SaaS ema_score is 7.5" "7.5" "$ema"

# ─── Test group 3: quality --history for unknown sub ─────────────────────────
echo ""
echo "--- Test group 3: quality --history for unknown sub ---"

unknown_output=$(bash "$REDDIT_SH" quality --history nonexistent 2>/dev/null)

has_error=$(echo "$unknown_output" | jq -r '.error // empty')
assert_eq "unknown sub returns error" "sub not found" "$has_error"

# ─── Test group 4: quality with no state file ────────────────────────────────
echo ""
echo "--- Test group 4: quality with no state file ---"

rm -f "$STATE_FILE"

no_state_output=$(bash "$REDDIT_SH" quality --report 2>&1 || true)
assert_contains "no state file message" "$no_state_output" "No state file"

test_summary
