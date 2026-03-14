#!/usr/bin/env bash
set -euo pipefail

# ─── Constants ────────────────────────────────────────────────────────────────
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
BASE_URL="https://www.reddit.com"
RATE_LIMIT_MIN=10
SLEEP_BETWEEN=3

# ─── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="${REDDIT_DATA_DIR:-$PWD/.reddit-leads}"
STATE_FILE="$DATA_DIR/.reddit.json"

# ─── Helpers ──────────────────────────────────────────────────────────────────

log() {
  echo "[$(date '+%H:%M:%S')] $*" >&2
}

ensure_jq() {
  if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed." >&2
    echo "Install it with: brew install jq" >&2
    exit 1
  fi
}

ensure_data_dir() {
  mkdir -p "$DATA_DIR/reports"
  mkdir -p "$DATA_DIR/opportunities"
  mkdir -p "$DATA_DIR/archive"

  local gitignore="$PWD/.gitignore"
  if [[ -f "$gitignore" ]]; then
    if ! grep -qF ".reddit-leads/" "$gitignore"; then
      log "Warning: .reddit-leads/ is not in .gitignore — consider adding it to avoid committing local data"
    fi
  else
    log "Warning: No .gitignore found — consider creating one and adding .reddit-leads/"
  fi
}

init_state() {
  ensure_data_dir
  cat > "$STATE_FILE" <<'EOF'
{"seen_posts":{},"watched_threads":{},"opportunities":{},"products_seen":{},"influencers":{},"community_overlap":{},"subreddit_quality":{}}
EOF
  log "State initialized at $STATE_FILE"
}

reddit_curl() {
  local url="$1"
  shift
  local retries=0
  local max_retries=2

  while true; do
    local tmpfile
    tmpfile=$(mktemp)
    local headers_file
    headers_file=$(mktemp)

    local http_code
    http_code=$(curl -s -o "$tmpfile" -D "$headers_file" -w "%{http_code}" \
      -H "User-Agent: $UA" \
      -H "Accept: application/json" \
      --max-redirs 0 \
      "$url" "$@")

    local remaining
    remaining=$(grep -i "x-ratelimit-remaining:" "$headers_file" 2>/dev/null | awk '{print $2}' | tr -d '\r' || echo "")

    case "$http_code" in
      200)
        cat "$tmpfile"
        rm -f "$tmpfile" "$headers_file"
        sleep "$SLEEP_BETWEEN"
        return 0
        ;;
      302)
        local location
        location=$(grep -i "^location:" "$headers_file" | awk '{print $2}' | tr -d '\r')
        log "Redirect to: $location — following manually"
        rm -f "$tmpfile" "$headers_file"
        url="$location"
        continue
        ;;
      429)
        local retry_after
        retry_after=$(grep -i "retry-after:" "$headers_file" 2>/dev/null | awk '{print $2}' | tr -d '\r' || echo "60")
        retry_after="${retry_after:-60}"
        log "Rate limited (429). Sleeping ${retry_after}s before retry..."
        rm -f "$tmpfile" "$headers_file"
        sleep "$retry_after"
        retries=$((retries + 1))
        if [[ $retries -gt $max_retries ]]; then
          log "Max retries exceeded on 429"
          return 1
        fi
        continue
        ;;
      403)
        local body
        body=$(cat "$tmpfile")
        rm -f "$tmpfile" "$headers_file"
        if echo "$body" | grep -qiE "private|quarantine"; then
          log "Subreddit is private or quarantined (403)"
          return 2
        fi
        log "403 Forbidden — switching UA and retrying once"
        retries=$((retries + 1))
        if [[ $retries -gt 1 ]]; then
          log "Still 403 after UA switch"
          return 1
        fi
        UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
        continue
        ;;
      404)
        log "404 Not Found: $url"
        rm -f "$tmpfile" "$headers_file"
        return 1
        ;;
      5*)
        log "Server error $http_code: $url"
        rm -f "$tmpfile" "$headers_file"
        return 1
        ;;
      *)
        log "Unexpected HTTP $http_code: $url"
        rm -f "$tmpfile" "$headers_file"
        return 1
        ;;
    esac
  done
}

