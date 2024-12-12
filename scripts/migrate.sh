#!/bin/bash

echo "Converting images to webp"

# Create the destination folder if it doesn't exist
mkdir -p images/migration/webp

# Read the JSON file and parse it
images=$(jq -c '.[]' new-token-images.json)

# Process each image sequentially
for image in ${images[@]}; do
    fileName=$(echo $image | jq -r '.fileName')
    imageUrl=$(echo $image | jq -r '.imageUrl')
    destination="images/migration/webp/${fileName}.webp"

    # Check if the file already exists
    if [ -f "$destination" ]; then
        echo "Image already exists for $fileName. Skipping download and conversion."
        continue
    fi

    # Check if imageUrl is empty or null
    if [ -z "$imageUrl" ] || [ "$imageUrl" == "null" ]; then
        echo "Image saving failed for $fileName: URL is empty or null."
        continue
    fi

    # Check HTTP status before downloading the image
    http_status=$(curl -s -o /dev/null -w "%{http_code}" "$imageUrl")

    if [ "$http_status" -ne 200 ]; then
        echo "Image download failed for $fileName: HTTP status $http_status. Skipping this image."
        continue
    fi

    # Download the image with a timeout
    wget --timeout=10 -q -O /tmp/$fileName $imageUrl

    # Check if the download was successful
    if [ $? -ne 0 ]; then
        echo "Image download failed for $fileName. Skipping this image."
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
        image/png)
            magick /tmp/$fileName -resize 128x128 /tmp/$fileName_resized.png
            cwebp /tmp/$fileName_resized.png -o "$destination" -quiet
            ;;
        image/jpeg)
            magick /tmp/$fileName -resize 128x128 /tmp/$fileName_resized.png
            cwebp /tmp/$fileName_resized.png -o "$destination" -quiet
            ;;
        image/gif)
            magick /tmp/$fileName[0] -resize 128x128 /tmp/$fileName_resized.png
            cwebp /tmp/$fileName_resized.png -o "$destination" -quiet
            ;;
        image/webp)
            magick /tmp/$fileName -resize 128x128 /tmp/$fileName_resized.webp
            mv /tmp/$fileName_resized.webp "$destination"
            ;;
        *)
            magick /tmp/$fileName -resize 128x128 /tmp/$fileName_resized.webp
            ;;
    esac

    if [ $? -eq 0 ]; then
        echo "Image saved for $fileName"
    else
        echo "Image saving failed for $fileName"
    fi

    # Clean up temporary resized image
    rm -f /tmp/$fileName_resized.png /tmp/$fileName_resized.webp /tmp/$fileName
done

echo "All images processed."
