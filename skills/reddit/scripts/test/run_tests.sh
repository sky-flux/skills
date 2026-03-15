#!/usr/bin/env bash
set -euo pipefail

# Test runner: discovers and runs all test_*.sh files in this directory

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"

TOTAL=0
PASSED=0
FAILED=0
FAILED_FILES=()

echo "========================================"
echo "  Reddit Skill Test Runner"
echo "========================================"

for test_file in "$TEST_DIR"/test_*.sh; do
  [[ -f "$test_file" ]] || continue
  filename="$(basename "$test_file")"
  TOTAL=$((TOTAL + 1))

  echo ""
  echo "--- Running: $filename ---"
  if bash "$test_file"; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
    FAILED_FILES+=("$filename")
  fi
done

echo ""
echo "========================================"
echo "  Test Runner Summary"
echo "  Files: $PASSED/$TOTAL passed"
if [[ $FAILED -gt 0 ]]; then
  echo "  Failed:"
  for f in "${FAILED_FILES[@]}"; do
    echo "    - $f"
  done
fi
echo "========================================"

if [[ $FAILED -gt 0 ]]; then
  exit 1
fi
