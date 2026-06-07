#!/usr/bin/env bash
# Algorithm Engine for Reddit skill
# Provides: Aho-Corasick keyword matching, Bloom filter dedup,
#           language detection, inverted index
# Sourced by reddit.sh — not executed directly.

ALGO_DIR="${REDDIT_DATA_DIR:-$PWD/.reddit}/algo"

# ─── Aho-Corasick Keyword Matching ──────────────────────────────────────────

# Compile intent_keywords.json + tech/competitor keywords into a flat file
# Format: category:keyword (one per line, lowercased)
# Usage: algo_compile_keywords <intent_keywords.json> [subreddits.json]
algo_compile_keywords() {
  local keywords_json="$1"
  local subreddits_json="${2:-}"

  mkdir -p "$ALGO_DIR"
  local compiled="$ALGO_DIR/keywords_compiled.txt"
  : > "$compiled"

  # Map intent_keywords.json tiers to our categories
  # English tiers
  jq -r '.languages.en // {} | to_entries[] | .key as $tier | .value[] |
    (if ($tier | test("pain")) then "pain"
     elif ($tier | test("intent|solution|purchase")) then "intent"
     elif ($tier | test("research")) then "research"
     else "other" end) + ":" + (. | ascii_downcase)' \
    "$keywords_json" >> "$compiled" 2>/dev/null || true

  # Non-English languages
  jq -r '.languages | to_entries[] | select(.key != "en") | .value | to_entries[] |
    .key as $cat | .value[] |
    (if ($cat | test("pain")) then "pain"
     elif ($cat | test("intent")) then "intent"
     elif ($cat | test("business")) then "market"
     elif ($cat | test("compliance")) then "market"
     elif ($cat | test("research")) then "research"
     else "other" end) + ":" + (. | ascii_downcase)' \
    "$keywords_json" >> "$compiled" 2>/dev/null || true

  # Tech stack keywords
  local tech_keywords=(
    react next.js vue angular svelte
    node.js python django flask ruby rails
    typescript javascript golang rust java
    postgres mysql mongodb redis elasticsearch
    docker kubernetes aws gcp azure
    graphql rest api webhook
    tailwind bootstrap material-ui
  )
  for kw in "${tech_keywords[@]}"; do
    echo "tech:$kw" >> "$compiled"
  done

  # Competitor keywords from subreddits.json
  if [[ -n "$subreddits_json" && -f "$subreddits_json" ]]; then
    jq -r '.campaigns | to_entries[] | .value.competitors // [] | .[] |
      "competitor:" + (. | ascii_downcase)' \
      "$subreddits_json" >> "$compiled" 2>/dev/null || true
  fi

  # Remove empty lines and deduplicate
  sort -u "$compiled" -o "$compiled"
  sed -i '' '/^$/d' "$compiled" 2>/dev/null || sed -i '/^$/d' "$compiled" 2>/dev/null || true
}

