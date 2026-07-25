#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(git -C "$script_dir/.." rev-parse --show-toplevel 2>/dev/null || true)"

if [ -z "$repo_root" ] || [ "$repo_root" != "$(CDPATH= cd -- "$script_dir/.." && pwd -P)" ]; then
  printf '::error::check_redesign_release_readiness.sh must run from the Mori repository.\n'
  exit 2
fi

cd "$repo_root"

skip_native_build=0
skip_web_build=0
skip_project_generate=0
existing_compiled_artifacts=0
evidence_root=""
# Keep an empty sentinel so Bash's nounset mode can safely expand the array
# when readiness exits before any temporary path has been registered.
temporary_paths=("")
remove_generated_web_dist=0

usage() {
  cat <<'EOF'
Usage: bash scripts/check_redesign_release_readiness.sh [options]

Runs the clean-clone release-readiness line:
  source gate + repo hygiene
  web test + app build + library build
  XcodeGen idempotence
  native build + compiled artifact inspection

Runtime evidence is deliberately separate and optional. It runs only when an
archive is supplied with --evidence-root.

Options:
  --skip-native-build          Skip xcodebuild and fresh compiled inspection.
  --skip-web-build             Skip web tests plus app/library builds.
  --skip-project-generate      Skip XcodeGen idempotence.
  --existing-compiled-artifacts
                               With --skip-native-build, inspect an existing app
                               bundle under MORI_DERIVED_DATA_PATH (or the legacy
                               .codex-build path when explicitly requested).
  --evidence-root PATH         Validate and run archived runtime evidence.
  -h, --help                   Show this help.

Environment:
  MORI_DERIVED_DATA_PATH       Optional explicit DerivedData path. When unset,
                               fresh native builds use a temporary directory.
  MORI_SIM_DESTINATION         Defaults to generic/platform=iOS Simulator.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-native-build)
      skip_native_build=1
      shift
      ;;
    --skip-web-build)
      skip_web_build=1
      shift
      ;;
    --skip-project-generate)
      skip_project_generate=1
      shift
      ;;
    --existing-compiled-artifacts)
      existing_compiled_artifacts=1
      shift
      ;;
    --evidence-root)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        printf '::error::--evidence-root requires a path.\n'
        exit 2
      fi
      evidence_root="$2"
      shift 2
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
done

cleanup() {
  local path
  for path in "${temporary_paths[@]}"; do
    if [ -n "$path" ] && [ -d "$path" ]; then
      rm -rf -- "$path"
    fi
  done

  if [ "$remove_generated_web_dist" -eq 1 ] && [ -d "$repo_root/www/dist" ]; then
    rm -rf -- "$repo_root/www/dist"
  fi
}
trap cleanup EXIT

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

