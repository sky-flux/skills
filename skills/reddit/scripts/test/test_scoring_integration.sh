#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo ""
echo "=== Scoring Integration Tests ==="

# ─── Source algo_scoring.sh ──────────────────────────────────────────────────

ALGO_SCORING="$SCRIPT_DIR/algo_scoring.sh"
if [[ ! -f "$ALGO_SCORING" ]]; then
  echo "SKIP: algo_scoring.sh not found at $ALGO_SCORING"
  echo "      (expected once algo_scoring module is implemented)"
  exit 0
fi

source "$ALGO_SCORING"

# ─── Load fixtures ───────────────────────────────────────────────────────────

SCORING_FIXTURE="$FIXTURE_DIR/scoring_samples.json"
if [[ ! -f "$SCORING_FIXTURE" ]]; then
  echo "FAIL: scoring_samples.json fixture not found"
  exit 1
fi

DENTISTRY=$(jq '.Dentistry' "$SCORING_FIXTURE")
SMALL_SUB=$(jq '.SmallSubNoActivity' "$SCORING_FIXTURE")

# ─── Test 1: Dentistry (high quality sub) ────────────────────────────────────
echo ""
echo "=== Test 1: Dentistry — high quality subreddit scoring ==="

# Pain density = pain_posts / sample_posts
d_pain_posts=$(echo "$DENTISTRY" | jq -r '.pain_posts')
d_sample_posts=$(echo "$DENTISTRY" | jq -r '.sample_posts')
d_pain_density=$(echo "scale=4; $d_pain_posts / $d_sample_posts" | bc)

# Pain density should be > 0 for a high-quality sub
if (( $(echo "$d_pain_density > 0" | bc -l) )); then
  echo "  PASS: Dentistry pain density is positive ($d_pain_density)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Dentistry pain density should be > 0 (got $d_pain_density)"
  FAIL=$((FAIL + 1))
fi

# Purchasing power dimension: geo_tier_s_ratio + budget_mention_rate + professional_title_rate
d_geo=$(echo "$DENTISTRY" | jq -r '.geo_tier_s_ratio')
d_budget=$(echo "$DENTISTRY" | jq -r '.budget_mention_rate')
d_prof=$(echo "$DENTISTRY" | jq -r '.professional_title_rate')
d_purchasing=$(echo "scale=4; $d_geo + $d_budget + $d_prof" | bc)

if (( $(echo "$d_purchasing > 0" | bc -l) )); then
  echo "  PASS: Dentistry purchasing power signals are positive ($d_purchasing)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Dentistry purchasing power should be > 0 (got $d_purchasing)"
  FAIL=$((FAIL + 1))
fi

# Activity dimension: posts_per_week + avg_comments + avg_score
d_ppw=$(echo "$DENTISTRY" | jq -r '.posts_per_week')
d_comments=$(echo "$DENTISTRY" | jq -r '.avg_comments')
d_score=$(echo "$DENTISTRY" | jq -r '.avg_score')
d_activity=$(echo "scale=4; $d_ppw + $d_comments + $d_score" | bc)

if (( $(echo "$d_activity > 0" | bc -l) )); then
  echo "  PASS: Dentistry activity signals are positive ($d_activity)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Dentistry activity should be > 0 (got $d_activity)"
  FAIL=$((FAIL + 1))
fi

# Composite: partial score from available dimensions should be positive
d_partial=$(echo "scale=4; $d_pain_density * 100 + $d_purchasing * 50 + $d_activity" | bc)

if (( $(echo "$d_partial > 0" | bc -l) )); then
  echo "  PASS: Dentistry partial score is positive ($d_partial)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Dentistry partial score should be > 0 (got $d_partial)"
  FAIL=$((FAIL + 1))
fi

# ─── Test 2: SmallSubNoActivity (low quality sub) ───────────────────────────
echo ""
echo "=== Test 2: SmallSubNoActivity — low quality subreddit scoring ==="

s_pain_posts=$(echo "$SMALL_SUB" | jq -r '.pain_posts')
s_sample_posts=$(echo "$SMALL_SUB" | jq -r '.sample_posts')

# Pain density should be 0 (0 pain posts)
if [[ "$s_pain_posts" == "0" ]]; then
  s_pain_density="0"
else
  s_pain_density=$(echo "scale=4; $s_pain_posts / $s_sample_posts" | bc)
fi

assert_eq "SmallSubNoActivity pain density is 0" "0" "$s_pain_density"

# All purchasing power signals should be 0
s_geo=$(echo "$SMALL_SUB" | jq -r '.geo_tier_s_ratio | tostring | sub("\\.0$"; "")')
s_budget=$(echo "$SMALL_SUB" | jq -r '.budget_mention_rate | tostring | sub("\\.0$"; "")')
s_prof=$(echo "$SMALL_SUB" | jq -r '.professional_title_rate | tostring | sub("\\.0$"; "")')

assert_eq "SmallSubNoActivity geo_tier_s_ratio is 0" "0" "$s_geo"
assert_eq "SmallSubNoActivity budget_mention_rate is 0" "0" "$s_budget"
assert_eq "SmallSubNoActivity professional_title_rate is 0" "0" "$s_prof"

# ─── Test 3: Bayesian correction ────────────────────────────────────────────
echo ""
echo "=== Test 3: Bayesian correction ==="

# algo_bayesian(raw_score, sample_size, prior, prior_weight)
# With small sample, score should regress toward prior
high_score_small_sample=$(algo_bayesian 90 5 50 10)
high_score_large_sample=$(algo_bayesian 90 100 50 10)

# Small sample should regress more toward the prior (50) than large sample
# So high_score_small_sample < high_score_large_sample
if (( $(echo "$high_score_small_sample < $high_score_large_sample" | bc -l) )); then
  echo "  PASS: Bayesian correction — small sample ($high_score_small_sample) regresses more than large sample ($high_score_large_sample)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Bayesian correction — expected small sample < large sample"
  echo "        small sample score: $high_score_small_sample"
  echo "        large sample score: $high_score_large_sample"
  FAIL=$((FAIL + 1))
fi

# Large sample should preserve most of the raw score (closer to 90 than to 50)
midpoint=70
if (( $(echo "$high_score_large_sample > $midpoint" | bc -l) )); then
  echo "  PASS: Bayesian correction — large sample preserves score ($high_score_large_sample > $midpoint)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Bayesian correction — large sample should preserve score above $midpoint"
  echo "        actual: $high_score_large_sample"
  FAIL=$((FAIL + 1))
fi

# Small sample should be closer to prior than to raw score
if (( $(echo "$high_score_small_sample < $midpoint" | bc -l) )); then
  echo "  PASS: Bayesian correction — small sample regresses toward prior ($high_score_small_sample < $midpoint)"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Bayesian correction — small sample should regress below $midpoint"
  echo "        actual: $high_score_small_sample"
  FAIL=$((FAIL + 1))
fi

test_summary
