#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/lib/evidence_paths.sh
app_bundle="$(mori_evidence_path ".codex-build/DerivedData/Build/Products/Debug-iphonesimulator/Mori.app" "${1:-}")"

if [ ! -d "$app_bundle" ]; then
  printf '\n::error::Compiled app bundle not found: %s\n' "$app_bundle"
  printf 'Pass an app bundle explicitly, or set MORI_EVIDENCE_ROOT to an archive containing .codex-build/DerivedData/Build/Products/Debug-iphonesimulator/Mori.app.\n'
  exit 1
fi

if ! command -v assetutil >/dev/null 2>&1; then
  printf '\n::error::assetutil is required to inspect compiled asset catalogs\n'
  exit 1
fi

failures=0

require_path() {
  local path="$1"

  if [ -e "$path" ]; then
    printf 'OK: compiled artifact exists: %s\n' "$path"
  else
    printf '\n::error::Missing compiled artifact: %s\n' "$path"
    failures=$((failures + 1))
  fi
}

check_assets_car() {
  local description="$1"
  local assets_car="$2"
  shift 2

  require_path "$assets_car"
  [ -f "$assets_car" ] || return 0

  local output
  if output=$(ruby -rjson - "$assets_car" "$@" 2>&1 <<'RUBY'
assets_car = ARGV.shift
required = ARGV
assets = JSON.parse(IO.popen(["assetutil", "--info", assets_car], &:read))
names = assets.filter_map { |asset| asset["Name"] }.uniq
missing = required - names
legacy = names.grep(/logo|wordmark|hourglass|funnel|time[_-]?seed|forest_rings|forest_canopy|moriArtLeafMark|moriArtBreatheOrb|moriArtFocusRing|moriArtRootsHero|moriCardWash|moriBotanicalCardWash/i)

if missing.empty? && legacy.empty?
  puts "#{names.length} compiled asset names inspected."
else
  problems = []
  problems << "Missing required compiled assets: #{missing.join(", ")}" unless missing.empty?
  problems << "Legacy compiled asset names present: #{legacy.join(", ")}" unless legacy.empty?
  abort problems.join("\n")
end
RUBY
  ); then
    printf 'OK: %s\n' "$description"
    printf '%s\n' "$output"
  else
    printf '\n::error::%s\n' "$description"
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

shield_configuration="$app_bundle/PlugIns/MoriShieldConfiguration.appex"
shield_action="$app_bundle/PlugIns/MoriShieldAction.appex"
widgets="$app_bundle/PlugIns/MoriWidgets.appex"
watch_app="$app_bundle/Watch/MoriWatch.app"
watch_widgets="$watch_app/PlugIns/MoriWatchWidgets.appex"

require_path "$shield_configuration"
require_path "$shield_action"
require_path "$widgets"
require_path "$watch_app"
require_path "$watch_widgets"

check_assets_car \
  "Main app carries no-logo paper-watercolor bitmap assets" \
  "$app_bundle/Assets.car" \
  moriPaperWash \
  moriCardPaperWash \
  moriCardSageWash \
  moriCardWarmWash \
  moriCardCoolWash \
  moriBotanicalScreenWash \
  moriButtonWash \
  moriWidgetPaperWash \
  moriWidgetBotanicalWash \
  moriIconLeaf \
  moriIconLockShield \
  moriIconBreathe

check_assets_car \
  "Shield configuration extension carries botanical bitmap shield assets" \
  "$shield_configuration/Assets.car" \
  moriIconLeaf \
  moriIconBreathe \
  moriIconLockShield \
  moriPaperWash \
  moriCardPaperWash \
  moriCardSageWash \
  moriCardWarmWash \
  moriCardCoolWash \
  moriBotanicalScreenWash \
  moriButtonWash \
  moriWidgetPaperWash \
  moriWidgetBotanicalWash

check_assets_car \
  "iOS widgets carry paper-watercolor bitmap assets" \
  "$widgets/Assets.car" \
  moriPaperWash \
  moriCardPaperWash \
  moriCardSageWash \
  moriCardWarmWash \
  moriCardCoolWash \
  moriBotanicalScreenWash \
  moriButtonWash \
  moriWidgetPaperWash \
  moriWidgetBotanicalWash \
  moriIconLeaf \
  moriIconPulse \
  moriIconRoots \
  moriIconJournal \
  moriIconLockShield \
  moriIconBreathe

check_assets_car \
  "Watch app carries paper-watercolor bitmap assets" \
  "$watch_app/Assets.car" \
  moriPaperWash \
  moriCardPaperWash \
  moriCardSageWash \
  moriCardWarmWash \
  moriCardCoolWash \
  moriBotanicalScreenWash \
  moriButtonWash \
  moriIconRoots \
  moriIconBell \
  moriIconBreathe \
  moriIconPulse \
  moriIconHeart

check_assets_car \
  "Watch widgets carry botanical bitmap complication assets" \
  "$watch_widgets/Assets.car" \
  moriButtonWash \
  moriIconRoots \
  moriIconPulse \
  moriIconHeart

if [ "$failures" -ne 0 ]; then
  printf '\nCompiled design artifact check failed with %d failure(s).\n' "$failures"
  exit 1
fi

printf '\nCompiled design artifact check passed.\n'
