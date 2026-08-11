#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(git -C "$script_dir/../.." rev-parse --show-toplevel)"
source "$repo_root/scripts/lib/native_build_runtime.sh"

fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/mori-native-runtime-smoke.XXXXXX")"
trap 'rm -rf -- "$fixture_root"' EXIT

printf '%s\n' \
  'Ineligible destinations for the "Mori" scheme:' \
  'watchOS 26.5 is not installed. Download the platform in Xcode Settings.' \
  > "$fixture_root/watch-runtime.log"

printf '%s\n' \
  'This scheme builds an embedded Apple Watch app. watchOS 26.5 must be installed in order to run the scheme' \
  > "$fixture_root/embedded-watch-runtime.log"

printf '%s\n' \
  'xcodebuild: error: Unable to find a destination matching the provided destination specifier:' \
  '{ generic:1, platform:iOS Simulator }' \
  > "$fixture_root/destination.log"

printf '%s\n' \
  'Features/Today/TodayView.swift:42:1: error: cannot find type FakeType in scope' \
  > "$fixture_root/compile-error.log"

mori_is_missing_simulator_runtime_failure "$fixture_root/watch-runtime.log"
mori_is_missing_simulator_runtime_failure "$fixture_root/embedded-watch-runtime.log"
mori_is_missing_simulator_runtime_failure "$fixture_root/destination.log"

if mori_is_missing_simulator_runtime_failure "$fixture_root/compile-error.log"; then
  printf 'Compile errors must not be classified as missing simulator runtimes.\n'
  exit 1
fi

printf 'Native simulator-runtime environment classifier smoke check passed.\n'
