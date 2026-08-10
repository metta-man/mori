#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(git -C "$script_dir/../.." rev-parse --show-toplevel)"
source "$repo_root/scripts/lib/xcodegen_version.sh"

fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/mori-xcodegen-version-smoke.XXXXXX")"
trap 'rm -rf -- "$fixture_root"' EXIT

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "Version: 2.45.4\n"' \
  > "$fixture_root/xcodegen-current"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "Version: 2.44.1\n"' \
  > "$fixture_root/xcodegen-old"
chmod +x "$fixture_root/xcodegen-current" "$fixture_root/xcodegen-old"

mori_require_xcodegen_version "2.45.4" "$fixture_root/xcodegen-current"

set +e
old_output="$(
  mori_require_xcodegen_version "2.45.4" "$fixture_root/xcodegen-old" 2>&1
)"
old_status=$?
set -e

if [ "$old_status" -eq 0 ] || ! printf '%s\n' "$old_output" | rg -q -- \
  'XcodeGen 2.45.4 is required.*found 2.44.1'; then
  printf 'Expected the old XcodeGen fixture to be rejected.\n%s\n' "$old_output"
  exit 1
fi

printf 'XcodeGen exact-version guard smoke check passed.\n'
