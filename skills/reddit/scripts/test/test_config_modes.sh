#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo ""
echo "=== Config Modes Tests (stats, export, cleanup, discover, watch_check) ==="

# ─── Setup: temp data dir ────────────────────────────────────────────────────

export REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT

# Source state functions from reddit.sh
eval "$(SKILL_DIR="$SKILL_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f log init_state read_state update_state ensure_data_dir ensure_jq init_config")"
export SKILL_DIR DATA_DIR="$REDDIT_DATA_DIR" STATE_FILE="$REDDIT_DATA_DIR/.reddit.json" CONFIG_FILE="$REDDIT_DATA_DIR/config.json"

# Initialize state
init_state 2>/dev/null

# ─── Test 1: mode_stats ──────────────────────────────────────────────────────
echo ""
echo "--- Test 1: mode_stats ---"

STATS_OUTPUT=$(REDDIT_DATA_DIR="$REDDIT_DATA_DIR" bash "$REDDIT_SH" stats 2>/dev/null)
assert_json_key "stats has total_seen" "$STATS_OUTPUT" "total_seen"
assert_json_key "stats has total_opportunities" "$STATS_OUTPUT" "total_opportunities"
assert_json_key "stats has total_watched" "$STATS_OUTPUT" "total_watched"

# ─── Test 2: mode_export JSON ────────────────────────────────────────────────
echo ""
echo "--- Test 2: mode_export JSON ---"

# Add a test opportunity to state
update_state '.opportunities["test_product"] = {"score": 85, "status": "active", "first_seen": 1700000000, "pain_frequency": 3, "source_posts": ["post1", "post2"]}'

EXPORT_JSON=$(REDDIT_DATA_DIR="$REDDIT_DATA_DIR" bash "$REDDIT_SH" export --format json 2>/dev/null)
assert_contains "export JSON contains test_product" "$EXPORT_JSON" "test_product"
assert_contains "export JSON contains score" "$EXPORT_JSON" "85"

# ─── Test 3: mode_export CSV ─────────────────────────────────────────────────
echo ""
echo "--- Test 3: mode_export CSV ---"

EXPORT_CSV=$(REDDIT_DATA_DIR="$REDDIT_DATA_DIR" bash "$REDDIT_SH" export --format csv 2>/dev/null)
assert_contains "CSV has header row" "$EXPORT_CSV" "name,score,status,first_seen,pain_frequency,source_post_count"
assert_contains "CSV contains test_product" "$EXPORT_CSV" "test_product"

# ─── Test 4: mode_cleanup ────────────────────────────────────────────────────
echo ""
echo "--- Test 4: mode_cleanup ---"

# Add an old seen_post (60+ days ago) and a recent one
NOW=$(date +%s)
OLD_TS=$((NOW - 61 * 86400))
RECENT_TS=$((NOW - 5 * 86400))

update_state ".seen_posts[\"old_post\"] = $OLD_TS"
update_state ".seen_posts[\"recent_post\"] = $RECENT_TS"

# Verify both exist before cleanup
old_before=$(read_state '.seen_posts["old_post"]')
recent_before=$(read_state '.seen_posts["recent_post"]')
assert_eq "old_post exists before cleanup" "$OLD_TS" "$old_before"
assert_eq "recent_post exists before cleanup" "$RECENT_TS" "$recent_before"

# Run cleanup
CLEANUP_OUTPUT=$(REDDIT_DATA_DIR="$REDDIT_DATA_DIR" bash "$REDDIT_SH" cleanup 2>/dev/null)

# Verify old one removed and recent one survives
old_after=$(read_state '.seen_posts["old_post"] // "gone"')
recent_after=$(read_state '.seen_posts["recent_post"]')
assert_eq "old_post removed after cleanup" "gone" "$old_after"
assert_eq "recent_post survives cleanup" "$RECENT_TS" "$recent_after"

# ─── Test 5: discover no keyword ─────────────────────────────────────────
echo ""
echo "--- Test 5: discover no keyword ---"

DISCOVER_ERR=$(REDDIT_DATA_DIR="$REDDIT_DATA_DIR" bash "$REDDIT_SH" discover 2>&1 || true)
assert_contains "discover no keyword shows usage" "$DISCOVER_ERR" "Usage"

# ─── Test 6: watch_check empty ────────────────────────────────────────────────
echo ""
echo "--- Test 6: watch_check empty ---"

# Ensure watched_threads is empty
update_state '.watched_threads = {}'

# Source watch_check and run it -- should not error
eval "$(SKILL_DIR="$SKILL_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f watch_check log ensure_jq reddit_curl read_state update_state")"
WATCH_OUTPUT=$(watch_check 2>&1 || true)
# Should mention no active threads or produce empty result, but not crash
assert_contains "watch_check empty: no error" "$WATCH_OUTPUT" "No active watched threads"

test_summary
