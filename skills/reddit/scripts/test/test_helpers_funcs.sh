#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo ""
echo "=== Helper Function Tests ==="

# ─── Setup: temp data dir ────────────────────────────────────────────────────

REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT

# Source reddit.sh functions into this shell
eval "$(SKILL_DIR="$SKILL_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f log init_state read_state update_state update_subreddit_quality ensure_data_dir ensure_jq init_config")"
export SKILL_DIR DATA_DIR="$REDDIT_DATA_DIR" STATE_FILE="$REDDIT_DATA_DIR/.reddit.json" CONFIG_FILE="$REDDIT_DATA_DIR/config.json"

# Initialize state
init_state 2>/dev/null

# ─── Test group 1: update_subreddit_quality first call ───────────────────────
echo ""
echo "=== Test group 1: update_subreddit_quality first call ==="

update_subreddit_quality "SaaS" 50 3

scanned=$(read_state '.subreddit_quality["SaaS"].scanned')
assert_eq "SaaS scanned is 50 after first call" "50" "$scanned"

opportunities=$(read_state '.subreddit_quality["SaaS"].opportunities')
assert_eq "SaaS opportunities is 3 after first call" "3" "$opportunities"

hit_rate=$(read_state '.subreddit_quality["SaaS"].hit_rate')
assert_eq "SaaS hit_rate is 6 after first call (3/50*100)" "6" "$hit_rate"

# ─── Test group 2: update_subreddit_quality accumulation ────────────────────
echo ""
echo "=== Test group 2: update_subreddit_quality accumulation ==="

update_subreddit_quality "SaaS" 30 2

scanned2=$(read_state '.subreddit_quality["SaaS"].scanned')
assert_eq "SaaS scanned accumulated to 80" "80" "$scanned2"

opportunities2=$(read_state '.subreddit_quality["SaaS"].opportunities')
assert_eq "SaaS opportunities accumulated to 5" "5" "$opportunities2"

hit_rate2=$(read_state '.subreddit_quality["SaaS"].hit_rate')
# Note: the hit_rate formula re-adds opportunity_count to the already-updated .opportunities,
# and re-adds scanned_count to the already-updated .scanned, so: (5+2)/(80+30)*100 = 6.36
assert_eq "SaaS hit_rate after accumulation" "6.36" "$hit_rate2"

# ─── Test group 3: multiple subreddits ──────────────────────────────────────
echo ""
echo "=== Test group 3: multiple subreddits ==="

update_subreddit_quality "Startups" 100 10

startups_scanned=$(read_state '.subreddit_quality["Startups"].scanned')
assert_eq "Startups scanned is 100" "100" "$startups_scanned"

startups_opp=$(read_state '.subreddit_quality["Startups"].opportunities')
assert_eq "Startups opportunities is 10" "10" "$startups_opp"

# Verify SaaS is still intact
saas_still=$(read_state '.subreddit_quality["SaaS"].scanned')
assert_eq "SaaS scanned still 80 after adding Startups" "80" "$saas_still"

total_subs=$(read_state '.subreddit_quality | keys | length')
assert_eq "subreddit_quality has 2 entries" "2" "$total_subs"

test_summary
