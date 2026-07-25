#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
source_repo="$(git -C "$script_dir/../.." rev-parse --show-toplevel)"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/mori-hygiene-smoke.XXXXXX")"
trap 'rm -rf -- "$fixture_root"' EXIT

mkdir -p "$fixture_root/scripts"
rsync -a "$source_repo/scripts/check_repo_hygiene.sh" "$fixture_root/scripts/"

(
  cd "$fixture_root"
  git init -q
  git config user.name "Mori Hygiene Smoke"
  git config user.email "mori-hygiene-smoke@example.invalid"
  git add scripts
  git commit -qm "clean hygiene fixture"
  bash scripts/check_repo_hygiene.sh >/dev/null
)

ruby -e 'File.binwrite(ARGV.fetch(0), "\0" * 12_000)' "$fixture_root/large-fixture.bin"
(
  cd "$fixture_root"
  git add large-fixture.bin
)

warn_output="$(
  cd "$fixture_root" &&
    MORI_LARGE_FILE_THRESHOLD_BYTES=10000 \
    MORI_LARGE_FILE_HARD_LIMIT_BYTES=20000 \
    bash scripts/check_repo_hygiene.sh --large-file-policy warn 2>&1
)"
printf '%s\n' "$warn_output" | rg -q -- '::warning::large-fixture.bin'

set +e
large_fail_output="$(
  cd "$fixture_root" &&
    MORI_LARGE_FILE_THRESHOLD_BYTES=10000 \
    MORI_LARGE_FILE_HARD_LIMIT_BYTES=20000 \
    bash scripts/check_repo_hygiene.sh --large-file-policy fail 2>&1
)"
large_fail_status=$?
set -e
if [ "$large_fail_status" -eq 0 ] || ! printf '%s\n' "$large_fail_output" | rg -q -- \
  'large-fixture.bin: 12000 bytes exceeds 10000-byte'; then
  printf 'Expected the fail policy to reject the large-file fixture.\n%s\n' "$large_fail_output"
  exit 1
fi
(
  cd "$fixture_root"
  git rm -q -f large-fixture.bin
)

mkdir -p \
  "$fixture_root/nested/.github/workflows" \
  "$fixture_root/build" \
  "$fixture_root/Result.xcresult" \
  "$fixture_root/pkg/__pycache__" \
  "$fixture_root/coverage" \
  "$fixture_root/.pnpm-store" \
  "$fixture_root/.turbo" \
  "$fixture_root/.claude"
printf 'workflow\n' > "$fixture_root/nested/.github/workflows/ci.yml"
printf 'private key\n' > "$fixture_root/AuthKeyTEST.p8"
printf 'generated\n' > "$fixture_root/build/generated.txt"
printf 'result\n' > "$fixture_root/Result.xcresult/log.txt"
printf 'bytecode\n' > "$fixture_root/pkg/__pycache__/module.pyc"
printf 'coverage\n' > "$fixture_root/coverage/index.html"
printf 'pnpm\n' > "$fixture_root/.pnpm-store/state"
printf 'turbo\n' > "$fixture_root/.turbo/state"
printf '{}\n' > "$fixture_root/.claude/settings.local.json"
printf 'finder\n' > "$fixture_root/.DS_Store"

(
  cd "$fixture_root"
  git add -f \
    nested/.github/workflows/ci.yml \
    AuthKeyTEST.p8 \
    build/generated.txt \
    Result.xcresult/log.txt \
    pkg/__pycache__/module.pyc \
    coverage/index.html \
    .pnpm-store/state \
    .turbo/state \
    .claude/settings.local.json \
    .DS_Store
)

set +e
output="$(
  cd "$fixture_root" &&
    bash scripts/check_repo_hygiene.sh 2>&1
)"
gate_status=$?
set -e

if [ "$gate_status" -eq 0 ]; then
  printf 'Expected denylisted fixture paths to fail hygiene.\n'
  exit 1
fi

for expected in \
  'tracked .DS_Store' \
  'nested workflow' \
  'tracked local signing credential' \
  'tracked generated build or evidence directory' \
  'tracked Xcode archive or result' \
  'tracked Python bytecode' \
  'tracked generated dependency directory' \
  'tracked local assistant settings'; do
  if ! printf '%s\n' "$output" | rg -q -- "$expected"; then
    printf 'Missing hygiene diagnostic %s.\n%s\n' "$expected" "$output"
    exit 1
  fi
done

printf 'Repository hygiene denylist smoke check passed.\n'
