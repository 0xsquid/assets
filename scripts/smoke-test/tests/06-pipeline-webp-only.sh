#!/usr/bin/env bash
# Only the webp is missing (color entry intact) → fetch-new-tokens.js detects
# it and save-new-tokens.sh re-downloads. The color entry stays as-is because
# colors.js filters tokens with a saved bgColor.

set -uo pipefail
source "$(dirname "$0")/../lib.sh"
require_integration_prereqs

pipeline_setup
trap pipeline_restore EXIT

rm "$INTEGRATION_TARGET"

yarn update-tokens >/tmp/smoke-update.log 2>&1 || {
  echo "yarn update-tokens failed"
  tail -20 /tmp/smoke-update.log
  exit 1
}

[ -f "$INTEGRATION_TARGET" ] || { echo "webp not restored"; exit 1; }
