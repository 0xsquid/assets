#!/bin/bash

echo "Converting images to webp"

# Create the destination folder if it doesn't exist
mkdir -p images/migration/webp

# Read the JSON file and parse it
images=$(jq -c '.[]' ./scripts/update-tokens/new-token-images.json)

# Get the total number of images
total_images=$(echo "$images" | wc -l | tr -d ' ')

# Initialize counter
processed_count=0

# Process each image sequentially
for image in ${images[@]}; do
    processed_count=$((processed_count + 1))
    fileName=$(echo $image | jq -r '.fileName')
    imageUrl=$(echo $image | jq -r '.imageUrl')
    destination="images/migration/webp/${fileName}.webp"

    # Calculate progress percentage
    progress=$((processed_count * 100 / total_images))

    # Display progress bar
    bar_width=50
    filled=$((progress * bar_width / 100))
    empty=$((bar_width - filled))
    printf "\r[%-${bar_width}s] %d%% (%d/%d)" $(printf '#%.0s' $(seq 1 $filled)) "$progress" "$processed_count" "$total_images"

    # Check if the file already exists
    if [ -f "$destination" ]; then
        echo -e "\nImage already exists for $fileName. Skipping download and conversion."
        continue
    fi

    # Check if imageUrl is empty or null
    if [ -z "$imageUrl" ] || [ "$imageUrl" == "null" ]; then
        echo -e "\nImage saving failed for $imageUrl: URL is empty or null."
        continue
    fi

    # Check HTTP status before downloading the image
    http_status=$(curl -s -o /dev/null -w "%{http_code}" "$imageUrl")
    if [ "$http_status" -lt 200 ] || [ "$http_status" -ge 400 ]; then
        echo -e "\nImage download failed for $imageUrl: HTTP status $http_status. Skipping this image."
        continue
    fi

    # Download the image with a timeout
    wget --timeout=10 -q -O /tmp/$fileName $imageUrl
    if [ $? -ne 0 ]; then
        echo -e "\nImage download failed for $imageUrl. Skipping this image."
        continue
    fi

    # Determine the format of the downloaded image
    mimeType=$(file --mime-type -b /tmp/$fileName)
    case $mimeType in
        image/svg+xml)
            rsvg-convert /tmp/$fileName -o /tmp/$fileName.png
            magick /tmp/$fileName.png -resize 128x128 /tmp/$fileName_resized.png
            cwebp /tmp/$fileName_resized.png -o "$destination" -quiet
            ;;
        image/png|image/jpeg)
            magick /tmp/$fileName -resize 128x128 /tmp/$fileName_resized.png
            cwebp /tmp/$fileName_resized.png -o "$destination" -quiet
            ;;
        image/gif)
            # Get gif fps
            fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "/tmp/$fileName")
            echo -e "\nFPS: $fps"
            fps_value=$(echo "scale=2; $fps" | bc)
            echo -e "\nFPS value: $fps_value"

            # Convert GIF to animated WebP
            ffmpeg -i /tmp/$fileName -vf "scale=128:128:force_original_aspect_ratio=decrease,fps=$fps_value" -loop 0 "$destination" -hide_banner -loglevel error
            ;;
        image/webp)
            magick /tmp/$fileName -resize 128x128 /tmp/$fileName_resized.webp
            mv /tmp/$fileName_resized.webp "$destination"
            ;;
        image/avif)
            ffmpeg -i /tmp/$fileName -vf "scale=128:128" "$destination" -hide_banner -loglevel error
            ;;
        *)
            magick /tmp/$fileName -resize 128x128 /tmp/$fileName_resized.webp
            ;;
    esac

    if [ $? -eq 0 ]; then
        echo -e "\nImage saved for $fileName"
    else
        echo -e "\nImage saving failed for $imageUrl"
    fi

    # Clean up temporary files
    rm -f /tmp/$fileName_resized.png /tmp/$fileName_resized.webp /tmp/$fileName
done

# Final message
echo -e "\nAll images processed."