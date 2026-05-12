#!/usr/bin/env bash
# Bash and Node.js syntax checks for every script in scripts/.
# Catches typos, unbalanced quotes, and other issues that would only otherwise
# surface at runtime.

set -uo pipefail

for f in scripts/convert.sh \
         scripts/compare_folders_size.sh \
         scripts/update-tokens/save-new-tokens.sh \
         scripts/update-tokens/convert-webp-to-png.sh \
         scripts/smoke-test/run.sh \
         scripts/smoke-test/lib.sh \
         scripts/smoke-test/tests/*.sh; do
  bash -n "$f"
done

for f in scripts/update-tokens/colors.js \
         scripts/update-tokens/squid-api.js \
         scripts/update-tokens/fetch-new-tokens.js \
         scripts/update-tokens/colors-utils.js \
         scripts/update-tokens/assert-entry.js; do
  node --check "$f"
done
