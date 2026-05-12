#!/usr/bin/env bash
# colors.js must:
#   1. Exit cleanly (no hang from timer leak) when Squid is unreachable.
#   2. Leave url_fetch_errors.json untouched — otherwise the skip-list
#      fetch-new-tokens.js depends on next run would be wiped.

set -uo pipefail
source "$(dirname "$0")/../lib.sh"

cp scripts/update-tokens/url_fetch_errors.json /tmp/smoke-pre-url-errors.json 2>/dev/null || true

SQUID_API_URL=http://127.0.0.1:1 SQUID_INTEGRATOR_ID=x \
  run_with_timeout 30 node scripts/update-tokens/colors.js >/dev/null 2>&1
status=$?

if [ "$status" -eq 137 ]; then
  echo "TIMEOUT — process killed after 30s. Likely regression of the timer-leak fix."
  exit 1
fi
if [ "$status" -ne 0 ]; then
  echo "Unexpected exit code: $status"
  exit 1
fi

if [ -f /tmp/smoke-pre-url-errors.json ]; then
  diff -q /tmp/smoke-pre-url-errors.json \
          scripts/update-tokens/url_fetch_errors.json >/dev/null || {
    echo "url_fetch_errors.json was modified during API failure"
    exit 1
  }
fi
