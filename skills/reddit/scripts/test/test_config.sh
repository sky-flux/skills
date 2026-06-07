#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo ""
echo "=== Config Mode Tests ==="

# ─── Setup: temp data dir ────────────────────────────────────────────────────

REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT
export REDDIT_DATA_DIR

# ─── Test group 1: config show initializes defaults ──────────────────────────
echo ""
echo "=== Test group 1: config show initializes defaults ==="

config_output=$(bash "$REDDIT_SH" config show 2>/dev/null)

assert_contains "config show outputs output_language" "$config_output" '"output_language": "en"'
assert_contains "config show outputs score_threshold" "$config_output" '"score_threshold": 7'
assert_contains "config show outputs currency_display" "$config_output" '"currency_display": "USD"'

# Verify defaults via jq
config_file="$REDDIT_DATA_DIR/config.json"
lang=$(jq -r '.output_language' "$config_file")
assert_eq "default output_language is en" "en" "$lang"

threshold=$(jq '.score_threshold' "$config_file")
assert_eq "default score_threshold is 7" "7" "$threshold"

currency=$(jq -r '.currency_display' "$config_file")
assert_eq "default currency_display is USD" "USD" "$currency"

# ─── Test group 2: config set ───────────────────────────────────────────────
echo ""
echo "=== Test group 2: config set ==="

# Change language
bash "$REDDIT_SH" config set output_language zh 2>/dev/null
new_lang=$(jq -r '.output_language' "$config_file")
assert_eq "output_language changed to zh" "zh" "$new_lang"

# Set focus_industries array
bash "$REDDIT_SH" config set focus_industries '["SaaS","DevTools"]' 2>/dev/null
industries=$(jq -r '.focus_industries | join(",")' "$config_file")
assert_eq "focus_industries set to SaaS,DevTools" "SaaS,DevTools" "$industries"

industries_len=$(jq '.focus_industries | length' "$config_file")
assert_eq "focus_industries has 2 entries" "2" "$industries_len"

# Verify other defaults unchanged
threshold_after=$(jq '.score_threshold' "$config_file")
assert_eq "score_threshold still 7 after other changes" "7" "$threshold_after"

# ─── Test group 3: config reset ─────────────────────────────────────────────
echo ""
echo "=== Test group 3: config reset ==="

bash "$REDDIT_SH" config reset 2>/dev/null

reset_lang=$(jq -r '.output_language' "$config_file")
assert_eq "output_language reset to en" "en" "$reset_lang"

reset_industries=$(jq '.focus_industries | length' "$config_file")
assert_eq "focus_industries reset to empty array" "0" "$reset_industries"

reset_threshold=$(jq '.score_threshold' "$config_file")
assert_eq "score_threshold reset to 7" "7" "$reset_threshold"

reset_currency=$(jq -r '.currency_display' "$config_file")
assert_eq "currency_display reset to USD" "USD" "$reset_currency"

test_summary
