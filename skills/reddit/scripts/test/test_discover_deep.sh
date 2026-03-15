#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo "=== Discover Deep + Probing Tests ==="

# Test probe_sample_posts with fixture data
eval "$(SKILL_DIR="$SKILL_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f probe_sample_posts 2>/dev/null || echo 'probe_sample_posts() { echo not_implemented; }'")"

PROBE=$(probe_sample_posts "$FIXTURE_DIR/fetch_response.json" 2>/dev/null)
if [[ "$PROBE" == "not_implemented" ]]; then
  echo "  SKIP: probe_sample_posts not yet implemented"
else
  assert_json_key "probe has sample_posts" "$PROBE" 'sample_posts'
  assert_json_key "probe has pain_posts" "$PROBE" 'pain_posts'
  assert_json_key "probe has avg_comments" "$PROBE" 'avg_comments'
  sample=$(echo "$PROBE" | jq '.sample_posts')
  assert_eq "probe: 3 clean posts" "3" "$sample"
  pain=$(echo "$PROBE" | jq '.pain_posts')
  assert_gt "probe: at least 1 pain post" "$pain" "0"
fi

# Test merge_discovered_subs
export REDDIT_DATA_DIR
REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT
mkdir -p "$REDDIT_DATA_DIR"

cat > "$REDDIT_DATA_DIR/discovered_subs.json" << 'DISC'
{"discovered":{"global_english":[{"name":"DiscoveredTestSub","subscribers":1000,"sort_modes":["new"],"pages":1}]}}
DISC

eval "$(SKILL_DIR="$SKILL_DIR" DATA_DIR="$REDDIT_DATA_DIR" bash -c "source '$REDDIT_SH' 2>/dev/null; declare -f merge_discovered_subs 2>/dev/null || echo 'merge_discovered_subs() { echo not_implemented; }'")"
export DATA_DIR="$REDDIT_DATA_DIR"

MERGED=$(merge_discovered_subs "global_english" "$SKILL_DIR/references/subreddits.json" 2>/dev/null)
if [[ "$MERGED" == "not_implemented" ]]; then
  echo "  SKIP: merge_discovered_subs not yet implemented"
else
  assert_contains "merged includes DiscoveredTestSub" "$MERGED" "DiscoveredTestSub"
  assert_contains "merged includes SaaS (original)" "$MERGED" "SaaS"
fi

test_summary
