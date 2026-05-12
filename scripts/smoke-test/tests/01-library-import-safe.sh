#!/usr/bin/env bash
# squid-api.js is the shared library module — it must import without
# producing any output or running side effects. If this fails, a future
# contributor probably added a top-level statement to the library.

set -uo pipefail

out=$(node --input-type=module -e "import \"./scripts/update-tokens/squid-api.js\"" 2>&1)
if [ -n "$out" ]; then
  echo "squid-api.js produced output on import:"
  echo "$out"
  exit 1
fi