log_step "Check shell gate syntax"
bash -n scripts/*.sh scripts/lib/*.sh scripts/tests/*.sh

if [ "$skip_project_generate" -eq 0 ]; then
  log_step "Check pinned XcodeGen version"
  require_command xcodegen
  source scripts/lib/xcodegen_version.sh
  mori_require_xcodegen_version "2.45.4" xcodegen
fi

log_step "Check repository hygiene"
bash scripts/check_repo_hygiene.sh

log_step "Check deterministic tracked design source"
bash scripts/check_design_direction.sh

if [ "$skip_web_build" -eq 0 ]; then
  log_step "Test web package"
  require_command pnpm
  if [ ! -d "$repo_root/www/dist" ]; then
    remove_generated_web_dist=1
  fi
  pnpm --dir www --config.node-linker=hoisted test

  log_step "Build web app"
  pnpm --dir www --config.node-linker=hoisted build:app

  log_step "Build web component library"
  pnpm --dir www --config.node-linker=hoisted build:library
else
  log_step "Skip web tests and app/library builds"
fi

native_project_path="$repo_root/Mori.xcodeproj"

if [ "$skip_project_generate" -eq 0 ]; then
  log_step "Compare tracked Xcode project with isolated generation"
  require_command xcodegen
  require_command rsync
  require_command diff
  require_command tar

  xcodegen_temp="$(mktemp -d "${TMPDIR:-/tmp}/mori-xcodegen-before-after.XXXXXX")"
  temporary_paths+=("$xcodegen_temp")
  xcodegen_worktree="$xcodegen_temp/worktree"
  mkdir -p "$xcodegen_worktree" "$xcodegen_temp/tracked" "$xcodegen_temp/first"

  (
    cd "$repo_root"
    tar -cf - -T <(
      git ls-files |
        while IFS= read -r tracked_path; do
          if [ -e "$tracked_path" ] || [ -L "$tracked_path" ]; then
            printf '%s\n' "$tracked_path"
          fi
        done
    )
  ) | (
    cd "$xcodegen_worktree"
    tar -xf -
  )
  rsync -a "$xcodegen_worktree/Mori.xcodeproj/" "$xcodegen_temp/tracked/Mori.xcodeproj/"

  xcodegen generate \
    --spec "$xcodegen_worktree/project.yml" \
    --project "$xcodegen_worktree" \
    --project-root "$xcodegen_worktree"
  if ! tracked_project_diff="$(
    diff -qr \
      -x xcuserdata \
      -x configuration \
      "$xcodegen_temp/tracked/Mori.xcodeproj" \
      "$xcodegen_worktree/Mori.xcodeproj"
  )"; then
    printf '\n::error::Tracked Mori.xcodeproj is out of sync with project.yml and tracked source.\n'
    printf '%s\n' "$tracked_project_diff"
    printf 'Regenerate Mori.xcodeproj with the repository XcodeGen version before release.\n'
    exit 1
  fi

  rsync -a "$xcodegen_worktree/Mori.xcodeproj/" "$xcodegen_temp/first/Mori.xcodeproj/"
  xcodegen generate \
    --spec "$xcodegen_worktree/project.yml" \
    --project "$xcodegen_worktree" \
    --project-root "$xcodegen_worktree"
  diff -qr \
    -x xcuserdata \
    -x configuration \
    "$xcodegen_temp/first/Mori.xcodeproj" \
    "$xcodegen_worktree/Mori.xcodeproj"
  native_project_path="$xcodegen_worktree/Mori.xcodeproj"
else
  log_step "Skip isolated Xcode project generation"
fi

sim_destination="${MORI_SIM_DESTINATION:-generic/platform=iOS Simulator}"

if [ "$skip_native_build" -eq 0 ]; then
  log_step "Build native iOS app"
  require_command xcodebuild
  require_command rg
  require_command tee
  source scripts/lib/native_build_runtime.sh

  if [ -n "${MORI_DERIVED_DATA_PATH:-}" ]; then
    derived_data_path="$MORI_DERIVED_DATA_PATH"
  else
    derived_data_temp="$(mktemp -d "${TMPDIR:-/tmp}/mori-derived-data.XXXXXX")"
    temporary_paths+=("$derived_data_temp")
    derived_data_path="$derived_data_temp/DerivedData"
  fi

  native_log_temp="$(mktemp -d "${TMPDIR:-/tmp}/mori-native-build-log.XXXXXX")"
  temporary_paths+=("$native_log_temp")
  simulator_build_log="$native_log_temp/simulator-build.log"

  set +e
  xcodebuild \
    -project "$native_project_path" \
    -scheme Mori \
    -configuration Debug \
    -destination "$sim_destination" \
    -derivedDataPath "$derived_data_path" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build 2>&1 | tee "$simulator_build_log"
  simulator_build_status=${PIPESTATUS[0]}
  set -e

  if [ "$simulator_build_status" -eq 0 ]; then
    :
  elif mori_is_missing_simulator_runtime_failure "$simulator_build_log"; then
    printf '\n::error::Native build blocked: the active Xcode installation lacks the matching iOS/watchOS simulator runtime required by the Mori scheme.\n'
    printf 'Install the exact runtime requested above, or run this gate on CI/Xcode with matching simulator runtimes.\n'
    if command -v xcrun >/dev/null 2>&1; then
      printf '\nInstalled simulator runtimes:\n'
      xcrun simctl list runtimes 2>/dev/null || true
    fi
    exit "$simulator_build_status"
  else
    printf '\n::error::Native simulator build failed for a non-runtime reason.\n'
    exit "$simulator_build_status"
  fi

  app_bundle="$derived_data_path/Build/Products/Debug-iphonesimulator/Mori.app"
  log_step "Inspect freshly compiled design artifacts"
  bash scripts/check_compiled_design_artifacts.sh "$app_bundle"
elif [ "$existing_compiled_artifacts" -eq 1 ]; then
  log_step "Inspect explicitly requested existing compiled artifacts"
  derived_data_path="${MORI_DERIVED_DATA_PATH:-.codex-build/DerivedData}"
  app_bundle="$derived_data_path/Build/Products/Debug-iphonesimulator/Mori.app"
  bash scripts/check_compiled_design_artifacts.sh "$app_bundle"
else
  log_step "Skip native build and compiled artifact inspection"
fi

if [ -n "$evidence_root" ]; then
  log_step "Validate archived runtime evidence"
  bash scripts/check_runtime_evidence.sh --evidence-root "$evidence_root"
else
  log_step "Skip archived runtime evidence (no --evidence-root supplied)"
fi

printf '\nRedesign release-readiness checks passed.\n'
