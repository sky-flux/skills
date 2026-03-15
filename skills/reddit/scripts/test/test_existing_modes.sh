#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

# ─── Test group 10: Integration — diagnose mode ───────────────────────────────
echo ""
echo "=== Test group 10: Integration — diagnose mode ==="
DIAG=$(bash "$SCRIPT_DIR/reddit.sh" diagnose 2>/dev/null)
DIAG_JQ=$(echo "$DIAG" | jq -r '.jq.status')
assert_eq "diagnose: jq detected" "ok" "$DIAG_JQ"

DIAG_CURL=$(echo "$DIAG" | jq -r '.curl.status')
assert_eq "diagnose: curl detected" "ok" "$DIAG_CURL"

DIAG_CONFIG=$(echo "$DIAG" | jq -r '.config.status')
assert_eq "diagnose: config found" "ok" "$DIAG_CONFIG"

# ─── Test group 11: Integration — script help ─────────────────────────────────
echo ""
echo "=== Test group 11: Integration — script help ==="
HELP_OUTPUT=$(bash "$SCRIPT_DIR/reddit.sh" 2>&1 || true)
assert_contains "help shows fetch mode" "$HELP_OUTPUT" "fetch"
assert_contains "help shows diagnose mode" "$HELP_OUTPUT" "diagnose"
assert_contains "help shows all 14 modes" "$HELP_OUTPUT" "firehose"

# ─── Test group 12: Integration — mode count ──────────────────────────────────
echo ""
echo "=== Test group 12: Integration — mode count ==="
MODE_COUNT=$(grep -c '^mode_' "$REDDIT_SH" || true)
assert_gt "at least 14 mode functions" "$MODE_COUNT" "13"

test_summary
