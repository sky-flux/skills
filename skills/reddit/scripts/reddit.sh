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
DATA_DIR="${REDDIT_DATA_DIR:-$PWD/.reddit}"
STATE_FILE="$DATA_DIR/.reddit.json"
CONFIG_FILE="$DATA_DIR/config.json"

# ─── Algorithm Modules ────────────────────────────────────────────────────────
for _algo_module in "$SCRIPT_DIR"/algo_*.sh; do
  [[ -f "$_algo_module" ]] && source "$_algo_module"
done

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
    if ! grep -qF ".reddit/" "$gitignore"; then
      log "Warning: .reddit/ is not in .gitignore — consider adding it to avoid committing local data"
    fi
  else
    log "Warning: No .gitignore found — consider creating one and adding .reddit/"
  fi

  # Initialize config if missing
  if [[ ! -f "${DATA_DIR}/config.json" ]]; then
    init_config
  fi
}

init_state() {
  ensure_data_dir
  cat > "$STATE_FILE" <<'EOF'
{"seen_posts":{},"watched_threads":{},"opportunities":{},"products_seen":{},"influencers":{},"community_overlap":{},"subreddit_quality":{},"candidate_subs":[],"rejected_subs":[],"keyword_frequencies":{},"sub_clusters":[],"user_intent_timeline":{}}
EOF
  log "State initialized at $STATE_FILE"
}

init_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" <<'CONF'
{
  "output_language": "en",
  "focus_industries": [],
  "excluded_subreddits": [],
  "score_threshold": 7,
  "max_build_complexity": "Heavy",
  "currency_display": "USD",
  "sub_quality_threshold": 7.0
}
CONF
    log "Default config created at $CONFIG_FILE"
  fi
}

read_config() {
  local key="$1"
  local default="${2:-}"
  if [[ -f "$CONFIG_FILE" ]]; then
    local val
    val=$(jq -r --arg k "$key" '.[$k] // empty' "$CONFIG_FILE" 2>/dev/null)
    if [[ -n "$val" && "$val" != "null" ]]; then
      echo "$val"
      return
    fi
  fi
  echo "$default"
}