# Match text against compiled keywords using grep -F (Aho-Corasick internally)
# Returns JSON with categorized matches
# Usage: algo_match_text <text>
algo_match_text() {
  local text="$1"
  local compiled="$ALGO_DIR/keywords_compiled.txt"

  if [[ ! -f "$compiled" ]]; then
    echo '{"pain":[],"intent":[],"research":[],"tech":[],"competitor":[],"market":[],"other":[]}'
    return
  fi

  # Extract just the keywords (after the colon) for grep matching
  local keywords_only
  keywords_only=$(mktemp)
  cut -d: -f2- "$compiled" > "$keywords_only"

  # Single-pass grep -iFo against all keywords
  local matches
  matches=$(echo "$text" | grep -iFo -f "$keywords_only" 2>/dev/null | sort -uf || true)
  rm -f "$keywords_only"

  # Initialize category arrays
  local -a pain=() intent=() research=() tech=() competitor=() market=() other=()

  # Map each match back to its category
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    local match_lower
    match_lower=$(echo "$match" | tr '[:upper:]' '[:lower:]')
    # Look up category from compiled file
    local category
    category=$(grep -iF ":${match_lower}" "$compiled" | head -1 | cut -d: -f1)
    case "$category" in
      pain)       pain+=("$match_lower") ;;
      intent)     intent+=("$match_lower") ;;
      research)   research+=("$match_lower") ;;
      tech)       tech+=("$match_lower") ;;
      competitor) competitor+=("$match_lower") ;;
      market)     market+=("$match_lower") ;;
      *)          other+=("$match_lower") ;;
    esac
  done <<< "$matches"

  # Build JSON output
  _array_to_json() {
    local arr=("$@")
    if [[ ${#arr[@]} -eq 0 ]]; then
      echo "[]"
      return
    fi
    local json="["
    local first=true
    for item in "${arr[@]}"; do
      if $first; then first=false; else json+=","; fi
      json+="\"$item\""
    done
    json+="]"
    echo "$json"
  }

  local j_pain j_intent j_research j_tech j_competitor j_market j_other
  j_pain=$(_array_to_json "${pain[@]+"${pain[@]}"}")
  j_intent=$(_array_to_json "${intent[@]+"${intent[@]}"}")
  j_research=$(_array_to_json "${research[@]+"${research[@]}"}")
  j_tech=$(_array_to_json "${tech[@]+"${tech[@]}"}")
  j_competitor=$(_array_to_json "${competitor[@]+"${competitor[@]}"}")
  j_market=$(_array_to_json "${market[@]+"${market[@]}"}")
  j_other=$(_array_to_json "${other[@]+"${other[@]}"}")

  echo "{\"pain\":${j_pain},\"intent\":${j_intent},\"research\":${j_research},\"tech\":${j_tech},\"competitor\":${j_competitor},\"market\":${j_market},\"other\":${j_other}}"
}

# ─── Bloom Filter (file-based dedup) ────────────────────────────────────────

# Initialize bloom filter file
# Usage: algo_bloom_init [capacity]
algo_bloom_init() {
  mkdir -p "$ALGO_DIR"
  : > "$ALGO_DIR/bloom.dat"
}

# Add ID to bloom filter (skip if already present)
# Usage: algo_bloom_add <id>
algo_bloom_add() {
  local id="$1"
  local bloom="$ALGO_DIR/bloom.dat"

  # Check for duplicate first
  if grep -qFx "$id" "$bloom" 2>/dev/null; then
    return 0
  fi

  echo "$id" >> "$bloom"

  # Periodically sort for faster lookups
  local line_count
  line_count=$(wc -l < "$bloom" | tr -d ' ')
  if (( line_count % 100 == 0 )); then
    sort -u "$bloom" -o "$bloom"
  fi
}

# Check if ID exists in bloom filter
# Returns: 1 if found, 0 if not
# Usage: algo_bloom_check <id>
algo_bloom_check() {
  local id="$1"
  local bloom="$ALGO_DIR/bloom.dat"

  if [[ -f "$bloom" ]] && grep -qFx "$id" "$bloom" 2>/dev/null; then
    echo "1"
  else
    echo "0"
  fi
}

# ─── Language Detection ──────────────────────────────────────────────────────

# Detect language of text by counting language-specific word patterns
# Returns: ISO 639-1 code (en, de, fr, es, pt, etc.)
# Usage: algo_detect_lang <text>
algo_detect_lang() {
  local text="$1"
  local text_lower
  text_lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')

  # Helper: count occurrences of patterns in text
  _count_patterns() {
    local txt="$1"
    shift
    local total=0
    for w in "$@"; do
      local c
      c=$(echo "$txt" | grep -ioF "$w" | wc -l | tr -d ' ')
      total=$(( total + c ))
    done
    echo "$total"
  }

  _count_patterns_weighted() {
    local txt="$1"
    local weight="$2"
    shift 2
    local total=0
    for w in "$@"; do
      local c
      c=$(echo "$txt" | grep -ioF "$w" | wc -l | tr -d ' ')
      total=$(( total + c * weight ))
    done
    echo "$total"
  }

  # English
  local score_en
  score_en=$(_count_patterns "$text_lower" \
    "the " " the " " and " " for " " with " " this " " that " " have " \
    " from " " are " " was " " been " " will " " would " " could " \
    " should " " about " " which " " their " " there " " these " " those " " through ")

  # German words + special chars
  local score_de score_de_chars
  score_de=$(_count_patterns "$text_lower" \
    " der " " die " " das " " und " " ist " " ein " " eine " " nicht " \
    " mit " " auf " " den " " dem " " des " " von " " für " " sich " \
    " auch " " nach " " noch " " wie " " über ")
  score_de_chars=$(_count_patterns_weighted "$text_lower" 2 "ü" "ö" "ä" "ß")
  score_de=$(( score_de + score_de_chars ))

  # French words + special chars
  local score_fr score_fr_chars
  score_fr=$(_count_patterns "$text_lower" \
    " les " " des " " une " " est " " dans " " pour " " que " " sur " \
    " pas " " sont " " avec " " mais " " cette " " tout " " aux " " ses " " ont " " leur ")
  score_fr_chars=$(_count_patterns_weighted "$text_lower" 2 "é" "è" "ê" "ë" "ç" "à" "â" "î" "ô" "û")
  score_fr=$(( score_fr + score_fr_chars ))

  # Spanish
  local score_es score_es_chars
  score_es=$(_count_patterns "$text_lower" \
    " los " " las " " una " " del " " por " " con " " para " " como " \
    " pero " " sus " " sobre " " este " " esta " " todo " " tiene " " desde " " cuando ")
  score_es_chars=$(_count_patterns_weighted "$text_lower" 2 "ñ" "¿" "¡")
  score_es=$(( score_es + score_es_chars ))

  # Portuguese
  local score_pt score_pt_chars
  score_pt=$(_count_patterns "$text_lower" \
    " os " " das " " uma " " com " " para " " por " " mais " " como " \
    " mas " " seu " " sua " " nos " " nas " " tem " " sobre " " quando ")
  score_pt_chars=$(_count_patterns_weighted "$text_lower" 2 "ã" "õ" "ç")
  score_pt=$(( score_pt + score_pt_chars ))

  # Find max
  local best_lang="en"
  local best_score=$score_en

  if (( score_de > best_score )); then best_score=$score_de; best_lang="de"; fi
  if (( score_fr > best_score )); then best_score=$score_fr; best_lang="fr"; fi
  if (( score_es > best_score )); then best_score=$score_es; best_lang="es"; fi
  if (( score_pt > best_score )); then best_score=$score_pt; best_lang="pt"; fi

  echo "$best_lang"
}

# ─── Inverted Index ─────────────────────────────────────────────────────────

# Add a post_id to the index for a keyword
# Usage: algo_index_add <keyword> <post_id>
algo_index_add() {
  local keyword="$1"
  local post_id="$2"
  local index_dir="$ALGO_DIR/index"
  mkdir -p "$index_dir"

  # Sanitize keyword for filename
  local safe_keyword
  safe_keyword=$(echo "$keyword" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g')

  local index_file="$index_dir/$safe_keyword"
  echo "$post_id" >> "$index_file"
}

# Query the index for a keyword
# Returns: sorted unique post IDs, one per line (empty string if none)
# Usage: algo_index_query <keyword>
algo_index_query() {
  local keyword="$1"
  local index_dir="$ALGO_DIR/index"

  local safe_keyword
  safe_keyword=$(echo "$keyword" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g')

  local index_file="$index_dir/$safe_keyword"

  if [[ -f "$index_file" ]]; then
    sort -u "$index_file"
  fi
}
