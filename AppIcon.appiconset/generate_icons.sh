#!/bin/bash
# Colors from Flare's spec
BG="#2D4739"
RING="#F5F0E1"
GLOW="#D4A574"

# Create base 1024x1024 icon
convert -size 1024x1024 xc:"$BG" \
    -gravity center \
    -fill "$RING" -draw "circle 512,512 512,400" \
    -fill "$BG"   -draw "circle 512,512 512,440" \
    -fill "$RING" -draw "circle 512,512 512,360" \
    -fill "$BG"   -draw "circle 512,512 512,400" \
    -fill "$RING" -draw "circle 512,512 512,320" \
    -fill "$BG"   -draw "circle 512,512 512,360" \
    -fill "$GLOW" -draw "circle 512,512 512,480" \
    -fill "$RING" -draw "circle 512,512 512,280" \
    -fill "$BG"   -draw "circle 512,512 512,320" \
    -blur 0x20 icon_1024.png

# Generate iOS sizes
for size in 180 120 60 29; do
    convert icon_1024.png -resize ${size}x${size} icon_${size}.png
done

# Generate Android sizes
for size in 192 144 96 72 48; do
    convert icon_1024.png -resize ${size}x${size} android_icon_${size}.png
done

# High contrast variant (darker background, brighter rings)
convert -size 1024x1024 xc:"#1a2e24" \
    -gravity center \
    -fill "#ffffff" -draw "circle 512,512 512,400" \
    -fill "#1a2e24" -draw "circle 512,512 512,440" \
    -fill "#ffffff" -draw "circle 512,512 512,360" \
    -fill "#1a2e24" -draw "circle 512,512 512,400" \
    -fill "#ffffff" -draw "circle 512,512 512,320" \
    -fill "#1a2e24" -draw "circle 512,512 512,360" \
    -fill "#ffcc88" -draw "circle 512,512 512,480" \
    -fill "#ffffff" -draw "circle 512,512 512,280" \
    -fill "#1a2e24" -draw "circle 512,512 512,320" \
    icon_1024_high_contrast.png
convert icon_1024_high_contrast.png -resize 180x180 icon_180_high_contrast.png

# Monochrome variant (black and white)
convert -size 1024x1024 xc:"#000000" \
    -gravity center \
    -fill "#ffffff" -draw "circle 512,512 512,400" \
    -fill "#000000" -draw "circle 512,512 512,440" \
    -fill "#ffffff" -draw "circle 512,512 512,360" \
    -fill "#000000" -draw "circle 512,512 512,400" \
    -fill "#ffffff" -draw "circle 512,512 512,320" \
    -fill "#000000" -draw "circle 512,512 512,360" \
    -fill "#888888" -draw "circle 512,512 512,480" \
    -fill "#ffffff" -draw "circle 512,512 512,280" \
    -fill "#000000" -draw "circle 512,512 512,320" \
    icon_1024_mono.png
convert icon_1024_mono.png -resize 180x180 icon_180_mono.png

echo "Icons generated successfully"
ls -la
