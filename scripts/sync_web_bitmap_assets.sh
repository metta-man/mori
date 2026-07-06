#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mode="${1:-sync}"
if [ "$mode" != "sync" ] && [ "$mode" != "--check" ]; then
  printf 'Usage: %s [sync|--check]\n' "$0" >&2
  exit 2
fi

web_icon_dir="www/src/assets/icons"
failures=0
updates=0

asset_mappings=(
  "moriIconBell:mori-icon-bell"
  "moriIconBreathe:mori-icon-breathe"
  "moriIconChevron:mori-icon-chevron"
  "moriIconFocus:mori-icon-focus"
  "moriIconHaptics:mori-icon-haptics"
  "moriIconHeart:mori-icon-heart"
  "moriIconHome:mori-icon-home"
  "moriIconJournal:mori-icon-journal"
  "moriIconLeaf:mori-icon-leaf"
  "moriIconLockShield:mori-icon-lock-shield"
  "moriIconMinus:mori-icon-minus"
  "moriIconPause:mori-icon-pause"
  "moriIconPlay:mori-icon-play"
  "moriIconPlus:mori-icon-plus"
  "moriIconPulse:mori-icon-pulse"
  "moriIconQuiet:mori-icon-quiet"
  "moriIconRefresh:mori-icon-refresh"
  "moriIconRoots:mori-icon-roots"
  "moriIconSettings:mori-icon-settings"
  "moriIconSound:mori-icon-sound"
  "moriIconStop:mori-icon-stop"
  "moriIconTimer:mori-icon-timer"
)

if [ "$mode" = "sync" ]; then
  mkdir -p "$web_icon_dir"
fi

for mapping in "${asset_mappings[@]}"; do
  source_name="${mapping%%:*}"
  web_name="${mapping##*:}"
  source_path="Shared/MoriGeneratedArt.xcassets/${source_name}.imageset/${source_name}@3x.png"
  web_path="${web_icon_dir}/${web_name}.png"

  if [ ! -f "$source_path" ]; then
    printf '::error::Missing canonical bitmap asset: %s\n' "$source_path"
    failures=$((failures + 1))
    continue
  fi

  if [ "$mode" = "--check" ]; then
    if [ ! -f "$web_path" ]; then
      printf '::error::Missing mirrored web bitmap asset: %s\n' "$web_path"
      failures=$((failures + 1))
    elif ! cmp -s "$source_path" "$web_path"; then
      printf '::error::Outdated mirrored web bitmap asset: %s\n' "$web_path"
      failures=$((failures + 1))
    else
      printf 'OK: mirrored bitmap asset matches: %s\n' "$web_path"
    fi
  elif ! cmp -s "$source_path" "$web_path" 2>/dev/null; then
    cp "$source_path" "$web_path"
    printf 'Updated: %s\n' "$web_path"
    updates=$((updates + 1))
  else
    printf 'OK: already synced: %s\n' "$web_path"
  fi
done

if [ "$failures" -ne 0 ]; then
  printf '\nBitmap asset mirror check failed with %d issue(s).\n' "$failures"
  exit 1
fi

if [ "$mode" = "--check" ]; then
  printf '\nBitmap asset mirror check passed.\n'
else
  printf '\nBitmap asset sync complete. Updated %d file(s).\n' "$updates"
fi
