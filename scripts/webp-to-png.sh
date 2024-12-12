#!/bin/bash

echo "Converting webp images to PNG"

# Create the destination directory if it doesn't exist
mkdir -p ./images/migration/png

# Loop through all .webp files in the source directory
for file in ./images/migration/webp/*.webp; do
    # Extract the filename without extension
    filename=$(basename "$file" .webp)
    destination="./images/migration/png/$filename.png"

    # Check if the .png file already exists
    if [ -f "$destination" ]; then
        continue
    fi

    # Convert to .png and save in the destination directory
    magick "$file" "$destination"
done

echo "Conversion complete!"
