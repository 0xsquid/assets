#!/usr/bin/env bash
# purge-list.sh turns an rclone -v log into Cloudflare purge bodies. It must
# keep only replaced and deleted files, ignore new files and summary noise,
# prefix every path with the CDN URL, and split into batches of 30.

set -uo pipefail

script=scripts/sync/purge-list.sh
[ -f "$script" ] || { echo "missing $script"; exit 1; }

base="https://assets.squidrouter.com"

fixture=$(cat <<'LOG'
2026/10/05 10:00:00 INFO  : webp128/chains/chain-a.webp: Copied (new)
2026/10/05 10:00:00 INFO  : webp128/chains/chain-b.webp: Copied (replaced)
2026/10/05 10:00:01 INFO  : png128/wallets/wallet-c.png: Deleted
2026/10/05 10:00:01 INFO  : master/providers/provider d.svg: Copied (replaced)
2026/10/05 10:00:01 INFO  : There was nothing to transfer
2026/10/05 10:00:02 INFO  :
Transferred:   	  1.234 KiB / 1.234 KiB, 100%, 0 B/s, ETA -
Checks:              3 / 3, 100%
Deleted:             1 (files), 0 (dirs), 0 B (freed)
Transferred:            2 / 2, 100%
Elapsed time:         0.5s
LOG
)

out=$(printf '%s\n' "$fixture" | bash "$script" images) || { echo "script failed"; exit 1; }

[ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = "1" ] || { echo "expected 1 batch, got:"; echo "$out"; exit 1; }

files=$(printf '%s\n' "$out" | jq -r '.files[]')
expected=$(printf '%s\n' \
  "$base/images/webp128/chains/chain-b.webp" \
  "$base/images/png128/wallets/wallet-c.png" \
  "$base/images/master/providers/provider d.svg")
[ "$files" = "$expected" ] || { echo "unexpected files:"; echo "$files"; exit 1; }

# 31 replaced entries must produce 2 batches: 30 + 1.
big=$(for i in $(seq 1 31); do
  printf '2026/10/05 10:00:00 INFO  : pfps/webp/pfp%s.webp: Copied (replaced)\n' "$i"
done)
out=$(printf '%s\n' "$big" | bash "$script" squid-brand-assets) || { echo "script failed on 31 entries"; exit 1; }
sizes=$(printf '%s\n' "$out" | jq -c '.files | length' | tr '\n' ' ')
[ "$sizes" = "30 1 " ] || { echo "expected batches '30 1 ', got '$sizes'"; exit 1; }
printf '%s\n' "$out" | head -1 | jq -e --arg u "$base/squid-brand-assets/pfps/webp/pfp1.webp" '.files[0] == $u' >/dev/null \
  || { echo "wrong prefix on first batch"; exit 1; }

# An empty log must produce no output and exit 0.
out=$(printf 'Transferred: 0 / 0\n' | bash "$script" images) || { echo "script failed on empty log"; exit 1; }
[ -z "$out" ] || { echo "expected no output for empty log, got: $out"; exit 1; }
