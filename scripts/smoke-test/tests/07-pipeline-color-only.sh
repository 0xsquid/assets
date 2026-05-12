#!/usr/bin/env bash
# Only the colors.json entry is missing (webp intact) → fetch-new-tokens.js
# does nothing (webp already there), but colors.js re-extracts the color
# from the existing image.

set -uo pipefail
source "$(dirname "$0")/../lib.sh"
require_integration_prereqs

pipeline_setup
trap pipeline_restore EXIT

delete_color_entry

yarn update-tokens >/tmp/smoke-update.log 2>&1 || {
  echo "yarn update-tokens failed"
  tail -20 /tmp/smoke-update.log
  exit 1
}

color_entry_present || { echo "color entry not regenerated"; exit 1; }
