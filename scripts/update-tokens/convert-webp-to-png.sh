#!/bin/bash
echo -e "\nConverting WEBPs to PNGs"
WEBP_FOLDER="images/migration/webp"
PNG_FOLDER="images/migration/png"
COLORS_JSON="scripts/update-tokens/colors.json"

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

# Parse the JSON file to extract existing keys
EXISTING_KEYS=$(jq -r '.tokens | keys[]' "$COLORS_JSON")

# Get the total number of .webp files to process
total_files=$(find "$WEBP_FOLDER" -maxdepth 1 -name "*.webp" | wc -l | tr -d ' ')

# Initialize counter
processed_count=0

# Convert all .webp images to .png, skipping those already in colors.json
for file in "$WEBP_FOLDER"/*.webp; do
  if [ -f "$file" ]; then
    filename=$(basename -- "$file")
    base="${filename%.*}"
    target_file="$PNG_FOLDER/$base.png"

    # Calculate progress percentage
    processed_count=$((processed_count + 1))
    progress=$((processed_count * 100 / total_files))

    # Display progress bar
    bar_width=50
    filled=$((progress * bar_width / 100))
    empty=$((bar_width - filled))
    printf "\r[%-${bar_width}s] %d%% (%d/%d)" $(printf '#%.0s' $(seq 1 $filled)) "$progress" "$processed_count" "$total_files"

    # Check if the key exists in colors.json
    if echo "$EXISTING_KEYS" | grep -q "^$base$"; then
      # echo -e "\nSkipping $file: Key '$base' exists in $COLORS_JSON"
      continue
    fi

    # echo -e "\nConverting $file to $target_file..."
    dwebp "$file" -o "$target_file" -quiet

    # Check if the conversion was successful
    # if [ $? -eq 0 ]; then
    #   echo "Converted: $file -> $target_file"
    # else
    #   echo "Failed to convert: $file"
    # fi
  fi
done

# Final message
echo -e "\nConversion complete."