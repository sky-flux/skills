#!/usr/bin/env bash
# Algorithm analysis functions for text/data analysis
# All functions use jq and awk, operate on JSON input, no API calls.

# ─── TF-IDF ──────────────────────────────────────────────────────────────────
# algo_tfidf(posts_json)
# Input: JSON array of objects with .text field
# Output: JSON array of {term, tfidf} sorted desc, top 30
algo_tfidf() {
  local posts_json="$1"
  echo "$posts_json" | jq -r '
    # Tokenize each document into lowercase words
    [.[] | .text | ascii_downcase | [scan("[a-z]+")] ] as $docs |
    ($docs | length) as $N |

    # Build document frequency: for each term, count how many docs contain it
    [
      $docs | to_entries[] |
      .value | unique[] |
      {term: .}
    ] | group_by(.term) | map({term: .[0].term, df: length}) |

    # Build term frequency across all docs combined
    [$docs | .[] | .[]] | group_by(.) | map({term: .[0], tf: length}) |

    # Join tf with df and compute tfidf
    . as $tf_list |
    [
      $tf_list[] |
      .term as $t | .tf as $tf |
      ([$docs | to_entries[] | select(.value | index($t)) ] | length) as $df |
      select($df > 0 and $df < $N) |
      {term: $t, tfidf: (($tf) * (($N / $df) | log / (2 | log)) | . * 1000 | round / 1000)}
    ] |
    sort_by(-.tfidf) | .[0:30]
  '
}

# ─── N-gram ──────────────────────────────────────────────────────────────────
# algo_ngrams(texts_json, n, min_freq)
# Input: JSON array of strings, n-gram size, minimum frequency
# Output: JSON array of {ngram, freq} sorted desc
algo_ngrams() {
  local texts_json="$1"
  local n="${2:-2}"
  local min_freq="${3:-2}"
  echo "$texts_json" | jq -r --argjson n "$n" --argjson min_freq "$min_freq" '
    [
      .[] |
      ascii_downcase | [scan("[a-z]+")] |
      . as $words |
      range(0; (($words | length) - $n + 1)) |
      [$words[.:. + $n]] | .[0] | join(" ")
    ] |
    group_by(.) |
    map({ngram: .[0], freq: length}) |
    [.[] | select(.freq >= $min_freq)] |
    sort_by(-.freq)
  '
}

# ─── SimHash ─────────────────────────────────────────────────────────────────
# algo_simhash(text)
# Locality-sensitive hash: words are hashed individually, then combined via
# weighted bit voting so similar texts produce similar fingerprints.
# Output: integer hash value (31-bit)
algo_simhash() {
  local text="$1"
  echo "$text" | awk '
  function word_hash(w,    h, i, c, ord_val, j) {
    h = 0
    for (i = 1; i <= length(w); i++) {
      c = substr(w, i, 1)
      ord_val = 0
      for (j = 32; j <= 126; j++) {
        if (sprintf("%c", j) == c) { ord_val = j; break }
      }
      h = (h * 31 + ord_val) % 2147483647
    }
    return h
  }
  {
    BITS = 31
    # Initialize bit weight vector
    for (b = 0; b < BITS; b++) V[b] = 0

    n = split(tolower($0), words, /[^a-z]+/)
    for (w = 1; w <= n; w++) {
      if (length(words[w]) == 0) continue
      h = word_hash(words[w])
      for (b = 0; b < BITS; b++) {
        if (int(h / (2^b)) % 2 == 1)
          V[b] += 1
        else
          V[b] -= 1
      }
    }

    # Convert weighted vector to hash
    fingerprint = 0
    for (b = 0; b < BITS; b++) {
      if (V[b] > 0) fingerprint += 2^b
    }
    print int(fingerprint)
  }'
}

# algo_simhash_dist(h1, h2)
# Hamming distance via XOR + popcount in awk
algo_simhash_dist() {
  local h1="$1"
  local h2="$2"
  awk -v a="$h1" -v b="$h2" 'BEGIN {
    val = int(a) + 0
    val2 = int(b) + 0
    dist = 0
    for (bit = 0; bit < 31; bit++) {
      bit_a = int(val / (2^bit)) % 2
      bit_b = int(val2 / (2^bit)) % 2
      if (bit_a != bit_b) dist++
    }
    print dist
  }'
}

# ─── Shannon Entropy ─────────────────────────────────────────────────────────
# algo_entropy(posts_json)
# Input: JSON array of objects with .text field
# Output: entropy value (float)
algo_entropy() {
  local posts_json="$1"
  echo "$posts_json" | jq -r '
    [.[] | .text | ascii_downcase | scan("[a-z]+")] |
    group_by(.) |
    map(length) |
    (. | add) as $total |
    map(. / $total) |
    map(. * (. | log / (2 | log))) |
    -(. | add) |
    . * 1000 | round / 1000
  '
}

