#!/usr/bin/env bash
# colors.js is an entry script and must refuse to be imported. Verifies the
# guard by importing it from a separate module file (the real-world case).

set -uo pipefail

tmp=$(mktemp -d)
trap "rm -rf '$tmp'" EXIT

cat > "$tmp/importer.mjs" <<EOF
await import("file://$PWD/scripts/update-tokens/colors.js")
EOF

out=$(node "$tmp/importer.mjs" 2>&1 || true)
if ! echo "$out" | grep -q "entry script and must not be imported"; then
  echo "expected guard error not raised. Got:"
  echo "$out"
  exit 1
fi