update_config() {
  local tmp
  tmp=$(mktemp)
  jq "$1" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
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

# ─── Helper functions ─────────────────────────────────────────────────────────

watch_check() {
  ensure_jq
  if [ ! -f "$STATE_FILE" ]; then return 0; fi
  local now; now=$(date +%s)
  local threads
  threads=$(jq -r --arg now "$now" '.watched_threads // {} | to_entries[] | select(.value.watch_until > ($now | tonumber)) | [.key, .value.subreddit, .value.last_comment_count] | @tsv' "$STATE_FILE")
  if [ -z "$threads" ]; then log "No active watched threads"; return 0; fi
  local updates="[]"
  while IFS=$'\t' read -r post_id subreddit last_count; do
    local response
    response=$(reddit_curl "${BASE_URL}/r/${subreddit}/comments/${post_id}.json?limit=1" 2>/dev/null) || continue
    local current_count
    current_count=$(echo "$response" | jq '.[0].data.children[0].data.num_comments // 0')
    if [ "$current_count" -gt "$last_count" ]; then
      local new_comments=$((current_count - last_count))
      log "Thread $post_id: $new_comments new comments"
      update_state ".watched_threads[\"$post_id\"].last_comment_count = $current_count | .watched_threads[\"$post_id\"].last_checked = $now"
      updates=$(echo "$updates" | jq --arg id "$post_id" --arg sub "$subreddit" --argjson new "$new_comments" --argjson total "$current_count" '. + [{post_id: $id, subreddit: $sub, new_comments: $new, total_comments: $total}]')
    fi
  done <<< "$threads"
  echo "$updates" | jq '{watched_updates: .}'
}

competitor_search() {
  local campaign="${1:?Usage: competitor_search <campaign>}"
  ensure_jq
  local config_file="$SKILL_DIR/references/subreddits.json"
  if [ ! -f "$config_file" ]; then log "No config"; return 1; fi
  local competitors
  competitors=$(jq -r --arg c "$campaign" '.campaigns[$c].competitors // [] | .[]' "$config_file")
  local queries
  queries=$(jq -r --arg c "$campaign" '.campaigns[$c].competitor_queries // [] | .[]' "$config_file")
  if [ -z "$competitors" ]; then log "No competitors for $campaign"; return 0; fi
  local all_results="[]"
  for comp in $competitors; do
    while IFS= read -r query_template; do
      local query
      query=$(echo "$query_template" | sed "s/{competitor}/$comp/g")
      log "Searching: $query"
      local result
      result=$(mode_search "$query" --global --sort new --time week 2>/dev/null) || continue
      all_results=$(echo "$all_results" "$result" | jq -s '.[0] + [.[1] | {query: .query, results: .results[:5]}]')
    done <<< "$queries"
  done
  echo "$all_results" | jq '{competitor_results: .}'
}

update_subreddit_quality() {
  local subreddit="$1" scanned_count="$2" opportunity_count="${3:-0}"
  if [ ! -f "$STATE_FILE" ]; then return 0; fi
  update_state "
    .subreddit_quality[\"$subreddit\"].scanned = ((.subreddit_quality[\"$subreddit\"].scanned // 0) + $scanned_count)
    | .subreddit_quality[\"$subreddit\"].opportunities = ((.subreddit_quality[\"$subreddit\"].opportunities // 0) + $opportunity_count)
    | .subreddit_quality[\"$subreddit\"].hit_rate = (
        ((.subreddit_quality[\"$subreddit\"].opportunities // 0) + $opportunity_count)
        / ([(.subreddit_quality[\"$subreddit\"].scanned // 0) + $scanned_count, 1] | max)
        * 100 | . * 100 | floor / 100
      )
  "
}

# ─── EMA tracking ─────────────────────────────────────────────────────────────

update_sub_ema() {
  local sub="${1:?}" weekly_score="${2:?}"
  if [ ! -f "$STATE_FILE" ]; then return 0; fi
  local old_ema
  old_ema=$(jq -r --arg s "$sub" '.subreddit_quality[$s].ema_score // empty' "$STATE_FILE")
  local new_ema
  if [[ -z "$old_ema" ]]; then
    new_ema="$weekly_score"
  else
    new_ema=$(awk -v c="$weekly_score" -v old="$old_ema" 'BEGIN { printf "%.2f", 0.3 * c + 0.7 * old }')
  fi
  update_state "
    .subreddit_quality[\"$sub\"].ema_score = $new_ema
    | .subreddit_quality[\"$sub\"].ema_history = ((.subreddit_quality[\"$sub\"].ema_history // []) + [$new_ema] | .[-12:])
    | .subreddit_quality[\"$sub\"].peak_score = ([.subreddit_quality[\"$sub\"].peak_score // 0, $new_ema] | max)
    | .subreddit_quality[\"$sub\"].weeks_tracked = ((.subreddit_quality[\"$sub\"].weeks_tracked // 0) + 1)
  "
}

# ─── Probing ──────────────────────────────────────────────────────────────────

probe_sample_posts() {
  local posts_file="${1:?}"
  if [[ ! -f "$posts_file" ]]; then echo '{"error":"file not found"}'; return 1; fi
  jq '
    .data.children as $raw |
    [$raw[] | select(
      .data.score >= 0 and .data.author != "[deleted]" and
      .data.selftext != "[removed]" and .data.removed_by_category == null
    )] as $clean |
    {
      sample_posts: ($clean | length),
      pain_posts: [$clean[] | select(
        (.data.title + " " + .data.selftext) |
        test("frustrat|disappoint|terrible|awful|waste|nightmare|hate|broken|struggling"; "i")
      )] | length,
      avg_comments: ([$clean[].data.num_comments] | if length == 0 then 0 else add / length end | . * 10 | round / 10),
      avg_score: ([$clean[].data.score] | if length == 0 then 0 else add / length end | . * 10 | round / 10),
      posts_per_week: ($clean | length),
      competitor_posts: [$clean[] | select((.data.title + " " + .data.selftext) | test("QuickBooks|Notion|Jira|Salesforce|HubSpot|Shopify|Adobe"; "i"))] | length
    }
  ' "$posts_file"
}

# ─── Auto-add discovered subs ────────────────────────────────────────────────

auto_add_discovered_sub() {
  local sub_name="${1:?}" campaign="${2:?}" score="${3:?}" source="${4:-manual}"
  local subscribers="${5:-0}"
  ensure_data_dir
  local discovered_file="$DATA_DIR/discovered_subs.json"
  if [[ ! -f "$discovered_file" ]]; then
    echo '{"discovered":{}}' > "$discovered_file"
  fi
  local tmp; tmp=$(mktemp)
  jq --arg c "$campaign" --arg name "$sub_name" --argjson subs "$subscribers" \
     --argjson score "$score" --arg src "$source" --arg date "$(date +%Y-%m-%d)" '
    .discovered[$c] = ((.discovered[$c] // []) + [{
      name: $name, subscribers: $subs, sort_modes: ["new"], pages: 1,
      _auto_added: true, _added_date: $date, _discovery_score: $score, _source: $src
    }]) | .discovered[$c] |= unique_by(.name)
  ' "$discovered_file" > "$tmp" && mv "$tmp" "$discovered_file"
}

# ─── Merge discovered subs ───────────────────────────────────────────────────

merge_discovered_subs() {
  local campaign="${1:?}" config_file="${2:?}"
  local discovered_file="$DATA_DIR/discovered_subs.json"
  if [[ ! -f "$discovered_file" ]]; then
    jq -r --arg c "$campaign" '.campaigns[$c].subreddits' "$config_file"
    return 0
  fi
  jq -s --arg c "$campaign" '
    (.[0].campaigns[$c].subreddits // []) as $orig |
    (.[1].discovered[$c] // []) as $disc |
    ($orig + $disc) | unique_by(.name)
  ' "$config_file" "$discovered_file"
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
mode_comments() {
  local post_id="${1:?Usage: reddit.sh comments <post_id> <subreddit>}"
  local subreddit="${2:?Usage: reddit.sh comments <post_id> <subreddit>}"
  local limit="${3:-200}"
  local depth="${4:-10}"

  ensure_jq

  local url="${BASE_URL}/r/${subreddit}/comments/${post_id}.json?limit=${limit}&depth=${depth}"
  local response
  response=$(reddit_curl "$url") || return 1

  # Parse the 2-element array [post, comments]
  # Recursively flatten comment tree
  echo "$response" | jq '
    def flatten_comments:
      . as $items
      | [ $items[]
          | select(.kind == "t1")
          | .data
          | {
              id,
              author,
              body,
              score,
              created_utc,
              depth: (.depth // 0),
              replies: (
                if .replies == "" or .replies == null then []
                else [.replies.data.children | flatten_comments]
                end
              )
            }
        ];
    {
      post: .[0].data.children[0].data | {id, subreddit, title, selftext, author, score, num_comments, permalink},
      comments: [.[1].data.children | flatten_comments] | flatten
    }
  '
}
mode_search() {
  local query=""
  local type="post"
  local global=false
  local subreddit=""
  local sort="new"
  local time_filter="week"

  while [ $# -gt 0 ]; do
    case "$1" in
      --type) type="$2"; shift 2 ;;
      --global) global=true; shift ;;
      --subreddit) subreddit="$2"; shift 2 ;;
      --sort) sort="$2"; shift 2 ;;
      --time) time_filter="$2"; shift 2 ;;
      *) query="$1"; shift ;;
    esac
  done

  if [ -z "$query" ]; then
    log "Usage: reddit.sh search <query> [--type post|user|subreddit] [--global] [--subreddit X]"
    return 1
  fi

  ensure_jq

  local encoded_query
  encoded_query=$(printf '%s' "$query" | jq -sRr @uri)

  local url
  case "$type" in
    post)
      if [ "$global" = true ] || [ -z "$subreddit" ]; then
        url="${BASE_URL}/search.json?q=${encoded_query}&sort=${sort}&t=${time_filter}&limit=100"
      else
        url="${BASE_URL}/r/${subreddit}/search.json?q=${encoded_query}&restrict_sr=on&sort=${sort}&t=${time_filter}&limit=100"
      fi
      ;;
    user)
      url="${BASE_URL}/search.json?q=${encoded_query}&type=user&limit=100"
      ;;
    subreddit)
      url="${BASE_URL}/subreddits/search.json?q=${encoded_query}&limit=100"
      ;;
    *)
      log "Unknown type: $type (use post, user, or subreddit)"
      return 1
      ;;
  esac

  local response
  response=$(reddit_curl "$url") || return 1

  echo "$response" | jq --arg q "$query" --arg t "$type" '{
    query: $q,
    type: $t,
    results: [.data.children[].data | if $t == "subreddit" then
      {name: .display_name, subscribers: .subscribers, description: .public_description, subreddit_type: .subreddit_type}
    elif $t == "user" then
      {name, link_karma, comment_karma, created_utc}
    else
      {id, subreddit, title, selftext, author, score, num_comments, permalink, created_utc}
    end]
  }'
}
mode_discover() {
  local keyword=""
  local method="keyword"

  while [ $# -gt 0 ]; do
    case "$1" in
      --deep) method="deep"; shift ;;
      --autocomplete) method="autocomplete"; shift ;;
      --from-sub) method="from-sub"; shift ;;
      --industry) method="industry"; shift ;;
      --footprint|--overlap) method="footprint"; shift ;;
      *) keyword="$1"; shift ;;
    esac
  done

  if [ -z "$keyword" ]; then
    log "Usage: reddit.sh discover <keyword> [--deep|--autocomplete|--from-sub|--industry|--footprint]"
    return 1
  fi

  ensure_jq

  case "$method" in
    keyword)
      local encoded
      encoded=$(printf '%s' "$keyword" | jq -sRr @uri)
      local response
      response=$(reddit_curl "${BASE_URL}/subreddits/search.json?q=${encoded}&limit=25") || return 1
      echo "$response" | jq --arg q "$keyword" '{
        query: $q, method: "keyword",
        results: [.data.children[].data | {
          name: .display_name, subscribers: .subscribers,
          description: .public_description, created_utc: .created_utc,
          subreddit_type: .subreddit_type,
          health_score: (if .subscribers > 10000 then "potentially_high" elif .subscribers > 1000 then "potentially_medium" else "potentially_low" end)
        }] | sort_by(-.subscribers)
      }'
      ;;
    autocomplete)
      local encoded
      encoded=$(printf '%s' "$keyword" | jq -sRr @uri)
      local response
      response=$(reddit_curl "${BASE_URL}/api/subreddit_autocomplete_v2.json?query=${encoded}&include_over_18=false") || return 1
      echo "$response" | jq --arg q "$keyword" '{
        query: $q, method: "autocomplete",
        results: [.data.children[].data | {name: .display_name, subscribers: .subscribers, description: .public_description}]
      }'
      ;;
    footprint|overlap)
      if [ -f "$STATE_FILE" ]; then
        jq --arg q "$keyword" '{query: $q, method: "overlap", community_overlap: .community_overlap, suggestion: "High overlap communities may be worth monitoring"}' "$STATE_FILE"
      else
        echo '{"error": "No state file — run fetch first to build overlap data"}'
      fi
      ;;
    deep)
      log "Deep discovery for: $keyword"
      local encoded
      encoded=$(printf '%s' "$keyword" | jq -sRr @uri)
      local response
      response=$(reddit_curl "${BASE_URL}/subreddits/search.json?q=${encoded}&limit=25") || return 1
      local subs
      subs=$(echo "$response" | jq -r '[.data.children[].data.display_name] | .[]')
      local results="[]"
      for sub in $subs; do
        log "Probing r/$sub..."
        local probe_file
        probe_file=$(mktemp)
        if reddit_curl "${BASE_URL}/r/${sub}/new.json?limit=25" > "$probe_file" 2>/dev/null; then
          local probe_data
          probe_data=$(probe_sample_posts "$probe_file" 2>/dev/null || echo '{}')
          results=$(echo "$results" | jq --arg name "$sub" --argjson data "$probe_data" '. + [{name: $name} + $data]')
        fi
        rm -f "$probe_file"
      done
      echo "$results" | jq --arg q "$keyword" '{query: $q, method: "deep", results: (. | sort_by(-.pain_posts))}'
      ;;
    from-sub)
      log "Discovering from sidebar/related of r/$keyword"
      local response
      response=$(reddit_curl "${BASE_URL}/r/${keyword}/about.json") || return 1
      echo "$response" | jq --arg sub "$keyword" '{
        query: $sub, method: "from-sub",
        subreddit: {name: .data.display_name, subscribers: .data.subscribers, description: .data.public_description},
        suggestion: "Check sidebar and wiki for related subreddits"
      }'
      ;;
    industry)
      log "Industry discovery for: $keyword"
      local encoded
      encoded=$(printf '%s' "$keyword" | jq -sRr @uri)
      local queries=("$keyword tool" "$keyword software" "$keyword alternative" "$keyword startup")
      local results="[]"
      for q in "${queries[@]}"; do
        local eq
        eq=$(printf '%s' "$q" | jq -sRr @uri)
        local response
        response=$(reddit_curl "${BASE_URL}/subreddits/search.json?q=${eq}&limit=10" 2>/dev/null) || continue
        local subs
        subs=$(echo "$response" | jq '[.data.children[].data | {name: .display_name, subscribers: .subscribers}]')
        results=$(echo "$results $subs" | jq -s 'add | unique_by(.name)')
      done
      echo "$results" | jq --arg q "$keyword" '{query: $q, method: "industry", results: (. | sort_by(-.subscribers))}'
      ;;
    *)
      log "Unknown method: $method (valid: keyword, autocomplete, deep, from-sub, industry, footprint)"
      log "Usage: reddit.sh discover <keyword> [--deep|--autocomplete|--from-sub|--industry|--footprint]"
      return 1
      ;;
  esac
}
mode_profile() {
  local username=""
  local enrich=false

  while [ $# -gt 0 ]; do
    case "$1" in
      --enrich) enrich=true; shift ;;
      *) username="$1"; shift ;;
    esac
  done

  if [ -z "$username" ]; then
    log "Usage: reddit.sh profile <username> [--enrich]"
    return 1
  fi

  ensure_jq

  local about
  about=$(reddit_curl "${BASE_URL}/user/${username}/about.json") || {
    echo "{\"error\": \"User not found or suspended: $username\"}"
    return 1
  }

  local user_info
  user_info=$(echo "$about" | jq '{
    name: .data.name, link_karma: .data.link_karma,
    comment_karma: .data.comment_karma, created_utc: .data.created_utc,
    is_gold: .data.is_gold, verified: .data.verified
  }')

  if [ "$enrich" = true ]; then
    local posts
    posts=$(reddit_curl "${BASE_URL}/user/${username}/submitted.json?limit=25&sort=new") || posts='{"data":{"children":[]}}'
    local comments
    comments=$(reddit_curl "${BASE_URL}/user/${username}/comments.json?limit=25&sort=new") || comments='{"data":{"children":[]}}'

    echo "$user_info" "$posts" "$comments" | jq -s '{
      user: .[0],
      posts: [.[1].data.children[].data | {id, subreddit, title, score, num_comments, created_utc, permalink}],
      comments: [.[2].data.children[].data | {id, subreddit, body: (.body | .[0:200]), score, created_utc, link_title}],
      subreddits_active: (([.[1].data.children[].data.subreddit] + [.[2].data.children[].data.subreddit]) | unique),
      urls_found: ([.[1].data.children[].data.selftext, .[2].data.children[].data.body] | map(select(. != null) | scan("https?://[^\\s)\"]+")) | flatten | unique)
    }'
  else
    echo "$user_info"
  fi
}
mode_crosspost() {
  local campaign=""
  while [ $# -gt 0 ]; do
    case "$1" in --campaign) campaign="$2"; shift 2 ;; *) shift ;; esac
  done
  ensure_jq; ensure_data_dir
  log "Fetching posts for crosspost analysis..."
  local fetch_output
  if [ -n "$campaign" ]; then
    fetch_output=$(mode_fetch --campaign "$campaign" --pages 1 2>/dev/null)
  else
    fetch_output=$(mode_fetch --campaign global_english --pages 1 2>/dev/null)
  fi
  if [ -z "$fetch_output" ]; then log "No fetch data"; return 1; fi
  echo "$fetch_output" | jq '{
    multi_posters: [
      [.posts[]] | group_by(.author) | map(select(length > 1)) | .[]
      | {author: .[0].author, post_count: length, subreddits: [.[].subreddit] | unique, titles: [.[].title]}
      | select(.subreddits | length > 1)
    ]
  }'
}

