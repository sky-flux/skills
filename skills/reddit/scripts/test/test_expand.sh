#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== Expand Command Tests ==="

export REDDIT_DATA_DIR
REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT
mkdir -p "$REDDIT_DATA_DIR"

cat > "$REDDIT_DATA_DIR/.reddit.json" << 'STATE'
{"seen_posts":{},"watched_threads":{},"opportunities":{},"products_seen":{},"influencers":{},"community_overlap":{},"subreddit_quality":{"SaaS":{"scanned":200,"opportunities":8,"hit_rate":4.0,"ema_score":7.5},"startups":{"scanned":150,"opportunities":5,"hit_rate":3.33,"ema_score":6.8}}}
STATE

EXPAND=$(bash "$REDDIT_SH" expand --campaign global_english 2>/dev/null)
assert_json_key "expand returns campaign" "$EXPAND" 'campaign'
assert_contains "expand has global_english" "$EXPAND" "global_english"

EXPAND_ERR=$(bash "$REDDIT_SH" expand 2>&1 || true)
assert_contains "expand requires --campaign" "$EXPAND_ERR" "Usage"

test_summary
