#!/usr/bin/env bash
# Reads an `rclone sync -v` log on stdin. Prints one Cloudflare purge body per
# line (`{"files":[...]}`), 30 URLs per batch, for files that changed or were
# deleted. New files are not cached yet and need no purge.
#
# Usage: purge-list.sh <destination-prefix> < rclone.log

set -euo pipefail

prefix=${1:?usage: purge-list.sh <destination-prefix>}
base="https://assets.squidrouter.com/$prefix"

sed -nE 's/^.* INFO  : (.*): (Copied \(replaced existing\)|Deleted)$/\1/p' \
  | jq -Rn --arg base "$base" '
      [inputs | select(length > 0) | "\($base)/\(split("/") | map(@uri) | join("/"))"]
      | select(length > 0)
      | _nwise(30)
      | {files: .}
    ' -c
