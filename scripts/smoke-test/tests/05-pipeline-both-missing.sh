#!/usr/bin/env bash
# Both the webp file and its colors.json entry are missing → yarn update-tokens
# should restore both. Exercises the full pipeline end-to-end.

set -uo pipefail
source "$(dirname "$0")/../lib.sh"
require_integration_prereqs

pipeline_setup
trap pipeline_restore EXIT

rm "$INTEGRATION_TARGET"
delete_color_entry

yarn update-tokens >/tmp/smoke-update.log 2>&1 || {
  echo "yarn update-tokens failed"
  tail -20 /tmp/smoke-update.log
  exit 1
}

[ -f "$INTEGRATION_TARGET" ] || { echo "webp not restored"; exit 1; }
color_entry_present || { echo "color entry not regenerated"; exit 1; }
