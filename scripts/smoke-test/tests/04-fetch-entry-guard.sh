#!/usr/bin/env bash
# fetch-new-tokens.js is an entry script and must refuse to be imported.

set -uo pipefail

tmp=$(mktemp -d)
trap "rm -rf '$tmp'" EXIT

cat > "$tmp/importer.mjs" <<EOF
await import("file://$PWD/scripts/update-tokens/fetch-new-tokens.js")
EOF

out=$(node "$tmp/importer.mjs" 2>&1 || true)
if ! echo "$out" | grep -q "entry script and must not be imported"; then
  echo "expected guard error not raised. Got:"
  echo "$out"
  exit 1
fi