mode_stickied() {
  local subreddit="${1:-}"
  ensure_jq
  if [ -z "$subreddit" ]; then
    local config_file="$SKILL_DIR/references/subreddits.json"
    if [ ! -f "$config_file" ]; then log "Specify a subreddit"; return 1; fi
    local subs
    subs=$(jq -r '[.campaigns[].subreddits[].name] | .[0:5] | .[]' "$config_file")
    for sub in $subs; do
      log "Fetching stickied from r/$sub..."
      local response
      response=$(reddit_curl "${BASE_URL}/r/${sub}/hot.json?limit=5") || continue
      echo "$response" | jq --arg sub "$sub" '[.data.children[].data | select(.stickied == true) | {id, subreddit: $sub, title, num_comments, permalink}]'
    done | jq -s 'flatten'
  else
    local response
    response=$(reddit_curl "${BASE_URL}/r/${subreddit}/hot.json?limit=5") || return 1
    local stickied_ids
    stickied_ids=$(echo "$response" | jq -r '[.data.children[].data | select(.stickied == true) | .id] | .[]')
    for post_id in $stickied_ids; do
      log "Fetching comments for stickied $post_id..."
      mode_comments "$post_id" "$subreddit"
    done
  fi
}

mode_firehose() {
  local subreddits="${1:-}"
  ensure_jq
  if [ -z "$subreddits" ]; then
    local config_file="$SKILL_DIR/references/subreddits.json"
    if [ ! -f "$config_file" ]; then log "Specify subreddits: reddit.sh firehose sub1+sub2"; return 1; fi
    subreddits=$(jq -r '[.campaigns[].subreddits[].name] | .[0:8] | join("+")' "$config_file")
  fi
  local response
  response=$(reddit_curl "${BASE_URL}/r/${subreddits}/comments.json?limit=100") || return 1
  echo "$response" | jq '{
    subreddits: (.data.children | [.[].data.subreddit] | unique),
    comments: [.data.children[].data | {id, author, body, subreddit, link_title, link_permalink, score, created_utc, urls: ([.body | scan("https?://[^\\s)\"]+")]? // [])}]
  }'
  # Update last comment ID in state
  local newest_id
  newest_id=$(echo "$response" | jq -r '.data.children[0].data.id // empty')
  if [ -n "$newest_id" ] && [ -f "$STATE_FILE" ]; then
    update_state ".last_firehose_comment_id = \"$newest_id\""
  fi
}

mode_export() {
  local format="json"
  while [ $# -gt 0 ]; do
    case "$1" in --format) format="$2"; shift 2 ;; *) shift ;; esac
  done
  ensure_jq
  if [ ! -f "$STATE_FILE" ]; then log "Nothing to export"; return 1; fi
  case "$format" in
    json) jq '.opportunities // {}' "$STATE_FILE" ;;
    csv)
      echo "name,score,status,first_seen,pain_frequency,source_post_count"
      jq -r '.opportunities // {} | to_entries[] | [.key, .value.score, .value.status, .value.first_seen, .value.pain_frequency, (.value.source_posts | length)] | @csv' "$STATE_FILE"
      ;;
    *) log "Unknown format: $format"; return 1 ;;
  esac
}

