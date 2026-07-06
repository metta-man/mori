#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

skip_native_build=0
skip_web_build=0
skip_project_generate=0
existing_compiled_artifacts=0

usage() {
  cat <<'EOF'
Usage: bash scripts/check_redesign_release_readiness.sh [options]

Runs the local release-readiness line for the current Mori redesign.

Options:
  --skip-native-build          Skip xcodebuild and compiled asset inspection.
  --skip-web-build             Skip pnpm web build.
  --skip-project-generate      Skip XcodeGen idempotence check.
  --existing-compiled-artifacts
                               Inspect the existing compiled app bundle without rebuilding.
  -h, --help                   Show this help.

Environment:
  MORI_DERIVED_DATA_PATH       Defaults to .codex-build/DerivedData
  MORI_SIM_DESTINATION         Defaults to generic/platform=iOS Simulator
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-native-build)
      skip_native_build=1
      ;;
    --skip-web-build)
      skip_web_build=1
      ;;
    --skip-project-generate)
      skip_project_generate=1
      ;;
    --existing-compiled-artifacts)
      existing_compiled_artifacts=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '\n::error::Unknown option: %s\n\n' "$1"
      usage
      exit 2
      ;;
  esac
  shift
done

log_step() {
  printf '\n==> %s\n' "$1"
}

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf '\n::error::Required command not found: %s\n' "$command_name"
    exit 1
  fi
}

require_file() {
  local path="$1"

  if [ ! -f "$path" ]; then
    printf '\n::error::Required file not found: %s\n' "$path"
    exit 1
  fi
}

derived_data_path="${MORI_DERIVED_DATA_PATH:-.codex-build/DerivedData}"
sim_destination="${MORI_SIM_DESTINATION:-generic/platform=iOS Simulator}"
app_bundle="$derived_data_path/Build/Products/Debug-iphonesimulator/Mori.app"

log_step "Check release source files"
require_file "MORI_REDESIGN_OPERATING_MODEL.md"
require_file "MORI_REDESIGN_RELEASE_AUDIT.md"
require_file "DesignSystem/MoriDesignSystemDocumentation.md"
require_file "brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md"
require_file "q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md"
require_file "scripts/check_accessibility_semantics_audit.sh"
require_file "scripts/check_accessibility_target_order_audit.sh"
require_file "scripts/check_reduced_motion_contract.sh"
require_file "scripts/check_reset_simplification_screenshot_audit.sh"
require_file "scripts/check_pulse_simplification_screenshot_audit.sh"
require_file "scripts/check_zh_hant_runtime_localization_audit.sh"
require_file "scripts/check_zh_hant_advanced_app_limits_audit.sh"
require_file "scripts/check_zh_hant_gate_settings_audit.sh"
require_file "scripts/check_zh_hant_pulse_recovery_audit.sh"
require_file "scripts/check_zh_hant_recovery_ready_detail_audit.sh"
require_file "scripts/check_recovery_healthkit_sample_audit.sh"
require_file "scripts/check_zh_hant_watch_widget_source_audit.sh"
require_file "scripts/check_zh_hant_watch_runtime_audit.sh"
require_file "scripts/check_watch_complication_source_audit.sh"
require_file "scripts/check_widget_runtime_audit.sh"
require_file "project.yml"

if [ "$skip_project_generate" -eq 0 ]; then
  log_step "Check generated Xcode project idempotence"
  require_command xcodegen
  require_command rsync
  require_command diff

  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/mori-xcodegen-before.XXXXXX")"
  trap 'rm -rf "$temp_dir"' EXIT
  rsync -a Mori.xcodeproj/ "$temp_dir/Mori.xcodeproj/"
  xcodegen generate
  diff -qr "$temp_dir/Mori.xcodeproj" Mori.xcodeproj
else
  log_step "Skip generated Xcode project idempotence"
fi

log_step "Check design direction gate syntax"
bash -n scripts/check_design_direction.sh

log_step "Check design direction"
bash scripts/check_design_direction.sh

if [ "$skip_web_build" -eq 0 ]; then
  log_step "Build web UI package"
  require_command pnpm
  pnpm --dir www build
else
  log_step "Skip web build"
fi

if [ "$skip_native_build" -eq 0 ]; then
  log_step "Build native iOS app"
  require_command xcodebuild
  xcodebuild \
    -project Mori.xcodeproj \
    -scheme Mori \
    -configuration Debug \
    -destination "$sim_destination" \
    -derivedDataPath "$derived_data_path" \
    build

  log_step "Inspect compiled design artifacts"
  bash scripts/check_compiled_design_artifacts.sh "$app_bundle"
elif [ "$existing_compiled_artifacts" -eq 1 ]; then
  log_step "Inspect existing compiled design artifacts"
  bash scripts/check_compiled_design_artifacts.sh "$app_bundle"
else
  log_step "Skip native build and compiled artifact inspection"
fi

printf '\nRedesign release-readiness checks passed.\n'
