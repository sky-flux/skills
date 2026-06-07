#!/usr/bin/env bash
# Tests for algo_engine.sh
# Run: bash skills/reddit/scripts/test/test_algo_engine.sh

set -euo pipefail

# ─── Setup ───────────────────────────────────────────────────────────────────

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SELF_DIR/test_helpers.sh"
setup_test_paths

# Temp data dir for isolation
export REDDIT_DATA_DIR="$(mktemp -d)"
trap 'rm -rf "$REDDIT_DATA_DIR"' EXIT

source "$SCRIPT_DIR/algo_engine.sh"

INTENT_JSON="$SKILL_DIR/references/intent_keywords.json"
SUBREDDITS_JSON="$SKILL_DIR/references/subreddits.json"

# ═════════════════════════════════════════════════════════════════════════════
echo "── Aho-Corasick: algo_compile_keywords + algo_match_text ──"
# ═════════════════════════════════════════════════════════════════════════════

algo_compile_keywords "$INTENT_JSON" "$SUBREDDITS_JSON"

assert_eq "compiled file exists" "true" \
  "$( [[ -f "$ALGO_DIR/keywords_compiled.txt" ]] && echo true || echo false )"

compiled_lines=$(wc -l < "$ALGO_DIR/keywords_compiled.txt" | tr -d ' ')
assert_gt "compiled file has 10+ lines" "$compiled_lines" 10

# Check format: category:keyword
first_line=$(head -1 "$ALGO_DIR/keywords_compiled.txt")
assert_contains "compiled line has category:keyword format" "$first_line" ":"

# Match text with known signals
result=$(algo_match_text "I'm frustrated with QuickBooks and looking for a tool that supports react")
assert_contains "match has pain signal" "$result" "frustrated with"
assert_contains "match has intent signal" "$result" "looking for a tool"
assert_contains "match has tech signal" "$result" "react"

# Verify JSON structure
assert_json_key "result has pain key" "$result" "pain"
assert_json_key "result has intent key" "$result" "intent"
assert_json_key "result has tech key" "$result" "tech"

# Boring text → empty arrays
boring_result=$(algo_match_text "The weather is nice today and I had lunch")
pain_count=$(echo "$boring_result" | jq '.pain | length')
intent_count=$(echo "$boring_result" | jq '.intent | length')
tech_count=$(echo "$boring_result" | jq '.tech | length')
assert_eq "boring text: no pain signals" "0" "$pain_count"
assert_eq "boring text: no intent signals" "0" "$intent_count"
assert_eq "boring text: no tech signals" "0" "$tech_count"

# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "── Bloom Filter: algo_bloom_init, algo_bloom_add, algo_bloom_check ──"
# ═════════════════════════════════════════════════════════════════════════════

algo_bloom_init 1000

algo_bloom_add "post_abc123"
algo_bloom_add "post_def456"

check_abc=$(algo_bloom_check "post_abc123")
check_def=$(algo_bloom_check "post_def456")
check_xyz=$(algo_bloom_check "post_xyz999")

assert_eq "bloom: abc123 found" "1" "$check_abc"
assert_eq "bloom: def456 found" "1" "$check_def"
assert_eq "bloom: xyz999 not found" "0" "$check_xyz"

# Double-add same ID → no duplicates
algo_bloom_add "post_abc123"
dup_count=$(grep -c "post_abc123" "$ALGO_DIR/bloom.dat")
assert_eq "bloom: no duplicates after double-add" "1" "$dup_count"

# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "── Language Detection: algo_detect_lang ──"
# ═════════════════════════════════════════════════════════════════════════════

lang_en=$(algo_detect_lang "I am looking for the best tool and I need help with this project")
assert_eq "English text detected as en" "en" "$lang_en"

lang_de=$(algo_detect_lang "Ich bin frustriert mit der Software und die Lösung ist zu teuer für das Unternehmen")
assert_eq "German text detected as de" "de" "$lang_de"

lang_fr=$(algo_detect_lang "Je cherche une alternative à cet outil pour les entreprises des clients")
assert_eq "French text detected as fr" "fr" "$lang_fr"

# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "── Inverted Index: algo_index_add, algo_index_query ──"
# ═════════════════════════════════════════════════════════════════════════════

algo_index_add "frustrated" "post001"
algo_index_add "frustrated" "post002"
algo_index_add "quickbooks" "post001"

frustrated_results=$(algo_index_query "frustrated")
frustrated_count=$(echo "$frustrated_results" | wc -l | tr -d ' ')
assert_eq "index: frustrated has 2 results" "2" "$frustrated_count"

qb_results=$(algo_index_query "quickbooks")
assert_contains "index: quickbooks contains post001" "$qb_results" "post001"

nonexistent_results=$(algo_index_query "nonexistent")
nonexistent_count=$(echo -n "$nonexistent_results" | wc -c | tr -d ' ')
assert_eq "index: nonexistent has 0 results" "0" "$nonexistent_count"

# ═════════════════════════════════════════════════════════════════════════════
echo ""
test_summary
