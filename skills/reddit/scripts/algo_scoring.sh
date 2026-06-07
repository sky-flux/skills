#!/usr/bin/env bash
# Algorithm Scoring: Bayesian Average, Wilson Score, EMA, Influence Score, Sub Quality Score
# Sourced by reddit.sh — not executed directly


# Bayesian average: regresses raw score toward global average
# Usage: algo_bayesian <raw_score> <sample_size> <global_avg> [confidence=15]
algo_bayesian() {
  local raw="$1" sample_size="$2" global_avg="$3" confidence="${4:-15}"
  awk -v r="$raw" -v n="$sample_size" -v avg="$global_avg" -v c="$confidence" \
    'BEGIN { printf "%.2f\n", (c * avg + r * n) / (c + n) }'
}

# Wilson score lower bound (95% confidence, z=1.96)
# Usage: algo_wilson <positive_votes> <total_votes>
algo_wilson() {
  local positive="$1" total="$2"
  awk -v p="$positive" -v n="$total" 'BEGIN {
    z = 1.96; if (n == 0) { print "0.00"; exit }
    phat = p / n; denom = 1 + z*z/n
    center = phat + z*z/(2*n)
    spread = z * sqrt((phat*(1-phat) + z*z/(4*n)) / n)
    lower = (center - spread) / denom
    if (lower < 0) lower = 0
    printf "%.4f\n", lower
  }'
}

# Exponential moving average update
# Usage: algo_ema_update <current_value> <old_ema> [alpha=0.3]
algo_ema_update() {
  local current="$1" old_ema="$2" alpha="${3:-0.3}"
  awk -v c="$current" -v old="$old_ema" -v a="$alpha" \
    'BEGIN { printf "%.2f\n", a * c + (1 - a) * old }'
}

# Influence score from user profile JSON
# Usage: algo_influence '<json_profile>'
algo_influence() {
  local profile_json="$1"
  echo "$profile_json" | jq -r '
    ((.link_karma // 1) + (.comment_karma // 1)) as $karma |
    ((.subreddits_active // []) | length | if . == 0 then 1 else . end) as $subs |
    ((.posts // 1) | if . == 0 then 1 else . end) as $posts |
    (($karma | log / (10 | log)) * $subs * ($posts | sqrt)) |
    . * 100 | round / 100
  '
}

score_sub_quality() {
  local sub_data="${1:?}" global_avg="${2:-5.0}"
  echo "$sub_data" | jq --argjson avg "$global_avg" '
    # Dimension 1: Pain Density (0.25)
    (if .sample_posts == 0 then 0 else (.pain_posts / .sample_posts) * 10 end) as $d1 |
    # Dimension 2: Purchasing Power (0.20)
    (((.geo_tier_s_ratio // 0) * 3 + (.budget_mention_rate // 0) * 2 +
      ((10 - (.flesch_kincaid_avg // 5)) | if . < 0 then 0 else . end) * 0.5 +
      (.professional_title_rate // 0) * 2) / 3 |
      if . > 10 then 10 elif . < 0 then 0 else . end) as $d2 |
    # Dimension 3: Activity Level (0.15)
    ((.posts_per_week // 0) * (((.subscribers // 1) | log) / (10 | log)) / 10 |
      if . > 10 then 10 else . end) as $d3 |
    # Dimension 4: Competitor Discussion Density (0.15)
    (if .sample_posts == 0 then $avg
     else ((.competitor_posts // 0) / .sample_posts) * 30 |
       if . > 10 then 10 else . end
     end) as $d4 |
    # Dimension 5: Engagement Depth (0.10)
    (((.avg_comments // 0) / 5) | if . > 10 then 10 else . end) as $d5 |
    # Dimension 6: Growth Rate (0.10)
    (if (.older_post_rate // 0) == 0 then $avg
     else (((.recent_post_rate // 0) - (.older_post_rate // 0)) / (.older_post_rate // 1) * 10 + 5) |
       if . > 10 then 10 elif . < 0 then 0 else . end
     end) as $d6 |
    # Dimension 7: Solo Dev Friendliness (0.05)
    (((.small_team_mentions // 0) * 3 + (.self_serve_signals // 0) * 3 +
      (1 - (.compliance_mentions // 0)) * 2) / 3 |
      if . > 10 then 10 elif . < 0 then 0 else . end) as $d7 |
    ($d1 * 0.25 + $d2 * 0.20 + $d3 * 0.15 + $d4 * 0.15 + $d5 * 0.10 + $d6 * 0.10 + $d7 * 0.05) as $raw |
    # Bayesian correction C=15
    (15 * $avg + $raw * (.sample_posts // 1)) / (15 + (.sample_posts // 1)) |
    . * 100 | round / 100
  '
}
