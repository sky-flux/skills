#!/usr/bin/env bash
# Algorithm Scheduling Module
# Pure computation functions for intelligent resource allocation and anomaly detection.
# All functions operate on JSON input and produce JSON output.

# ─── UCB1 Bandit ─────────────────────────────────────────────────────────────
# UCB1 = avg_reward + 2 * sqrt(ln(total_scans) / scans)
# Balances exploitation (high avg_reward) with exploration (low scans).
# Args: stats_json (array of {name, avg_reward, scans}), total_scans
# Returns: JSON array sorted by priority desc
algo_ucb1_priority() {
  local stats_json="$1"
  local total_scans="$2"

  echo "$stats_json" | jq --argjson total "$total_scans" '
    [.[] | . + {
      priority: (.avg_reward + 2 * (($total | log) / .scans | sqrt))
    }] | sort_by(-.priority)
  '
}

# ─── Burst Detection ────────────────────────────────────────────────────────
# For each keyword, compute mean+std of all-but-last values,
# z-score of last value. burst = z > threshold.
# Args: history_json (array of {keyword, counts[]}), threshold
# Returns: JSON array of {keyword, z_score, burst}
algo_burst_detect() {
  local history_json="$1"
  local threshold="$2"

  echo "$history_json" | jq --argjson thresh "$threshold" '
    [.[] | {
      keyword: .keyword,
      z_score: (
        (.counts | length) as $n |
        (.counts[0:$n-1]) as $baseline |
        (.counts[$n-1]) as $last |
        ($baseline | add / length) as $mean |
        (($baseline | map(. - $mean | . * .) | add / length) | sqrt) as $std |
        if $std == 0 then 0
        else (($last - $mean) / $std)
        end
      ),
      burst: (
        (.counts | length) as $n |
        (.counts[0:$n-1]) as $baseline |
        (.counts[$n-1]) as $last |
        ($baseline | add / length) as $mean |
        (($baseline | map(. - $mean | . * .) | add / length) | sqrt) as $std |
        if $std == 0 then false
        else (($last - $mean) / $std) > $thresh
        end
      )
    }]
  '
}

# ─── Z-Score ─────────────────────────────────────────────────────────────────
# (value - mean) / stddev
# Args: value, mean, stddev
# Returns: z-score formatted to 2 decimal places
algo_zscore() {
  local value="$1"
  local mean="$2"
  local stddev="$3"

  awk "BEGIN { printf \"%.2f\", ($value - $mean) / $stddev }"
}

# ─── SMA Decomposition ──────────────────────────────────────────────────────
# Simple Moving Average trend decomposition.
# trend[i] = average of window centered on i (or partial at edges)
# residual[i] = original[i] - trend[i]
# Args: weekly_json (array of numbers), window (integer)
# Returns: JSON {trend: [...], residual: [...]}
algo_sma_decompose() {
  local weekly_json="$1"
  local window="$2"

  echo "$weekly_json" | jq --argjson w "$window" '
    . as $data |
    length as $n |
    ($w / 2 | floor) as $half |
    [range($n) | . as $i |
      ([range(
        (if ($i - $half) < 0 then 0 else ($i - $half) end);
        (if ($i + $half + 1) > $n then $n else ($i + $half + 1) end)
      ) | $data[.]] | add / length)
    ] as $trend |
    {
      trend: $trend,
      residual: [range($n) | $data[.] - $trend[.]]
    }
  '
}

# ─── Sequential Pattern Mining ───────────────────────────────────────────────
# Extract bigram transitions from event sequences, count support.
# Args: timeline_json (array of {user, events[]}), min_support (float 0-1)
# Returns: JSON array of {pattern, count, support} where support >= min_support
algo_sequential_pattern() {
  local timeline_json="$1"
  local min_support="$2"

  echo "$timeline_json" | jq --argjson min_sup "$min_support" '
    length as $total |
    [.[] | .events as $ev |
      [range(($ev | length) - 1) |
        "\($ev[.])->\($ev[. + 1])"
      ] | unique
    ] | flatten |
    group_by(.) |
    map({
      pattern: .[0],
      count: length,
      support: (length / $total)
    }) |
    [.[] | select(.support >= $min_sup)] |
    sort_by(-.support)
  '
}
