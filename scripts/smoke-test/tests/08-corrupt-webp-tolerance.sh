#!/usr/bin/env bash
# Verifies that a single malformed webp does not abort convert-webp-to-png.sh
# under `set -e` + `xargs -P`. Plants a synthetic corrupt webp alongside a
# real one (INTEGRATION_TARGET, whose color entry is deleted so it must be
# reconverted), then asserts:
#   1. yarn update-colors exits 0 (the bad input did not propagate failure)
#   2. INTEGRATION_TARGET's color entry was regenerated (the batch kept going
#      past the corrupt file and colors.js ran)
#
# Regression target: the fix in convert-webp-to-png.sh that runs each xargs
# worker with `; echo done` instead of `&& echo done` so magick failures stay
# scoped to that worker.

set -uo pipefail
source "$(dirname "$0")/../lib.sh"
require_integration_prereqs

CORRUPT_WEBP="images/migration/webp/zzz-smoke-corrupt-test.webp"
INTEGRATION_PNG="images/migration/png/$INTEGRATION_BASE.png"

cp scripts/update-tokens/colors.json /tmp/smoke-pre-colors.json

restore() {
  rm -f "$CORRUPT_WEBP" "images/migration/png/zzz-smoke-corrupt-test.png"
  cp /tmp/smoke-pre-colors.json scripts/update-tokens/colors.json
  rm -f /tmp/smoke-pre-colors.json "$INTEGRATION_PNG" /tmp/smoke-update.log
}
trap restore EXIT

# Plant a malformed webp (plain text, magick will reject it).
echo "this is not a webp" > "$CORRUPT_WEBP"

# Force INTEGRATION_TARGET to be reconverted by removing both its color entry
# and any cached PNG. Without this, convert-webp-to-png.sh would skip it and
# we would only exercise the corrupt-only path.
delete_color_entry
rm -f "$INTEGRATION_PNG"

yarn update-colors >/tmp/smoke-update.log 2>&1 || {
  echo "yarn update-colors failed — corrupt webp aborted the batch"
  tail -30 /tmp/smoke-update.log
  exit 1
}

color_entry_present || {
  echo "valid token's color was not regenerated — convert step likely aborted"
  tail -20 /tmp/smoke-update.log
  exit 1
}
