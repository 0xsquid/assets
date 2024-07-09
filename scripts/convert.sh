#!/bin/bash

# Create output directory if it doesn't exist
mkdir -p output

# Loop through all SVG files in the current directory
for file in *.svg; do
    # Extract the filename without extension
    filename=$(basename "$file" .svg)
    # Convert and resize the SVG to PNG, saving it in the output directory
    rsvg-convert -w 128 -h 128 "$file" -o "output/${filename}.png"
done

echo "Conversion and resizing completed."
