#!/bin/bash

# Define the directories
MASTER_DIR="images/master"
PNG_DIR="images/png"
WEBP_DIR="images/webp"
OVERRIDE=false

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
DIM_GREY='\033[2m'
NC='\033[0m' # No Color

# Function to print messages in colors
print_color_message() {
    local message=$1
    local color=$2
    echo -e "${color}${message}${NC}"
}

# Function to handle script termination
cleanup() {
    echo ""
    print_color_message "Conversion process interrupted. Cleaning up..." "$RED"
    # Add cleanup tasks here if necessary
    exit 1
}

# Trap SIGINT signal (Ctrl + C)
trap cleanup SIGINT

# Check if --override flag is provided
if [[ "$1" == "--override" ]]; then
    OVERRIDE=true
fi

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

            # Check if file exists and OVERRIDE is false
            if [[ -f "$output_dir_png/$subdir/$filename.png" && "$OVERRIDE" == false ]]; then
                # print_color_message "Skipped existing file: $output_dir_png/$subdir/$filename.png" "$DIM_GREY"
                # Print nothing (redirect output to /dev/null)
                echo "" >/dev/null
            else
                # Convert SVG to PNG
                rsvg-convert -w 128 -h 128 "$svg_file" -o "$output_dir_png/$subdir/$filename.png"
                if [ $? -eq 0 ]; then
                    print_color_message "Converted $svg_file to $output_dir_png/$subdir/$filename.png" "$GREEN"
                else
                    print_color_message "Error converting $svg_file" "$RED"
                fi
            fi

            # Check if file exists and OVERRIDE is false
            if [[ -f "$output_dir_webp/$subdir/$filename.webp" && "$OVERRIDE" == false ]]; then
                # print_color_message "Skipped existing file: $output_dir_webp/$subdir/$filename.webp" "$DIM_GREY"
                # Print nothing (redirect output to /dev/null)
                echo "" >/dev/null
            else
                # Convert PNG to WebP
                cwebp "$output_dir_png/$subdir/$filename.png" -o "$output_dir_webp/$subdir/$filename.webp" -quiet
                if [ $? -eq 0 ]; then
                    print_color_message "Converted $svg_file to $output_dir_webp/$subdir/$filename.webp" "$GREEN"
                else
                    print_color_message "Error converting $svg_file to WebP" "$RED"
                fi
            fi
        fi
    done
}

# Loop through all directories in the master folder
echo "Converting images"
for dir in $(find "$MASTER_DIR" -type d); do
    convert_files "$dir" "$PNG_DIR" "$WEBP_DIR"
done

echo "Conversion completed."
