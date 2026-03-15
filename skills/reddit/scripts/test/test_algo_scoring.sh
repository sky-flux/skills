#!/usr/bin/env bash
# Tests for algo_scoring.sh — scoring algorithms (Bayesian, Wilson, EMA, Influence)

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/test_helpers.sh"
setup_test_paths
source "$SCRIPT_DIR/algo_scoring.sh"

echo "=== algo_scoring.sh tests ==="

# ─── Bayesian Average ────────────────────────────────────────────────────────

echo ""
echo "--- Bayesian Average ---"

result=$(algo_bayesian 8.0 50 5.0 15)
assert_eq "bayesian: moderate sample (8.0, n=50, avg=5.0, C=15) → 7.31" "7.31" "$result"

result=$(algo_bayesian 9.0 5 5.0 15)
assert_eq "bayesian: small sample regresses to mean (9.0, n=5, avg=5.0, C=15) → 6.00" "6.00" "$result"

result=$(algo_bayesian 8.0 200 5.0 15)
assert_eq "bayesian: large sample approaches raw (8.0, n=200, avg=5.0, C=15) → 7.79" "7.79" "$result"

# ─── Wilson Score ─────────────────────────────────────────────────────────────

echo ""
echo "--- Wilson Score ---"

result=$(algo_wilson 100 120)
in_range=$(awk -v v="$result" 'BEGIN { print (v >= 0.75 && v <= 0.78) ? "yes" : "no" }')
assert_eq "wilson: 100/120 → lower bound in [0.75, 0.78]" "yes" "$in_range"

result=$(algo_wilson 2 2)
low=$(awk -v v="$result" 'BEGIN { print (v < 0.50) ? "yes" : "no" }')
assert_eq "wilson: 2/2 → low confidence (< 0.50)" "yes" "$low"

# ─── EMA ──────────────────────────────────────────────────────────────────────

echo ""
echo "--- EMA Update ---"

result=$(algo_ema_update 8.0 6.0 0.3)
assert_eq "ema: 0.3×8 + 0.7×6 → 6.60" "6.60" "$result"

result=$(algo_ema_update 5.0 7.0 0.3)
assert_eq "ema: 0.3×5 + 0.7×7 → 6.40" "6.40" "$result"

# ─── Influence Score ──────────────────────────────────────────────────────────

echo ""
echo "--- Influence Score ---"

high_profile='{"link_karma":10000,"comment_karma":5000,"subreddits_active":["a","b","c"],"posts":10}'
high_score=$(algo_influence "$high_profile")
high_positive=$(awk -v v="$high_score" 'BEGIN { print (v > 0) ? "yes" : "no" }')
assert_eq "influence: high karma user → positive score ($high_score)" "yes" "$high_positive"

low_profile='{"link_karma":10,"comment_karma":5,"subreddits_active":["a"],"posts":1}'
low_score=$(algo_influence "$low_profile")
lower=$(awk -v h="$high_score" -v l="$low_score" 'BEGIN { print (h > l) ? "yes" : "no" }')
assert_eq "influence: high karma ($high_score) > low karma ($low_score)" "yes" "$lower"

# ─── Summary ──────────────────────────────────────────────────────────────────
setup_test_paths

echo ""
echo "=== Algo Scoring Tests ==="

# Source scoring functions
ALGO_SCORING_SH="$SCRIPT_DIR/algo_scoring.sh"
source "$ALGO_SCORING_SH"

echo ""
echo "--- score_sub_quality ---"

HIGH_SUB='{"pain_posts":23,"sample_posts":87,"geo_tier_s_ratio":0.7,"budget_mention_rate":0.15,"flesch_kincaid_avg":10.2,"professional_title_rate":0.8,"posts_per_week":45,"subscribers":161000,"competitor_posts":12,"avg_comments":12.4,"recent_post_rate":50,"older_post_rate":42,"small_team_mentions":0.3,"self_serve_signals":0.4,"compliance_mentions":0.1}'
high_score=$(score_sub_quality "$HIGH_SUB" 5.0)
high_int=$(echo "$high_score" | cut -d. -f1)
assert_gt "high quality sub scores > 3" "$high_int" "3"

LOW_SUB='{"pain_posts":0,"sample_posts":5,"geo_tier_s_ratio":0.0,"budget_mention_rate":0.0,"flesch_kincaid_avg":5.0,"professional_title_rate":0.0,"posts_per_week":0.5,"subscribers":50,"competitor_posts":0,"avg_comments":1.2,"recent_post_rate":1,"older_post_rate":1,"small_team_mentions":0.0,"self_serve_signals":0.0,"compliance_mentions":0.0}'
low_score=$(score_sub_quality "$LOW_SUB" 5.0)

# High should be significantly more than Low
high_x100=$(echo "$high_score" | awk '{printf "%d", $1 * 100}')
low_x100=$(echo "$low_score" | awk '{printf "%d", $1 * 100}')
assert_gt "high sub scores > low sub" "$high_x100" "$low_x100"

test_summary

test_summary
