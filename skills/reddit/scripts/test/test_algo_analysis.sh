#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/test_helpers.sh"
setup_test_paths

source "$SCRIPT_DIR/algo_analysis.sh"

echo ""
echo "=== Algorithm Analysis Tests ==="

# ─── Test group 1: TF-IDF ───────────────────────────────────────────────────
echo ""
echo "=== Test group 1: TF-IDF ==="

tfidf_input='[
  {"text": "I need help with invoicing software for my small business"},
  {"text": "Best invoicing tools that integrate with accounting systems"},
  {"text": "How do I automate my accounting workflow and reduce errors"}
]'

tfidf_result=$(algo_tfidf "$tfidf_input")

# Result should be a JSON array
tfidf_length=$(echo "$tfidf_result" | jq 'length')
assert_gt "TF-IDF returns non-empty array" "$tfidf_length" 0

# "invoicing" appears in 2/3 docs so has positive but not zero tfidf
invoicing_tfidf=$(echo "$tfidf_result" | jq '[.[] | select(.term == "invoicing")] | .[0].tfidf')
is_positive=$(echo "$invoicing_tfidf" | awk '{print ($1 > 0) ? "yes" : "no"}')
assert_eq "invoicing has positive tfidf" "yes" "$is_positive"

# Each result should have term and tfidf fields
first_has_term=$(echo "$tfidf_result" | jq '.[0] | has("term")')
assert_eq "TF-IDF results have term field" "true" "$first_has_term"

first_has_tfidf=$(echo "$tfidf_result" | jq '.[0] | has("tfidf")')
assert_eq "TF-IDF results have tfidf field" "true" "$first_has_tfidf"

# ─── Test group 2: N-gram ───────────────────────────────────────────────────
echo ""
echo "=== Test group 2: N-gram ==="

ngram_input='[
  "I waste hours on manual invoicing every week",
  "We waste hours reconciling payments manually",
  "Teams waste hours doing repetitive data entry",
  "I am looking for a better invoicing solution",
  "We are looking for automation tools for billing"
]'

ngram_result=$(algo_ngrams "$ngram_input" 2 2)

waste_hours_freq=$(echo "$ngram_result" | jq '[.[] | select(.ngram == "waste hours")] | .[0].freq')
assert_eq "waste hours bigram freq is 3" "3" "$waste_hours_freq"

looking_for_freq=$(echo "$ngram_result" | jq '[.[] | select(.ngram == "looking for")] | .[0].freq')
assert_eq "looking for bigram freq is 2" "2" "$looking_for_freq"

# ─── Test group 3: SimHash ──────────────────────────────────────────────────
echo ""
echo "=== Test group 3: SimHash ==="

hash1=$(algo_simhash "I need help with invoicing software for my business")
hash2=$(algo_simhash "I need help with invoicing tools for my business")
hash3=$(algo_simhash "The weather today is sunny and warm outside")

dist_similar=$(algo_simhash_dist "$hash1" "$hash2")
dist_different=$(algo_simhash_dist "$hash1" "$hash3")

similar_closer=$(awk "BEGIN {print ($dist_similar < $dist_different) ? \"yes\" : \"no\"}")
assert_eq "Similar texts have smaller hamming distance" "yes" "$similar_closer"

# ─── Test group 4: Shannon Entropy ──────────────────────────────────────────
echo ""
echo "=== Test group 4: Shannon Entropy ==="

focused_posts='[
  {"text": "Best invoicing software for freelancers and small business invoicing"},
  {"text": "Invoicing tools that help with billing and invoicing automation"},
  {"text": "How to improve invoicing workflow for client invoicing management"}
]'

scattered_posts='[
  {"text": "The weather forecast shows rain tomorrow morning"},
  {"text": "New programming language released for web development"},
  {"text": "Recipe for chocolate cake with cream cheese frosting"}
]'

entropy_focused=$(algo_entropy "$focused_posts")
entropy_scattered=$(algo_entropy "$scattered_posts")

focused_lower=$(awk "BEGIN {print ($entropy_focused < $entropy_scattered) ? \"yes\" : \"no\"}")
assert_eq "Focused posts have lower entropy than scattered" "yes" "$focused_lower"

# ─── Test group 5: Flesch-Kincaid ───────────────────────────────────────────
echo ""
echo "=== Test group 5: Flesch-Kincaid ==="

