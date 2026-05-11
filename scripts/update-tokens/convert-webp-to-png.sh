#!/bin/bash
set -euo pipefail
echo -e "\nConverting WEBPs to PNGs"
WEBP_FOLDER="images/migration/webp"
PNG_FOLDER="images/migration/png"
COLORS_JSON="scripts/update-tokens/colors.json"
PARALLELISM=8

# Ensure the source folder exists
if [ ! -d "$WEBP_FOLDER" ]; then
  echo "Error: Source folder '$WEBP_FOLDER' does not exist."
  exit 1
fi

# Ensure the JSON file exists
if [ ! -f "$COLORS_JSON" ]; then
  echo "Error: JSON file '$COLORS_JSON' does not exist."
  exit 1
fi

# Create the target folder if it doesn't exist
mkdir -p "$PNG_FOLDER"

WORK_LIST=$(mktemp)
TOKENS_WITH_COLOR=$(mktemp)
ALL_BASES=$(mktemp)
NEEDS_COLOR=$(mktemp)
trap 'rm -f "$WORK_LIST" "$TOKENS_WITH_COLOR" "$ALL_BASES" "$NEEDS_COLOR"' EXIT

echo "Scanning $WEBP_FOLDER..."

# Parse the JSON file to extract token keys that already have a non-empty bgColor
jq -r '.tokens | to_entries[] | select(.value.bgColor != null and .value.bgColor != "") | .key' \
  "$COLORS_JSON" | LC_ALL=C sort -u > "$TOKENS_WITH_COLOR"

# Collect every webp basename in one pass — use parameter expansion (no fork per file)
for file in "$WEBP_FOLDER"/*.webp; do
  [ -f "$file" ] || continue
  base=${file##*/}
  printf '%s\n' "${base%.webp}"
done | LC_ALL=C sort -u > "$ALL_BASES"

echo "Found $(wc -l < "$ALL_BASES" | tr -d ' ') webp files. Computing work list..."

# Subtract tokens that already have a saved bgColor — leaves only bases that still need processing
LC_ALL=C comm -23 "$ALL_BASES" "$TOKENS_WITH_COLOR" > "$NEEDS_COLOR"

# Build the (source, target) pairs, skipping files whose PNG already exists
while IFS= read -r base; do
  target="$PNG_FOLDER/$base.png"
  [ -f "$target" ] && continue
  printf '%s/%s.webp %s\n' "$WEBP_FOLDER" "$base" "$target" >> "$WORK_LIST"
done < "$NEEDS_COLOR"

total=$(wc -l < "$WORK_LIST" | tr -d ' ')
if [ "$total" -eq 0 ]; then
  echo "Nothing to convert."
  exit 0
fi

echo "Converting $total file(s) with $PARALLELISM parallel workers..."

# Convert WEBP to PNG in parallel (extracting only the first frame if animated).
# File names are <chainId>_<address>.webp — no spaces — so whitespace-separated
# lines are safe to feed to xargs. Each worker emits a marker on stdout when
# it finishes so the progress bar can advance.
xargs -P "$PARALLELISM" -L 1 -a "$WORK_LIST" bash -c 'magick "$0[0]" "$1" && echo done' | \
  while read -r _; do
    processed_count=$((${processed_count:-0} + 1))

    # Calculate progress percentage
    progress=$((processed_count * 100 / total))

    # Display progress bar
    bar_width=50
    filled=$((progress * bar_width / 100))
    hashes=""
    if [ "$filled" -gt 0 ]; then
      hashes=$(printf '#%.0s' $(seq 1 $filled))
    fi
    printf "\r[%-${bar_width}s] %d%% (%d/%d)" "$hashes" "$progress" "$processed_count" "$total"
  done

# Final message
echo -e "\nConversion complete."