# ─── Flesch-Kincaid Readability ──────────────────────────────────────────────
# algo_readability(text)
# Output: Flesch-Kincaid Grade Level (float)
algo_readability() {
  local text="$1"
  echo "$text" | awk '
  function count_syllables(word,    count, i, c, prev_vowel) {
    word = tolower(word)
    count = 0
    prev_vowel = 0
    for (i = 1; i <= length(word); i++) {
      c = substr(word, i, 1)
      if (c == "a" || c == "e" || c == "i" || c == "o" || c == "u" || c == "y") {
        if (!prev_vowel) count++
        prev_vowel = 1
      } else {
        prev_vowel = 0
      }
    }
    if (substr(word, length(word), 1) == "e" && count > 1) count--
    if (count < 1) count = 1
    return count
  }
  {
    line = $0
    # Count sentences
    sent = gsub(/[.!?]/, "&", line)
    if (sent < 1) sent = 1

    # Count words and syllables
    n = split($0, words, /[^a-zA-Z]+/)
    total_words = 0
    total_syl = 0
    for (i = 1; i <= n; i++) {
      if (length(words[i]) > 0) {
        total_words++
        total_syl += count_syllables(words[i])
      }
    }
    if (total_words < 1) total_words = 1

    grade = 0.39 * (total_words / sent) + 11.8 * (total_syl / total_words) - 15.59
    printf "%.2f\n", grade
  }'
}

# ─── Jaccard Similarity ─────────────────────────────────────────────────────
# algo_jaccard(set_a_json, set_b_json)
# Output: float [0,1]
algo_jaccard() {
  local set_a="$1"
  local set_b="$2"
  jq -n --argjson a "$set_a" --argjson b "$set_b" '
    ($a | map(tostring)) as $sa |
    ($b | map(tostring)) as $sb |
    ([$sa[] | select(. as $x | $sb | index($x))] | length) as $inter |
    ([$sa[], $sb[]] | unique | length) as $union |
    if $union == 0 then 0
    else (($inter / $union) * 100 | round) / 100
    end
  '
}

# ─── Association (Apriori-style) ─────────────────────────────────────────────
# algo_association(labels_json, min_support)
# Input: JSON array of arrays (baskets of labels)
# Output: JSON array of {pair, support} for co-occurring pairs
algo_association() {
  local labels_json="$1"
  local min_support="$2"
  echo "$labels_json" | jq --argjson min_support "$min_support" '
    . as $baskets |
    ($baskets | length) as $N |

    # Get all unique labels
    [.[] | .[]] | unique | . as $all_labels |

    # For each pair, count co-occurrences
    [
      range(0; $all_labels | length) as $i |
      range($i + 1; $all_labels | length) as $j |
      $all_labels[$i] as $a |
      $all_labels[$j] as $b |
      ([
        $baskets[] |
        select((. | index($a)) and (. | index($b)))
      ] | length) as $count |
      ($count / $N) as $support |
      select($support >= $min_support) |
      {pair: [$a, $b], support: (($support * 100 | round) / 100)}
    ] |
    sort_by(-.support)
  '
}

# ─── Threshold Cluster (Union-Find) ─────────────────────────────────────────
# algo_threshold_cluster(similarity_json, threshold)
# Input: JSON object with "A:B" keys and similarity values
# Output: JSON array of arrays (clusters)
algo_threshold_cluster() {
  local similarity_json="$1"
  local threshold="$2"
  jq -n --argjson sim "$similarity_json" --argjson thresh "$threshold" '
    # Extract all unique nodes
    [$sim | keys[] | split(":") | .[]] | unique | . as $nodes |

    # Build edges that exceed threshold
    [
      $sim | to_entries[] |
      select(.value > $thresh) |
      .key | split(":") | {a: .[0], b: .[1]}
    ] as $edges |

    # Union-find via iterative merging
    # Start with each node in its own cluster
    [$nodes[] | [.]] |

    # For each edge, merge clusters containing a and b
    reduce $edges[] as $e (
      .;
      . as $clusters |
      ($e.a) as $a | ($e.b) as $b |
      # Find cluster indices containing a and b
      (reduce range(0; $clusters | length) as $i (
        null;
        if . == null and ($clusters[$i] | index($a)) then $i else . end
      )) as $idx_a |
      (reduce range(0; $clusters | length) as $i (
        null;
        if . == null and ($clusters[$i] | index($b)) then $i else . end
      )) as $idx_b |
      if $idx_a == $idx_b then .
      elif $idx_a < $idx_b then
        .[$idx_a] = (.[$idx_a] + .[$idx_b]) |
        del(.[$idx_b])
      else
        .[$idx_b] = (.[$idx_b] + .[$idx_a]) |
        del(.[$idx_a])
      end
    ) |
    [.[] | sort]
  '
}
