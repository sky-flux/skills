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

# ─── Mode stubs ───────────────────────────────────────────────────────────────

mode_fetch()      { log "TODO: fetch"; }
mode_comments()   { log "TODO: comments"; }
mode_search()     { log "TODO: search"; }
mode_discover()   { log "TODO: discover"; }
mode_profile()    { log "TODO: profile"; }
mode_crosspost()  { log "TODO: crosspost"; }
mode_stickied()   { log "TODO: stickied"; }
mode_firehose()   { log "TODO: firehose"; }
mode_export()     { log "TODO: export"; }
mode_cleanup()    { log "TODO: cleanup"; }
mode_diagnose()   { log "TODO: diagnose"; }
mode_duplicates() { log "TODO: duplicates"; }
mode_wiki()       { log "TODO: wiki"; }
mode_stats()      { log "TODO: stats"; }

# ─── Main dispatch ────────────────────────────────────────────────────────────

case "${1:-}" in
  fetch|comments|search|discover|profile|crosspost|stickied|firehose|export|cleanup|diagnose|duplicates|wiki|stats)
    mode="$1"; shift; "mode_$mode" "$@" ;;
  *)
    echo "Usage: reddit.sh <mode> [options]"
    echo "Modes: fetch comments search discover profile crosspost stickied firehose export cleanup diagnose duplicates wiki stats"
    exit 1
    ;;
esac
