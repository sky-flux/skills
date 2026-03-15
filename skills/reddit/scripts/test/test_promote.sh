#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

echo ""
echo "=== Promote Mode Tests ==="

# ─── Setup: temp data dir with discovered subs and subreddits.json ──────────

REDDIT_DATA_DIR=$(mktemp -d)
trap "rm -rf '$REDDIT_DATA_DIR'" EXIT
export REDDIT_DATA_DIR

mkdir -p "$REDDIT_DATA_DIR/reports" "$REDDIT_DATA_DIR/opportunities" "$REDDIT_DATA_DIR/archive"

# Create a temporary subreddits.json to avoid modifying the real one
SUBS_DIR=$(mktemp -d)
SUBS_FILE="$SUBS_DIR/subreddits.json"
export SUBREDDITS_FILE="$SUBS_FILE"

cat > "$SUBS_FILE" <<'EOF'
{
  "campaigns": {
    "test_campaign": {
      "subreddits": [
        {"name": "SaaS", "sort_modes": ["new", "hot"]}
      ]
    }
  }
}
EOF

# Create discovered_subs.json
DISCOVERED_FILE="$REDDIT_DATA_DIR/discovered_subs.json"
cat > "$DISCOVERED_FILE" <<'EOF'
{
  "discovered": {
    "test_campaign": [
      {
        "name": "microSaaS",
        "sort_modes": ["new"],
        "subscribers": 15000,
        "_auto_added": true,
        "_added_date": "2026-03-10",
        "_discovery_score": 8.5,
        "_source": "keyword_search"
      },
      {
        "name": "indiehackers",
        "sort_modes": ["hot"],
        "subscribers": 50000,
        "_auto_added": true,
        "_added_date": "2026-03-12",
        "_discovery_score": 7.0,
        "_source": "overlap"
      }
    ]
  }
}
EOF

# Create config.json so ensure_data_dir doesn't fail
cat > "$REDDIT_DATA_DIR/config.json" <<'EOF'
{
  "output_language": "en",
  "focus_industries": [],
  "excluded_subreddits": [],
  "score_threshold": 7,
  "max_build_complexity": "Heavy",
  "currency_display": "USD",
  "sub_quality_threshold": 7.0
}
EOF

# ─── Test group 1: promote a discovered sub ──────────────────────────────────
echo ""
echo "--- Test group 1: promote a discovered sub ---"

promote_output=$(bash "$REDDIT_SH" promote microSaaS --campaign test_campaign 2>/dev/null)

# Check the promoted sub data is returned (without internal fields)
promoted_name=$(echo "$promote_output" | jq -r '.name')
assert_eq "promoted sub name is microSaaS" "microSaaS" "$promoted_name"

has_auto_added=$(echo "$promote_output" | jq 'has("_auto_added")')
assert_eq "promoted sub has no _auto_added field" "false" "$has_auto_added"

has_source=$(echo "$promote_output" | jq 'has("_source")')
assert_eq "promoted sub has no _source field" "false" "$has_source"

# Verify subreddits.json was updated
subs_count=$(jq '.campaigns.test_campaign.subreddits | length' "$SUBS_FILE")
assert_eq "subreddits.json now has 2 subs" "2" "$subs_count"

added_sub=$(jq -r '.campaigns.test_campaign.subreddits[1].name' "$SUBS_FILE")
assert_eq "second sub in config is microSaaS" "microSaaS" "$added_sub"

# Verify discovered_subs.json was updated (microSaaS removed)
remaining=$(jq '.discovered.test_campaign | length' "$DISCOVERED_FILE")
assert_eq "discovered subs has 1 remaining" "1" "$remaining"

remaining_name=$(jq -r '.discovered.test_campaign[0].name' "$DISCOVERED_FILE")
assert_eq "remaining discovered sub is indiehackers" "indiehackers" "$remaining_name"

# ─── Test group 2: promote non-existent sub ──────────────────────────────────
echo ""
echo "--- Test group 2: promote non-existent sub ---"

bad_output=$(bash "$REDDIT_SH" promote nonexistent --campaign test_campaign 2>&1 || true)
assert_contains "error for missing sub" "$bad_output" "not found in discovered subs"

# ─── Test group 3: promote with missing args ─────────────────────────────────
echo ""
echo "--- Test group 3: promote with missing args ---"

no_args_output=$(bash "$REDDIT_SH" promote 2>&1 || true)
assert_contains "usage message for missing args" "$no_args_output" "Usage"

# ─── Test group 4: promote from non-existent campaign ────────────────────────
echo ""
echo "--- Test group 4: promote from non-existent campaign ---"

bad_campaign=$(bash "$REDDIT_SH" promote indiehackers --campaign fake_campaign 2>&1 || true)
assert_contains "error for missing campaign" "$bad_campaign" "not found in discovered subs"

# Cleanup temp subs dir
rm -rf "$SUBS_DIR"

test_summary
