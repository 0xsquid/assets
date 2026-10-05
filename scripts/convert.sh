#!/bin/bash

# check if required tools are installed
command -v rsvg-convert >/dev/null || { echo "rsvg-convert is required"; exit 1; }
command -v cwebp >/dev/null || { echo "cwebp is required"; exit 1; }

# Prefer ImageMagick 7's `magick`, fall back to IM6's `convert`. Both implement
# the same operators our scripts use; the indirection avoids IM7's deprecation
# warning that fires on every `convert` invocation.
MAGICK=$(command -v magick 2>/dev/null || command -v convert)
[ -n "$MAGICK" ] || { echo "ImageMagick is required (install via brew or apt)"; exit 1; }

SIZE=128
MASTER_DIR="images/master"

# Folders to include (only these will be converted)
INCLUDE_FOLDERS=("chains" "wallets" "providers" "cash")

# Extra sources outside images/master: "<source dir>:<output base>:<size>". Outputs go to <output base>/webp.
EXTRA_TARGETS=("squid-brand-assets/pfps:squid-brand-assets/pfps:256")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

print_color_message() {
    echo -e "${2}${1}${NC}"
}

# cwebp encodes from an intermediate PNG; keep it out of the repo.
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
trap 'echo ""; print_color_message "Conversion process interrupted." "$RED"; exit 1' SIGINT

for arg in "$@"; do
    case $arg in
        --size=*) SIZE="${arg#*=}" ;;
    esac
done

WEBP_DIR="images/webp$SIZE"

# convert_files <input dir> <output dir> <base dir> <size>
convert_files() {
    local input_dir=$1
    local output_dir=$2
    local base_dir=$3
    local size=$4

    for src in "$input_dir"/*.svg "$input_dir"/*.png; do
        [ -f "$src" ] || continue

        local ext=${src##*.}
        local filename=$(basename "$src" ".$ext")
        local subdir=$(dirname "${src#$base_dir/}")
        [ "$subdir" = "." ] && subdir=""
        local out="$output_dir/${subdir:+$subdir/}$filename.webp"

        [ -f "$out" ] && continue
        mkdir -p "$(dirname "$out")"

        local tmp_png="$TMP_DIR/$filename.png"
        if [ "$ext" = "svg" ]; then
            rsvg-convert -w "$size" -h "$size" "$src" -o "$tmp_png"
        else
            "$MAGICK" "$src" -resize "${size}x${size}" "$tmp_png"
        fi

        if [ $? -eq 0 ] && cwebp "$tmp_png" -o "$out" -quiet; then
            print_color_message "Converted $src to $out" "$GREEN"
        else
            print_color_message "Error converting $src to WebP" "$RED"
        fi
        rm -f "$tmp_png"
    done
}

echo "Converting images from: ${INCLUDE_FOLDERS[*]}"
for folder in "${INCLUDE_FOLDERS[@]}"; do
    folder_path="$MASTER_DIR/$folder"

    if [ ! -d "$folder_path" ]; then
        print_color_message "Warning: Folder $folder_path does not exist, skipping..." "$YELLOW"
        continue
    fi

    print_color_message "Processing folder: $folder" "$YELLOW"
    for dir in $(find "$folder_path" -type d); do
        convert_files "$dir" "$WEBP_DIR" "$MASTER_DIR" "$SIZE"
    done
done

for target in "${EXTRA_TARGETS[@]}"; do
    IFS=: read -r source_dir output_base target_size <<< "$target"

    if [ ! -d "$source_dir" ]; then
        print_color_message "Warning: Folder $source_dir does not exist, skipping..." "$YELLOW"
        continue
    fi

    print_color_message "Processing folder: $source_dir at ${target_size}px" "$YELLOW"
    convert_files "$source_dir" "$output_base/webp" "$source_dir" "$target_size"
done

echo "Conversion completed."
