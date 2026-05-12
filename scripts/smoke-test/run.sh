#!/usr/bin/env bash
# Entry point for the update-tokens regression suite.
# Run with: yarn test:smoke  (or bash scripts/smoke-test/run.sh)
#
# Discovers tests under scripts/smoke-test/tests/ and runs each as an
# independent bash subprocess. Aggregates pass/fail/skip counts and exits
# non-zero if anything failed.
#
# Per-test exit code conventions:
#   0   → passed
#   77  → skipped (first line of stdout is shown as the reason)
#   *   → failed (full output shown, truncated to 30 lines)

set -uo pipefail

# Always run from repo root regardless of how this was invoked.
cd "$(dirname "$0")/../.."

pass=0
fail=0
skipped=0
log=$(mktemp)
trap 'rm -f "$log"' EXIT

echo "Running update-tokens regression suite..."
echo

for test_file in scripts/smoke-test/tests/*.sh; do
  name=$(basename "$test_file" .sh)
  bash "$test_file" >"$log" 2>&1
  status=$?
  case $status in
    0)
      printf '\033[32m✓\033[0m %s\n' "$name"
      pass=$((pass + 1))
      ;;
    77)
      reason=$(head -1 "$log")
      printf '\033[33m∼\033[0m %s (skipped: %s)\n' "$name" "$reason"
      skipped=$((skipped + 1))
      ;;
    *)
      printf '\033[31m✗\033[0m %s\n' "$name"
      sed 's/^/    /' "$log" | head -30
      fail=$((fail + 1))
      ;;
  esac
done

echo
if [ "$fail" -eq 0 ]; then
  printf '\033[32m%d passed\033[0m' "$pass"
  [ "$skipped" -gt 0 ] && printf ', \033[33m%d skipped\033[0m' "$skipped"
  printf '\n'
  exit 0
else
  printf '\033[31m%d failed\033[0m, %d passed' "$fail" "$pass"
  [ "$skipped" -gt 0 ] && printf ', \033[33m%d skipped\033[0m' "$skipped"
  printf '\n'
  exit 1
fi
