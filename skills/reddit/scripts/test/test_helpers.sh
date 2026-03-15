#!/usr/bin/env bash
# Shared test helpers for reddit skill tests
# Source this file from each test_*.sh file

PASS=0
FAIL=0

# ─── Path setup ──────────────────────────────────────────────────────────────

setup_test_paths() {
  TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
  FIXTURE_DIR="$TEST_DIR/fixtures"
  SCRIPT_DIR="$(dirname "$TEST_DIR")"
  SKILL_DIR="$(dirname "$SCRIPT_DIR")"
  REDDIT_SH="$SCRIPT_DIR/reddit.sh"
}

# ─── Assertion helpers ────────────────────────────────────────────────────────

assert_eq() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    echo "        expected: $expected"
    echo "        actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local description="$1"
  local haystack="$2"
  local needle="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    echo "        expected to contain: $needle"
    echo "        in: $haystack"
    FAIL=$((FAIL + 1))
  fi
}

assert_gt() {
  local description="$1"
  local actual="$2"
  local threshold="$3"
  if [[ "$actual" -gt "$threshold" ]]; then
    echo "  PASS: $description (got $actual > $threshold)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    echo "        expected: > $threshold"
    echo "        actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_json_key() {
  local description="$1"
  local json="$2"
  local key="$3"
  if echo "$json" | jq -e "has(\"$key\")" >/dev/null 2>&1; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    echo "        expected JSON to have key: $key"
    FAIL=$((FAIL + 1))
  fi
}

# ─── Summary ──────────────────────────────────────────────────────────────────

test_summary() {
  echo ""
  echo "=================================================="
  echo "Results: $PASS passed, $FAIL failed"
  echo "=================================================="

  if [[ $FAIL -gt 0 ]]; then
    return 1
  fi
  return 0
}