mode_cleanup() {
  ensure_jq
  if [ ! -f "$STATE_FILE" ]; then log "Nothing to clean"; return 0; fi
  local now thirty_days_ago sixty_days_ago
  now=$(date +%s)
  thirty_days_ago=$((now - 30 * 86400))
  sixty_days_ago=$((now - 60 * 86400))
  local before_seen before_watched before_products
  before_seen=$(jq '.seen_posts // {} | keys | length' "$STATE_FILE")
  before_watched=$(jq '.watched_threads // {} | keys | length' "$STATE_FILE")
  before_products=$(jq '.products_seen // {} | keys | length' "$STATE_FILE")
  local tmp_file
  tmp_file=$(mktemp)
  jq --arg cutoff30 "$thirty_days_ago" '
    .seen_posts = (.seen_posts // {} | to_entries | map(select(.value > ($cutoff30 | tonumber))) | from_entries)
    | .watched_threads = (.watched_threads // {} | to_entries | map(select(.value.watch_until > now)) | from_entries)
  ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"
  local after_seen after_watched after_products
  after_seen=$(jq '.seen_posts // {} | keys | length' "$STATE_FILE")
  after_watched=$(jq '.watched_threads // {} | keys | length' "$STATE_FILE")
  after_products=$(jq '.products_seen // {} | keys | length' "$STATE_FILE")
  jq -n --arg bs "$before_seen" --arg as "$after_seen" --arg bw "$before_watched" --arg aw "$after_watched" --arg bp "$before_products" --arg ap "$after_products" '{
    cleaned: {seen_posts: (($bs|tonumber)-($as|tonumber)), watched_threads: (($bw|tonumber)-($aw|tonumber)), products_seen: (($bp|tonumber)-($ap|tonumber))},
    remaining: {seen_posts: ($as|tonumber), watched_threads: ($aw|tonumber), products_seen: ($ap|tonumber)}
  }'
}
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
mode_duplicates() {
  local post_id="${1:?Usage: reddit.sh duplicates <post_id>}"
  ensure_jq
  local response
  response=$(reddit_curl "${BASE_URL}/duplicates/${post_id}.json") || return 1
  echo "$response" | jq --arg id "$post_id" '{post_id: $id, duplicates: [.[1].data.children[].data | {subreddit, title, score, num_comments, permalink, created_utc}]}'
}

mode_wiki() {
  local subreddit="${1:?Usage: reddit.sh wiki <subreddit> [page]}"
  local page="${2:-}"
  ensure_jq
  if [ -z "$page" ]; then
    local response
    response=$(reddit_curl "${BASE_URL}/r/${subreddit}/wiki/pages.json") || { echo '{"error": "Wiki not available"}'; return 1; }
    echo "$response" | jq --arg sub "$subreddit" '{subreddit: $sub, pages: .data}'
  else
    local response
    response=$(reddit_curl "${BASE_URL}/r/${subreddit}/wiki/${page}.json") || { echo '{"error": "Wiki page not found"}'; return 1; }
    echo "$response" | jq --arg sub "$subreddit" --arg p "$page" '{subreddit: $sub, page: $p, content_md: .data.content_md, revision_date: .data.revision_date}'
  fi
}

mode_stats() {
  ensure_jq
  if [ ! -f "$STATE_FILE" ]; then echo '{"error": "No state file"}'; return 1; fi
  local size_kb
  size_kb=$(du -sk "$DATA_DIR" 2>/dev/null | awk '{print $1}')
  jq --arg size "$size_kb" '{
    total_seen: (.seen_posts // {} | keys | length),
    total_opportunities: (.opportunities // {} | keys | length),
    total_watched: (.watched_threads // {} | keys | length),
    data_size_kb: ($size | tonumber),
    opportunity_breakdown: (.opportunities // {} | to_entries | group_by(.value.status) | map({(.[0].value.status): length}) | add // {}),
    influencers_tracked: (.influencers // {} | keys | length),
    products_seen: (.products_seen // {} | keys | length)
  }' "$STATE_FILE"
}

mode_config() {
  ensure_jq
  ensure_data_dir

  local action="${1:-show}"

  case "$action" in
    show)
      if [[ ! -f "$CONFIG_FILE" ]]; then
        init_config
      fi
      echo "=== Reddit Opportunity Hunter Config ==="
      echo "Location: $CONFIG_FILE"
      echo ""
      jq . "$CONFIG_FILE"
      ;;
    set)
      local key="${2:?Usage: reddit.sh config set <key> <value>}"
      local value="${3:?Usage: reddit.sh config set <key> <value>}"
      if [[ ! -f "$CONFIG_FILE" ]]; then
        init_config
      fi
      # Detect if value is a JSON array/object/number/boolean or a plain string
      if echo "$value" | jq . &>/dev/null; then
        update_config ".[\"$key\"] = $value"
      else
        update_config ".[\"$key\"] = \"$value\""
      fi
      log "Set $key = $value"
      jq . "$CONFIG_FILE"
      ;;
    reset)
      rm -f "$CONFIG_FILE"
      init_config
      log "Config reset to defaults"
      jq . "$CONFIG_FILE"
      ;;
    *)
      echo "Usage: reddit.sh config [show|set <key> <value>|reset]"
      echo ""
      echo "Keys:"
      echo "  output_language       Report language (en, zh, ja, de, fr, ...)"
      echo "  focus_industries      JSON array of industries to prioritize"
      echo "  excluded_subreddits   JSON array of subreddits to skip"
      echo "  score_threshold       Minimum score for reports (default: 7)"
      echo "  max_build_complexity  Max complexity: Trivial|Light|Medium|Heavy"
      echo "  currency_display      Currency for revenue estimates (USD, CNY, EUR, ...)"
      echo ""
      echo "Examples:"
      echo "  reddit.sh config set output_language zh"
      echo "  reddit.sh config set focus_industries '[\"SaaS\",\"DevTools\"]'"
      echo "  reddit.sh config set currency_display CNY"
      echo "  reddit.sh config reset"
      return 1
      ;;
  esac
}

mode_expand() {
  local campaign=""
  while [[ $# -gt 0 ]]; do
    case "$1" in --campaign) campaign="$2"; shift 2 ;; *) shift ;; esac
  done
  if [[ -z "$campaign" ]]; then
    log "Usage: reddit.sh expand --campaign <campaign_name>"
    return 1
  fi
  ensure_jq; ensure_data_dir
  local config_file="$SKILL_DIR/references/subreddits.json"
  if [[ ! -f "$config_file" ]]; then log "No subreddits.json"; return 1; fi
  local subs
  subs=$(jq -r --arg c "$campaign" '.campaigns[$c].subreddits // [] | .[].name' "$config_file" 2>/dev/null)
  if [[ -z "$subs" ]]; then log "Campaign $campaign not found or empty"; return 1; fi
  log "Expanding campaign: $campaign"
  local top_subs
  if [[ -f "$STATE_FILE" ]]; then
    top_subs=$(jq -r '.subreddit_quality // {} | to_entries | sort_by(-.value.ema_score // -.value.hit_rate // 0) | .[0:3] | .[].key' "$STATE_FILE" 2>/dev/null)
  fi
  if [[ -z "$top_subs" ]]; then top_subs=$(echo "$subs" | head -3); fi
  echo "{\"campaign\":\"$campaign\",\"top_subs\":[$(echo "$top_subs" | jq -R . | paste -sd,)],\"status\":\"expansion_ready\"}"
}

mode_quality() {
  local action="report" sub="" format="json"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --report) action="report"; shift ;;
      --history) action="history"; sub="$2"; shift 2 ;;
      --format) format="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  ensure_jq
  if [[ ! -f "$STATE_FILE" ]]; then log "No state file"; return 1; fi
  case "$action" in
    report)
      jq '{
        quality_report: {
          date: (now | strftime("%Y-%m-%d")),
          subs: [.subreddit_quality // {} | to_entries[] | {
            sub: .key,
            ema_score: (.value.ema_score // "N/A"),
            peak_score: (.value.peak_score // "N/A"),
            hit_rate: (.value.hit_rate // 0),
            scanned: (.value.scanned // 0),
            weeks_tracked: (.value.weeks_tracked // 0),
            trend: (if (.value.ema_history // [] | length) >= 2 then
              if (.value.ema_history[-1] // 0) > (.value.ema_history[-2] // 0) then "rising"
              elif (.value.ema_history[-1] // 0) < (.value.ema_history[-2] // 0) then "declining"
              else "stable" end
            else "insufficient_data" end)
          }] | sort_by(-.ema_score)
        }
      }' "$STATE_FILE"
      ;;
    history)
      if [[ -z "$sub" ]]; then log "Usage: reddit.sh quality --history <subreddit>"; return 1; fi
      jq --arg s "$sub" '.subreddit_quality[$s] // {error: "sub not found"}' "$STATE_FILE"
      ;;
  esac
}

mode_promote() {
  local sub_name="" campaign=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --campaign) campaign="$2"; shift 2 ;;
      *) sub_name="$1"; shift ;;
    esac
  done
  if [[ -z "$sub_name" || -z "$campaign" ]]; then
    log "Usage: reddit.sh promote <sub_name> --campaign <campaign_name>"
    return 1
  fi
  ensure_jq; ensure_data_dir
  local discovered_file="$DATA_DIR/discovered_subs.json"
  local subs_file="${SUBREDDITS_FILE:-$SKILL_DIR/references/subreddits.json}"
  if [[ ! -f "$discovered_file" ]]; then log "No discovered_subs.json"; return 1; fi
  local sub_data
  sub_data=$(jq -r --arg name "$sub_name" --arg c "$campaign" '.discovered[$c] // [] | map(select(.name == $name)) | .[0] // empty' "$discovered_file")
  if [[ -z "$sub_data" ]]; then log "Sub $sub_name not found in discovered subs for campaign $campaign"; return 1; fi
  local clean_sub
  clean_sub=$(echo "$sub_data" | jq 'del(._auto_added, ._added_date, ._discovery_score, ._source)')
  local tmp; tmp=$(mktemp)
  jq --arg c "$campaign" --argjson sub "$clean_sub" '.campaigns[$c].subreddits += [$sub]' "$subs_file" > "$tmp" && mv "$tmp" "$subs_file"
  tmp=$(mktemp)
  jq --arg name "$sub_name" --arg c "$campaign" '.discovered[$c] = [.discovered[$c][] | select(.name != $name)]' "$discovered_file" > "$tmp" && mv "$tmp" "$discovered_file"
  log "Promoted $sub_name to $subs_file under campaign $campaign"
  echo "$clean_sub"
}

merge_discovered_subs() {
  local campaign="${1:?}" subs_file="${2:?}"
  local discovered_file="$DATA_DIR/discovered_subs.json"
  local original
  original=$(jq --arg c "$campaign" '.campaigns[$c].subreddits // []' "$subs_file")
  if [[ -f "$discovered_file" ]]; then
    local discovered
    discovered=$(jq --arg c "$campaign" '.discovered[$c] // []' "$discovered_file")
    echo "$original" "$discovered" | jq -s 'add | unique_by(.name)'
  else
    echo "$original"
  fi
}

# ─── Main dispatch ────────────────────────────────────────────────────────────

# Guard: only dispatch when executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    fetch|comments|search|discover|profile|crosspost|stickied|firehose|export|cleanup|diagnose|duplicates|wiki|stats|config|expand|quality|promote)
      mode="$1"; shift; "mode_$mode" "$@" ;;
    *)
      echo "Usage: reddit.sh <mode> [options]"
      echo "Modes: fetch comments search discover profile crosspost stickied firehose export cleanup diagnose duplicates wiki stats config expand quality promote"
      exit 1
      ;;
  esac
fi