read_state() {
  jq -r "$1" "$STATE_FILE" 2>/dev/null
}

update_state() {
  local tmp
  tmp=$(mktemp)
  jq "$1" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

# ─── Enrichment pipeline ──────────────────────────────────────────────────────

enrich_posts() {
  # Args: campaign sort subreddits_array (as JSON string)
  local campaign="${1:-unknown}"
  local sort="${2:-new}"
  local subreddits_json="${3:-[]}"

  # Load intent keywords — multi-language, fall back to English hardcoded
  local keywords_file="$SKILL_DIR/references/intent_keywords.json"
  local keyword_regex
  if [[ -f "$keywords_file" ]]; then
    # Flatten all keyword arrays across all languages into one regex
    keyword_regex=$(jq -r '
      [ .languages | to_entries[] | .value | to_entries[] | .value[] ] |
      map(gsub("(?i)"; "")) |
      join("|")
    ' "$keywords_file" 2>/dev/null || true)
  fi
  # Fallback if file missing or jq failed
  if [[ -z "$keyword_regex" ]]; then
    keyword_regex="willing to pay|budget for|looking for a tool|anyone know|recommend a|frustrated with|struggling with|switching from|need alternative"
  fi

  local now_ts
  now_ts=$(date +%s)

  jq \
    --arg campaign "$campaign" \
    --arg sort "$sort" \
    --argjson subreddits "$subreddits_json" \
    --argjson now "$now_ts" \
    --arg keyword_regex "$keyword_regex" \
    '
    # Spam-username pattern helper (jq test is PCRE)
    def is_spam_author:
      test("^[A-Z][a-z]+-[A-Z][a-z]+[0-9]+$");

    # Question-title pattern
    def is_question_title:
      test("\\?$|^How |^What |^Why |^Where |^When |^Which |^Who |^Is |^Are |^Can |^Should |^Would |^Does |^Do |^Has |^Have |^Did "; "i");

    # Negative-sentiment words
    def has_pain(text):
      text | test("frustrat|disappoint|terrible|awful|waste of|regret|mistake|fail|broke|crash|bug|lost|scam|ripoff|overcharg"; "i");

    # Time window from age_hours
    def time_window(h):
      if h < 1 then "URGENT"
      elif h < 4 then "HOT"
      elif h < 24 then "WARM"
      elif h < 72 then "COOL"
      else "OLD"
      end;

    # Clean posts (non-spam, non-deleted, non-removed, non-negative-score)
    .data.children as $raw |
    ($raw | length) as $total_raw |

    ($raw | [.[] | select(
      .data.score >= 0 and
      .data.author != "[deleted]" and
      .data.selftext != "[removed]" and
      .data.removed_by_category == null and
      (.data.selftext == "" or true) and
      (.data.author | is_spam_author | not)
    )]) as $clean |

    ($clean | length) as $total_after |

    {
      meta: {
        mode: "fetch",
        campaign: $campaign,
        sort: $sort,
        timestamp: $now,
        subreddits_scanned: $subreddits,
        total_raw: $total_raw,
        total_after_filter: $total_after,
        errors: []
      },
      posts: [
        $clean[] |
        .data as $p |
        (($now - ($p.created_utc // $now)) / 3600 * 100 | round / 100) as $age_hours |
        (($p.title // "") + " " + ($p.selftext // "")) as $full_text |
        {
          id: $p.id,
          subreddit: $p.subreddit,
          title: $p.title,
          selftext: $p.selftext,
          author: $p.author,
          score: $p.score,
          num_comments: $p.num_comments,
          upvote_ratio: $p.upvote_ratio,
          created_utc: $p.created_utc,
          permalink: $p.permalink,
          link_flair_text: $p.link_flair_text,
          is_self: $p.is_self,
          num_crossposts: $p.num_crossposts,
          subreddit_subscribers: $p.subreddit_subscribers,
          _jq_enriched: {
            age_hours: $age_hours,
            time_window: time_window($age_hours),
            is_question: ($p.title | is_question_title),
            tags: (
              [ if ($p.title | is_question_title) then "question" else empty end,
                if has_pain($full_text) then "pain" else empty end,
                if ($full_text | test($keyword_regex; "i")) then "request" else empty end
              ]
            ),
            intent_keywords_matched: [
              $full_text |
              [ scan($keyword_regex) ] |
              .[] |
              ascii_downcase
            ] | unique,
            negative_signals: [
              $full_text |
              [ scan("frustrat|disappoint|terrible|awful|waste of|regret|mistake|fail|broke|crash|bug|lost|scam|ripoff|overcharg"; "i") ] |
              .[] |
              ascii_downcase
            ] | unique,
            tech_stack: [
              $full_text |
              [ scan("react|next\\.js|vue|angular|node|python|django|rails|stripe|aws|vercel|supabase|firebase|postgres|mongo|redis|docker|kubernetes|tailwind|typescript|graphql|prisma|drizzle"; "i") ] |
              .[] |
              ascii_downcase
            ] | unique,
            company_stage: (
              [ $full_text | scan("\\$[0-9]+k? (?:MRR|ARR|revenue)"; "i"),
                $full_text | scan("(?:solo|[0-9]+) person team"; "i")
              ] | unique
            ),
            geo_signals: [
              $full_text |
              [ scan("US|UK|Europe|India|Australia|Canada|Germany|France|Brazil|Asia|LATAM|APAC|EMEA") ] |
              .[]
            ] | unique,
            revenue_mentions: [
              $full_text |
              [ scan("\\$[0-9]+k? (?:MRR|ARR|revenue)"; "i") ] |
              .[]
            ] | unique,
            is_spam: ($p.author | is_spam_author),
            engagement_per_hour: (
              (($p.score // 0) + ($p.num_comments // 0)) /
              (if $age_hours < 0.1 then 0.1 else $age_hours end) * 100 | round / 100
            )
          }
        }
      ]
    }
    '
}

# ─── Mode stubs ───────────────────────────────────────────────────────────────

mode_fetch() {
  ensure_jq
  ensure_data_dir

  local sort="new"
  local pages=2
  local campaign="global_english"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --sort)     sort="$2";     shift 2 ;;
      --pages)    pages="$2";    shift 2 ;;
      --campaign) campaign="$2"; shift 2 ;;
      *) log "Unknown option: $1"; shift ;;
    esac
  done

  local config_file="$SKILL_DIR/references/subreddits.json"
  if [[ ! -f "$config_file" ]]; then
    log "Error: subreddits.json not found at $config_file"
    exit 1
  fi

  # Read subreddits for this campaign, excluding search_only entries
  local subreddits_json
  subreddits_json=$(jq -r --arg campaign "$campaign" --arg sort "$sort" '
    .campaigns[$campaign].subreddits //
    error("campaign not found: \($campaign)")
  ' "$config_file")

  # Filter out search_only (sort_modes contains only search_only)
  local active_subreddits
  active_subreddits=$(echo "$subreddits_json" | jq '[.[] | select(.sort_modes | map(. == "search_only") | all | not)]')

  local subreddit_names
  subreddit_names=$(echo "$active_subreddits" | jq -r '[.[].name] | join("+")' 2>/dev/null)

  if [[ -z "$subreddit_names" ]]; then
    log "No active (non-search_only) subreddits found for campaign: $campaign"
    exit 1
  fi

  local subreddits_array
  subreddits_array=$(echo "$active_subreddits" | jq '[.[].name]')

  log "Campaign: $campaign | Sort: $sort | Pages: $pages"
  log "Subreddits: $subreddit_names"

  local url="${BASE_URL}/r/${subreddit_names}/${sort}.json?limit=100"
  local after=""
  local page=1
  local all_posts="[]"
  local errors="[]"

  while [[ $page -le $pages ]]; do
    local fetch_url="$url"
    if [[ -n "$after" ]]; then
      fetch_url="${url}&after=${after}"
    fi

    log "Fetching page $page/$pages: $fetch_url"

    local raw_json
    if ! raw_json=$(reddit_curl "$fetch_url" 2>/tmp/reddit_curl_err); then
      local err_msg
      err_msg=$(cat /tmp/reddit_curl_err 2>/dev/null || echo "curl failed")
      log "Error fetching page $page: $err_msg"
      errors=$(echo "$errors" | jq --arg e "page $page: $err_msg" '. + [$e]')
      break
    fi

    # Validate JSON
    if ! echo "$raw_json" | jq empty 2>/dev/null; then
      log "Invalid JSON on page $page"
      errors=$(echo "$errors" | jq '. + ["invalid JSON on page '"$page"'"]')
      break
    fi

    # Collect posts from this page
    local page_posts
    page_posts=$(echo "$raw_json" | jq '[.data.children[].data.id]' 2>/dev/null || echo "[]")
    all_posts=$(echo "$all_posts $page_posts" | jq -s 'add')

    # Get next cursor
    after=$(echo "$raw_json" | jq -r '.data.after // empty')
    if [[ -z "$after" ]]; then
      log "No more pages after page $page"
      break
    fi

    page=$((page + 1))
  done

  # Re-fetch all pages as one enrichment pass — actually we need to pipe fresh raw JSON
  # through enrich_posts. For multi-page, we need to re-fetch from a combined listing.
  # Strategy: fetch all pages, accumulate raw children, then enrich in one shot.

  # Reset and do a proper accumulating fetch
  after=""
  page=1
  local tmp_combined
  tmp_combined=$(mktemp)
  echo '{"kind":"Listing","data":{"children":[]}}' > "$tmp_combined"

  while [[ $page -le $pages ]]; do
    local fetch_url="$url"
    if [[ -n "$after" ]]; then
      fetch_url="${url}&after=${after}"
    fi

    local raw_json
    if ! raw_json=$(reddit_curl "$fetch_url" 2>/dev/null); then
      log "Error fetching page $page (skipping)"
      break
    fi

    if ! echo "$raw_json" | jq empty 2>/dev/null; then
      log "Invalid JSON on page $page (skipping)"
      break
    fi

    # Merge children into combined
    local merged
    merged=$(jq -s '
      .[0].data.children += .[1].data.children |
      .[0]
    ' "$tmp_combined" <(echo "$raw_json"))
    echo "$merged" > "$tmp_combined"

    after=$(echo "$raw_json" | jq -r '.data.after // empty')
    if [[ -z "$after" ]]; then
      break
    fi
    page=$((page + 1))
  done

  # Run enrichment
  local enriched_json
  enriched_json=$(enrich_posts "$campaign" "$sort" "$subreddits_array" < "$tmp_combined")
  rm -f "$tmp_combined"

  # Save output
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local report_file="$DATA_DIR/reports/fetch_${campaign}_${sort}_${timestamp}.json"
  echo "$enriched_json" > "$report_file"
  log "Report saved: $report_file"

  # Update seen_posts in state
  if [[ -f "$STATE_FILE" ]]; then
    local new_ids
    new_ids=$(echo "$enriched_json" | jq '[.posts[].id]')
    update_state --argjson ids "$new_ids" '
      .seen_posts as $seen |
      reduce $ids[] as $id (.; .seen_posts[$id] = (now | floor))
    '
    log "Updated seen_posts with $(echo "$new_ids" | jq length) post IDs"
  fi

  # Print summary
  echo "$enriched_json" | jq '{
    campaign: .meta.campaign,
    sort: .meta.sort,
    total_raw: .meta.total_raw,
    total_after_filter: .meta.total_after_filter,
    posts_by_time_window: (.posts | group_by(._jq_enriched.time_window) | map({(.[0]._jq_enriched.time_window): length}) | add // {}),
    top_posts: [.posts | sort_by(-.score) | .[0:5] | .[] | {id, title: .title[0:60], score, tags: ._jq_enriched.tags}]
  }'
}
mode_comments()   { log "TODO: comments"; }
mode_search()     { log "TODO: search"; }
mode_discover()   { log "TODO: discover"; }
mode_profile()    { log "TODO: profile"; }
mode_crosspost()  { log "TODO: crosspost"; }
mode_stickied()   { log "TODO: stickied"; }
mode_firehose()   { log "TODO: firehose"; }
mode_export()     { log "TODO: export"; }
mode_cleanup()    { log "TODO: cleanup"; }
mode_diagnose() {
  local results="{}"

  # Check jq
  if command -v jq &>/dev/null; then
    results=$(echo "$results" | jq --arg v "$(jq --version 2>&1)" '.jq = {status: "ok", version: $v}')
  else
    results=$(echo "$results" | jq '.jq = {status: "missing", fix: "brew install jq"}')
  fi

  # Check curl
  if command -v curl &>/dev/null; then
    results=$(echo "$results" | jq --arg v "$(curl --version 2>&1 | head -1)" '.curl = {status: "ok", version: $v}')
  else
    results=$(echo "$results" | jq '.curl = {status: "missing"}')
  fi

  # Check network + rate limit
  local header_file
  header_file=$(mktemp)
  trap "rm -f '$header_file'" RETURN
  local http_code
  http_code=$(curl -s -w "%{http_code}" -o /dev/null -D "$header_file" \
    -H "User-Agent: $UA" \
    "https://www.reddit.com/r/SaaS/new.json?limit=1" 2>/dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local remaining reset
    remaining=$(grep -i "x-ratelimit-remaining" "$header_file" 2>/dev/null | tr -d '\r' | awk '{print $2}' || echo "unknown")
    reset=$(grep -i "x-ratelimit-reset" "$header_file" 2>/dev/null | tr -d '\r' | awk '{print $2}' || echo "unknown")
    results=$(echo "$results" | jq --arg r "$remaining" --arg s "$reset" \
      '.network = {status: "ok"} | .rate_limit = {remaining: $r, reset_seconds: $s}')
  else
    results=$(echo "$results" | jq --arg c "$http_code" '.network = {status: "error", http_code: $c}')
  fi

  # Check config
  local config_file="$SKILL_DIR/references/subreddits.json"
  if [ -f "$config_file" ]; then
    local campaign_count
    campaign_count=$(jq '.campaigns | keys | length' "$config_file" 2>/dev/null || echo "0")
    results=$(echo "$results" | jq --arg c "$campaign_count" '.config = {status: "ok", campaigns: ($c | tonumber)}')
  else
    results=$(echo "$results" | jq '.config = {status: "missing", path: "references/subreddits.json"}')
  fi

  # Check data dir
  if [ -d "$DATA_DIR" ]; then
    local size
    size=$(du -sk "$DATA_DIR" 2>/dev/null | awk '{print $1}')
    results=$(echo "$results" | jq --arg s "$size" '.data_dir = {status: "ok", size_kb: ($s | tonumber)}')
  else
    results=$(echo "$results" | jq '.data_dir = {status: "not_initialized", fix: "run any reddit.sh command to auto-create"}')
  fi

  echo "$results" | jq .
}
mode_duplicates() { log "TODO: duplicates"; }
mode_wiki()       { log "TODO: wiki"; }
mode_stats()      { log "TODO: stats"; }

# ─── Main dispatch ────────────────────────────────────────────────────────────

# Guard: only dispatch when executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    fetch|comments|search|discover|profile|crosspost|stickied|firehose|export|cleanup|diagnose|duplicates|wiki|stats)
      mode="$1"; shift; "mode_$mode" "$@" ;;
    *)
      echo "Usage: reddit.sh <mode> [options]"
      echo "Modes: fetch comments search discover profile crosspost stickied firehose export cleanup diagnose duplicates wiki stats"
      exit 1
      ;;
  esac
fi
