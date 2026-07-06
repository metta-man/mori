#!/bin/bash
set -euo pipefail

# Regenerate the active botanical app-icon family. Keep the app icon aligned with
# the paper-and-watercolor direction used throughout the app.

if ! command -v convert >/dev/null 2>&1; then
    echo "ImageMagick 'convert' is required." >&2
    exit 1
fi

PAPER_MASTER="icon_1024_paper_linework.png"
IOS_SIZES=(20 29 40 58 60 76 80 87 120 152 167 180)
ANDROID_SIZES=(48 72 96 144 192)

generate_family() {
    local master="$1"
    local suffix="$2"

    if [[ ! -f "$master" ]]; then
        echo "Missing master icon: $master" >&2
        exit 1
    fi

    for size in "${IOS_SIZES[@]}"; do
        convert "$master" -resize "${size}x${size}" "icon_${size}_${suffix}.png"
    done

    for size in "${ANDROID_SIZES[@]}"; do
        convert "$master" -resize "${size}x${size}" "android_icon_${size}_${suffix}.png"
    done
}

generate_family "$PAPER_MASTER" "paper_linework"

echo "Botanical app icons regenerated."
