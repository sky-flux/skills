#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

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

test_summary
