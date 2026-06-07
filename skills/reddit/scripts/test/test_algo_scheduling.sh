#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

source "$SCRIPT_DIR/algo_scheduling.sh"

echo ""
echo "=== Algorithm Scheduling Tests ==="

# ─── Test group 1: UCB1 Bandit ──────────────────────────────────────────────
echo ""
echo "=== Test group 1: UCB1 Bandit ==="

stats_json='[
  {"name":"SaaS","avg_reward":0.08,"scans":100},
  {"name":"Dentistry","avg_reward":0.12,"scans":20},
  {"name":"NewSub","avg_reward":0.0,"scans":2}
]'

result=$(algo_ucb1_priority "$stats_json" 122)

# NewSub should get highest priority due to exploration bonus
first=$(echo "$result" | jq -r '.[0].name')
assert_eq "UCB1: NewSub has highest priority (exploration bonus)" "NewSub" "$first"

# All three should be present
count=$(echo "$result" | jq 'length')
assert_eq "UCB1: all 3 subs returned" "3" "$count"

# Each entry should have a priority field
has_priority=$(echo "$result" | jq 'all(has("priority"))')
assert_eq "UCB1: all entries have priority field" "true" "$has_priority"

# Priority should be sorted descending
sorted_check=$(echo "$result" | jq '[.[0].priority, .[1].priority, .[2].priority] | (.[0] >= .[1]) and (.[1] >= .[2])')
assert_eq "UCB1: results sorted by priority desc" "true" "$sorted_check"

# ─── Test group 2: Burst Detection ──────────────────────────────────────────
echo ""
echo "=== Test group 2: Burst Detection ==="

history_json='[
  {"keyword":"frustrated with","counts":[3,2,4,3,2,3,18]},
  {"keyword":"looking for tool","counts":[5,6,5,5,6,5,6]},
  {"keyword":"hate my current","counts":[1,1,2,1,1,1,10]}
]'

burst_result=$(algo_burst_detect "$history_json" 2.0)

# "frustrated with" last=18 vs baseline ~3 should burst
frustrated_burst=$(echo "$burst_result" | jq -r '.[] | select(.keyword=="frustrated with") | .burst')
assert_eq "Burst: 'frustrated with' detected as burst" "true" "$frustrated_burst"

# "looking for tool" is stable, no burst
stable_burst=$(echo "$burst_result" | jq -r '.[] | select(.keyword=="looking for tool") | .burst')
assert_eq "Burst: 'looking for tool' is not burst" "false" "$stable_burst"

# Each entry should have z_score field
has_zscore=$(echo "$burst_result" | jq 'all(has("z_score"))')
assert_eq "Burst: all entries have z_score field" "true" "$has_zscore"

# ─── Test group 3: Z-Score ──────────────────────────────────────────────────
echo ""
echo "=== Test group 3: Z-Score ==="

z1=$(algo_zscore 100 50 15)
assert_eq "Z-Score: (100-50)/15 = 3.33" "3.33" "$z1"

z2=$(algo_zscore 50 50 15)
assert_eq "Z-Score: (50-50)/15 = 0.00" "0.00" "$z2"

# ─── Test group 4: SMA Decomposition ────────────────────────────────────────
echo ""
echo "=== Test group 4: SMA Decomposition ==="

weekly_json='[10,12,14,16,18,20,22,24,26,28,30,32]'

sma_result=$(algo_sma_decompose "$weekly_json" 3)

trend_len=$(echo "$sma_result" | jq '.trend | length')
assert_eq "SMA: trend array length = 12" "12" "$trend_len"

has_residual=$(echo "$sma_result" | jq 'has("residual")')
assert_eq "SMA: residual field exists" "true" "$has_residual"

residual_len=$(echo "$sma_result" | jq '.residual | length')
assert_eq "SMA: residual array length = 12" "12" "$residual_len"

# ─── Test group 5: Sequential Pattern ───────────────────────────────────────
echo ""
echo "=== Test group 5: Sequential Pattern ==="

timeline_json='[
  {"user":"u1","events":["pain","seek","compare"]},
  {"user":"u2","events":["pain","seek"]},
  {"user":"u3","events":["seek","compare","buy"]},
  {"user":"u4","events":["pain","seek","buy"]},
  {"user":"u5","events":["browse","leave"]}
]'

pattern_result=$(algo_sequential_pattern "$timeline_json" 0.3)

# "pain->seek" appears in u1, u2, u4 = 3/5 = 60% support
pain_seek=$(echo "$pattern_result" | jq -r '.[] | select(.pattern=="pain->seek") | .support')
assert_contains "Sequential: pain->seek found with support >= 0.3" "$pain_seek" "0.6"

# All returned patterns should have support >= min_support
all_above=$(echo "$pattern_result" | jq 'all(.support >= 0.3)')
assert_eq "Sequential: all patterns meet min_support threshold" "true" "$all_above"

test_summary
