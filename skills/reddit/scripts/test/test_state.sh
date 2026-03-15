#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo ""
echo "=== State Management Tests ==="

# ─── Setup: temp data dir ────────────────────────────────────────────────────

REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT

# Source reddit.sh functions into this shell
eval "$(SKILL_DIR="$SKILL_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f log init_state read_state update_state ensure_data_dir ensure_jq init_config")"
export SKILL_DIR DATA_DIR="$REDDIT_DATA_DIR" STATE_FILE="$REDDIT_DATA_DIR/.reddit.json" CONFIG_FILE="$REDDIT_DATA_DIR/config.json"

# ─── Test group 1: init_state ────────────────────────────────────────────────
echo ""
echo "=== Test group 1: init_state ==="

init_state 2>/dev/null

assert_eq "state file exists after init_state" "true" "$([ -f "$STATE_FILE" ] && echo true || echo false)"

seen_posts=$(jq -r '.seen_posts | keys | length' "$STATE_FILE")
assert_eq "seen_posts is empty after init" "0" "$seen_posts"

watched_threads=$(jq -r '.watched_threads | keys | length' "$STATE_FILE")
assert_eq "watched_threads is empty after init" "0" "$watched_threads"

# Verify all expected top-level keys
assert_eq "state has seen_posts key" "true" "$(jq 'has("seen_posts")' "$STATE_FILE")"
assert_eq "state has watched_threads key" "true" "$(jq 'has("watched_threads")' "$STATE_FILE")"
assert_eq "state has opportunities key" "true" "$(jq 'has("opportunities")' "$STATE_FILE")"
assert_eq "state has subreddit_quality key" "true" "$(jq 'has("subreddit_quality")' "$STATE_FILE")"

# ─── Test group 2: update_state and read_state ──────────────────────────────
echo ""
echo "=== Test group 2: update_state and read_state ==="

# Add a seen post
update_state '.seen_posts["post123"] = 1700000000'
seen_val=$(read_state '.seen_posts["post123"]')
assert_eq "seen_posts contains post123 after update" "1700000000" "$seen_val"

# Add another seen post
update_state '.seen_posts["post456"] = 1700000001'
seen_count=$(read_state '.seen_posts | keys | length')
assert_eq "seen_posts has 2 entries" "2" "$seen_count"

# Add a watched thread
update_state '.watched_threads["thread001"] = {"subreddit": "SaaS", "watch_until": 1700100000, "last_comment_count": 5}'
watched_sub=$(read_state '.watched_threads["thread001"].subreddit')
assert_eq "watched thread subreddit is SaaS" "SaaS" "$watched_sub"

watched_count=$(read_state '.watched_threads["thread001"].last_comment_count')
assert_eq "watched thread last_comment_count is 5" "5" "$watched_count"

# Verify read_state returns correct total
total_watched=$(read_state '.watched_threads | keys | length')
assert_eq "watched_threads has 1 entry" "1" "$total_watched"

# ─── Test group 3: directory structure ───────────────────────────────────────
echo ""
echo "=== Test group 3: directory structure ==="

assert_eq "reports/ directory exists" "true" "$([ -d "$REDDIT_DATA_DIR/reports" ] && echo true || echo false)"
assert_eq "opportunities/ directory exists" "true" "$([ -d "$REDDIT_DATA_DIR/opportunities" ] && echo true || echo false)"
assert_eq "archive/ directory exists" "true" "$([ -d "$REDDIT_DATA_DIR/archive" ] && echo true || echo false)"

test_summary
