#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(git -C "$script_dir/.." rev-parse --show-toplevel 2>/dev/null || true)"
apply=0
include_evidence=0

usage() {
  cat <<'EOF'
Usage: bash scripts/clean_workspace.sh [--apply] [--include-evidence]

Safely cleans an explicit allowlist of ignored Mori build/cache paths. The
default is a dry run.

Options:
  --apply              Remove the listed paths instead of only printing them.
  --include-evidence   Also include .playwright-cli/, output/, outputs/, and artifacts/.
                      Evidence is never removed without this separate flag.
  -h, --help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --apply)
      apply=1
      shift
      ;;
    --include-evidence)
      include_evidence=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '::error::Unknown option: %s\n\n' "$1"
      usage
      exit 2
      ;;
  esac
done

expected_root="$(CDPATH= cd -- "$script_dir/.." && pwd -P)"
if [ -z "$repo_root" ] || [ "$repo_root" != "$expected_root" ]; then
  printf '::error::Refusing cleanup: scripts directory is not at the Mori Git root.\n'
  exit 2
fi

case "$repo_root" in
  /|'')
    printf '::error::Refusing cleanup at an unsafe repository root: %s\n' "$repo_root"
    exit 2
    ;;
esac

if [ ! -e "$repo_root/.git" ]; then
  printf '::error::Refusing cleanup: Git metadata is missing at %s\n' "$repo_root"
  exit 2
fi

cd "$repo_root"

cleanup_targets=(
  "$repo_root/.codex-build"
  "$repo_root/build"
  "$repo_root/DerivedData"
  "$repo_root/.build"
  "$repo_root/.swiftpm"
  "$repo_root/node_modules"
  "$repo_root/www/node_modules"
  "$repo_root/www/dist"
  "$repo_root/.vercel"
  "$repo_root/www/.vercel"
  "$repo_root/.venv"
  "$repo_root/.pnpm-store"
  "$repo_root/.turbo"
  "$repo_root/coverage"
  "$repo_root/.pytest_cache"
  "$repo_root/.mypy_cache"
  "$repo_root/.ruff_cache"
  "$repo_root/Mori.xcodeproj/xcuserdata"
)

if [ "$include_evidence" -eq 1 ]; then
  cleanup_targets+=(
    "$repo_root/.playwright-cli"
    "$repo_root/output"
    "$repo_root/outputs"
    "$repo_root/artifacts"
  )
fi

while IFS= read -r metadata_path; do
  cleanup_targets+=("$repo_root/${metadata_path#./}")
done < <(
  find . \
    -path './.git' -prune -o \
    -path './.codex-build' -prune -o \
    -path './build' -prune -o \
    -path './DerivedData' -prune -o \
    -path './.build' -prune -o \
    -path './.swiftpm' -prune -o \
    -path './node_modules' -prune -o \
    -path './www/node_modules' -prune -o \
    -path './www/dist' -prune -o \
    -path './.vercel' -prune -o \
    -path './www/.vercel' -prune -o \
    -path './.playwright-cli' -prune -o \
    -path './.venv' -prune -o \
    -path './.pnpm-store' -prune -o \
    -path './.turbo' -prune -o \
    -path './coverage' -prune -o \
    -path './output' -prune -o \
    -path './outputs' -prune -o \
    -path './artifacts' -prune -o \
    \( -name .DS_Store -o -name '*.log' -o -name '*.tmp' -o -name '*.swp' \) -print |
    LC_ALL=C sort
)

while IFS= read -r cache_dir; do
  cleanup_targets+=("$repo_root/${cache_dir#./}")
done < <(
  find . \
    -path './.git' -prune -o \
    -path './.codex-build' -prune -o \
    -path './build' -prune -o \
    -path './DerivedData' -prune -o \
    -path './.build' -prune -o \
    -path './.swiftpm' -prune -o \
    -path './node_modules' -prune -o \
    -path './www/node_modules' -prune -o \
    -path './www/dist' -prune -o \
    -path './.playwright-cli' -prune -o \
    -path './.venv' -prune -o \
    -path './.pnpm-store' -prune -o \
    -path './.turbo' -prune -o \
    -path './coverage' -prune -o \
    -path './output' -prune -o \
    -path './outputs' -prune -o \
    -path './artifacts' -prune -o \
    -type d \( -name __pycache__ -o -name .pytest_cache -o -name .mypy_cache -o -name .ruff_cache \) \
    -prune -print |
    LC_ALL=C sort
)

if [ "$include_evidence" -eq 0 ]; then
  printf 'Evidence directories are preserved. Add --include-evidence to include .playwright-cli/, output/, outputs/, and artifacts/.\n'
else
  printf '::warning::Evidence cleanup is enabled for .playwright-cli/, output/, outputs/, and artifacts/.\n'
fi

found=0
removed=0
refused=0

for target in "${cleanup_targets[@]}"; do
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    continue
  fi

  case "$target" in
    "$repo_root"/*) ;;
    *)
      printf '::error::Refusing path outside repository root: %s\n' "$target"
      refused=$((refused + 1))
      continue
      ;;
  esac

  relative_path="${target#"$repo_root"/}"
  case "$relative_path" in
    ''|.|..|../*|*/../*)
      printf '::error::Refusing unsafe cleanup target: %s\n' "$target"
      refused=$((refused + 1))
      continue
      ;;
  esac

  tracked_paths="$(git ls-files -- "$relative_path")"
  if [ -n "$tracked_paths" ]; then
    printf '::error::Refusing cleanup target containing tracked content: %s\n' "$relative_path"
    printf '%s\n' "$tracked_paths"
    refused=$((refused + 1))
    continue
  fi

  found=$((found + 1))
  if [ "$apply" -eq 0 ]; then
    printf 'Would remove: %s\n' "$relative_path"
    continue
  fi

  if [ -d "$target" ] && [ ! -L "$target" ]; then
    rm -rf -- "$target"
  else
    rm -f -- "$target"
  fi
  printf 'Removed: %s\n' "$relative_path"
  removed=$((removed + 1))
done

if [ "$refused" -ne 0 ]; then
  printf '\nWorkspace cleanup refused %d unsafe or tracked target(s).\n' "$refused"
  exit 1
fi

if [ "$apply" -eq 0 ]; then
  printf '\nDry run complete: %d allowlisted path(s) would be removed; no files changed.\n' "$found"
else
  printf '\nWorkspace cleanup complete: %d allowlisted path(s) removed. Removal is not recoverable by this script.\n' "$removed"
fi