simple_text="I like my dog. He is fun. We play a lot."
complex_text="The implementation of enterprise resource planning necessitates comprehensive organizational restructuring. Sophisticated methodologies facilitate systematic transformation procedures."

grade_simple=$(algo_readability "$simple_text")
grade_complex=$(algo_readability "$complex_text")

simple_lower=$(awk "BEGIN {print ($grade_simple < $grade_complex) ? \"yes\" : \"no\"}")
assert_eq "Simple text has lower grade than complex text" "yes" "$simple_lower"

# ─── Test group 6: Jaccard Similarity ───────────────────────────────────────
echo ""
echo "=== Test group 6: Jaccard Similarity ==="

set_a='[1,2,3,4,5]'
set_b='[3,4,5,6,7]'
set_c='[10,11,12]'

jaccard_ab=$(algo_jaccard "$set_a" "$set_b")
# intersection={3,4,5}=3, union={1,2,3,4,5,6,7}=7, 3/7=0.43
jaccard_ab_check=$(awk "BEGIN {diff = $jaccard_ab - 0.43; if (diff < 0) diff = -diff; print (diff < 0.01) ? \"yes\" : \"no\"}")
assert_eq "Jaccard A,B is ~0.43" "yes" "$jaccard_ab_check"

jaccard_ac=$(algo_jaccard "$set_a" "$set_c")
jaccard_ac_check=$(awk "BEGIN {print ($jaccard_ac == 0 || $jaccard_ac < 0.01) ? \"yes\" : \"no\"}")
assert_eq "Jaccard A,C is 0.00" "yes" "$jaccard_ac_check"

# ─── Test group 7: Apriori / Association ────────────────────────────────────
echo ""
echo "=== Test group 7: Apriori Association ==="

labels_input='[
  ["invoicing", "billing", "automation"],
  ["invoicing", "billing", "payments"],
  ["invoicing", "automation", "accounting"],
  ["billing", "payments", "reporting"],
  ["automation", "scheduling", "workflow"]
]'

assoc_result=$(algo_association "$labels_input" 0.3)

# invoicing+billing co-occur in 2/5 = 0.4 which is >= 0.3
has_inv_bill=$(echo "$assoc_result" | jq '[.[] | select((.pair[0] == "billing" and .pair[1] == "invoicing") or (.pair[0] == "invoicing" and .pair[1] == "billing"))] | length')
assert_gt "invoicing+billing pair found" "$has_inv_bill" 0

# invoicing+automation co-occur in 2/5 = 0.4 which is >= 0.3
has_inv_auto=$(echo "$assoc_result" | jq '[.[] | select((.pair[0] == "automation" and .pair[1] == "invoicing") or (.pair[0] == "invoicing" and .pair[1] == "automation"))] | length')
assert_gt "invoicing+automation pair found" "$has_inv_auto" 0

# Result should have pair and support fields
first_has_pair=$(echo "$assoc_result" | jq '.[0] | has("pair")')
assert_eq "Association results have pair field" "true" "$first_has_pair"

first_has_support=$(echo "$assoc_result" | jq '.[0] | has("support")')
assert_eq "Association results have support field" "true" "$first_has_support"

# ─── Test group 8: Threshold Cluster ────────────────────────────────────────
echo ""
echo "=== Test group 8: Threshold Cluster ==="

similarity_input='{
  "A:B": 0.45,
  "A:C": 0.05,
  "B:C": 0.08
}'

cluster_result=$(algo_threshold_cluster "$similarity_input" 0.15)

# A and B should be in the same cluster, C separate
# Find which cluster A is in
cluster_a=$(echo "$cluster_result" | jq -r '.[] | select(. | contains(["A"])) | .[0]')
cluster_has_b=$(echo "$cluster_result" | jq '[.[] | select(. | contains(["A"])) | select(. | contains(["B"]))] | length')
assert_gt "A and B in same cluster" "$cluster_has_b" 0

cluster_c_separate=$(echo "$cluster_result" | jq '[.[] | select(. | contains(["C"])) | select(length == 1)] | length')
assert_gt "C is in its own cluster" "$cluster_c_separate" 0

num_clusters=$(echo "$cluster_result" | jq 'length')
assert_eq "Two clusters total" "2" "$num_clusters"

test_summary
