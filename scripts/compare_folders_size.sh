#!/bin/bash

# Define the directories
MASTER_DIR="images/master"
PNG_DIR="images/png"
WEBP_DIR="images/webp"

# Function to print folder sizes including total size
print_folder_sizes() {
    local dir=$1
    local label=$2

    echo "$label"
    echo "--------------------"

    total_size=0

    # Get folder sizes and iterate over them
    for folder in "$dir"/*; do
        if [ -d "$folder" ]; then
            size=$(du -sh "$folder" | awk '{print $1}')
            folder_name=$(basename "$folder")
            echo "  - $folder_name -> $size"

            # Calculate total size
            size_bytes=$(du -s "$folder" | awk '{print $1}')
            total_size=$((total_size + size_bytes))
        fi
    done

    # Convert total size to human-readable format
    total_size_human=$(du -sh "$dir" | awk '{print $1}')
    echo "Total Size: $total_size_human"
    echo
}

# Print sizes for WEBP, PNG, and MASTER directories
print_folder_sizes "$MASTER_DIR" "master"
print_folder_sizes "$WEBP_DIR" "webp"
print_folder_sizes "$PNG_DIR" "png"
