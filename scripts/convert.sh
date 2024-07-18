#!/bin/bash

# Define the directories
MASTER_DIR="images/master"
PNG_DIR="images/png"
WEBP_DIR="images/webp"

# Create the output directories if they don't exist
mkdir -p "$PNG_DIR"
mkdir -p "$WEBP_DIR"

# Function to convert SVG to PNG and WebP
convert_files() {
    local input_dir=$1
    local output_dir_png=$2
    local output_dir_webp=$3

    for svg_file in "$input_dir"/*.svg; do
        if [ -f "$svg_file" ]; then
            local filename=$(basename "$svg_file" .svg)
            local subpath=${svg_file#$MASTER_DIR/}
            local subdir=$(dirname "$subpath")

            mkdir -p "$output_dir_png/$subdir"
            mkdir -p "$output_dir_webp/$subdir"

            # Convert SVG to PNG
            rsvg-convert -w 128 -h 128 "$svg_file" -o "$output_dir_png/$subdir/$filename.png"

            # Convert PNG to WebP
            cwebp "$output_dir_png/$subdir/$filename.png" -o "$output_dir_webp/$subdir/$filename.webp" -quiet

            echo "Converted $svg_file to $output_dir_png/$subdir/$filename.png and $output_dir_webp/$subdir/$filename.webp"
        fi
    done
}

# Loop through all directories in the master folder
for dir in $(find "$MASTER_DIR" -type d); do
    convert_files "$dir" "$PNG_DIR" "$WEBP_DIR"
done

echo "Conversion completed."
