#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
source_repo="$(git -C "$script_dir/../.." rev-parse --show-toplevel)"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/mori-runtime-evidence-smoke.XXXXXX")"
fixture_repo="$fixture_root/repo"
archive_root="$fixture_root/archive"
trap 'rm -rf -- "$fixture_root"' EXIT

mkdir -p "$fixture_repo/scripts/lib" "$archive_root/evidence"
rsync -a "$source_repo/scripts/check_runtime_evidence.sh" "$fixture_repo/scripts/"
rsync -a "$source_repo/scripts/lib/evidence_paths.sh" "$fixture_repo/scripts/lib/"

while IFS= read -r check_path; do
  if [ "$check_path" = "scripts/check_runtime_evidence.sh" ]; then
    continue
  fi
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'printf "stub evidence root: %s\n" "$MORI_EVIDENCE_ROOT"' \
    > "$fixture_repo/$check_path"
  chmod +x "$fixture_repo/$check_path"
done < <(
  rg -o --no-filename 'scripts/check_[a-z0-9_]+\.sh' \
    "$source_repo/scripts/check_runtime_evidence.sh" |
    LC_ALL=C sort -u
)

(
  cd "$fixture_repo"
  git init -q
  git config user.name "Mori Gate Smoke"
  git config user.email "mori-gate-smoke@example.invalid"
  git add scripts
  git commit -qm "runtime evidence smoke fixture"
)

printf 'Mori runtime evidence smoke fixture.\n' > "$archive_root/README.md"
printf 'checksum fixture\n' > "$archive_root/evidence/payload.txt"

current_sha="$(git -C "$fixture_repo" rev-parse HEAD)"

write_manifest() {
  local commit_sha="$1"
  printf '%s\n' \
    '{' \
    '  "schema_version": 1,' \
    "  \"commit_sha\": \"$commit_sha\"" \
    '}' > "$archive_root/manifest.json"
}

write_checksum_manifest() {
  local payload_sha
  payload_sha="$(shasum -a 256 "$archive_root/evidence/payload.txt" | awk '{print $1}')"
  printf '%s  %s\n' "$payload_sha" "evidence/payload.txt" > "$archive_root/MANIFEST.sha256"
}

run_success() {
  local supplied_root="$1"
  local output
  output="$(
    cd "$fixture_repo" &&
      bash scripts/check_runtime_evidence.sh --evidence-root "$supplied_root" 2>&1
  )"
  printf '%s\n' "$output" | rg -q -- 'evidence archive README, manifest, and checksums are valid'
  printf '%s\n' "$output" | rg -q -- 'stub evidence root: .*/archive/evidence'
  printf '%s\n' "$output" | rg -q -- 'Runtime evidence gate passed'
}

write_manifest "$current_sha"
write_checksum_manifest
run_success "$archive_root"
run_success "$archive_root/evidence"

printf 'tampered payload\n' > "$archive_root/evidence/payload.txt"
set +e
checksum_output="$(
  cd "$fixture_repo" &&
    bash scripts/check_runtime_evidence.sh --evidence-root "$archive_root" 2>&1
)"
checksum_status=$?
set -e
if [ "$checksum_status" -eq 0 ] || ! printf '%s\n' "$checksum_output" | rg -q -- 'checksum mismatch'; then
  printf 'Expected a MANIFEST.sha256 mismatch.\n%s\n' "$checksum_output"
  exit 1
fi

write_checksum_manifest
write_manifest "0000000000000000000000000000000000000000"
set +e
stale_output="$(
  cd "$fixture_repo" &&
    bash scripts/check_runtime_evidence.sh --evidence-root "$archive_root" 2>&1
)"
stale_status=$?
set -e
if [ "$stale_status" -eq 0 ] || ! printf '%s\n' "$stale_output" | rg -q -- 'Stale runtime evidence'; then
  printf 'Expected an explicit stale-evidence error.\n%s\n' "$stale_output"
  exit 1
fi

write_manifest "$current_sha"
printf '\n# dirty smoke fixture\n' >> "$fixture_repo/scripts/lib/evidence_paths.sh"
set +e
dirty_output="$(
  cd "$fixture_repo" &&
    bash scripts/check_runtime_evidence.sh --evidence-root "$archive_root" 2>&1
)"
dirty_status=$?
set -e
if [ "$dirty_status" -eq 0 ] || ! printf '%s\n' "$dirty_output" | rg -q -- 'Dirty tracked worktree/index'; then
  printf 'Expected dirty tracked evidence rejection.\n%s\n' "$dirty_output"
  exit 1
fi

printf 'Runtime evidence archive/evidence-root/checksum/stale/dirty smoke checks passed.\n'
