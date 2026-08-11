#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(git -C "$script_dir/.." rev-parse --show-toplevel 2>/dev/null || true)"
evidence_root=""

usage() {
  cat <<'EOF'
Usage: bash scripts/check_runtime_evidence.sh --evidence-root PATH

Validates a runtime-evidence archive for the checked-out commit, then runs the
runtime screenshot and compiled-artifact audits against that archive.

Archive contract:
  PATH/README.md       Non-empty archive notes.
  PATH/manifest.json   JSON with a full commit_sha matching git HEAD.

Evidence payload may live directly beneath PATH or beneath PATH/evidence:
  evidence/output/...
  evidence/outputs/...
  evidence/.codex-build/DerivedData/Build/Products/Debug-iphonesimulator/Mori.app

You may pass either the archive PATH or its PATH/evidence directory.

manifest.json may optionally contain a files array. Each entry may be a relative
path string or {"path":"...", "sha256":"..."}. Listed files and checksums are
validated before any evidence audit runs. A checksums object or SHA256SUMS file
is also supported; the canonical archive checksum file is MANIFEST.sha256.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
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
      printf '::error::Unknown option: %s\n\n' "$1"
      usage
      exit 2
      ;;
  esac
done

if [ -z "$repo_root" ] || [ "$repo_root" != "$(CDPATH= cd -- "$script_dir/.." && pwd -P)" ]; then
  printf '::error::check_runtime_evidence.sh must run from the tracked Mori repository.\n'
  exit 2
fi

if [ -z "$evidence_root" ]; then
  printf '::error::Runtime evidence is opt-in; pass --evidence-root PATH.\n\n'
  usage
  exit 2
fi

if [ ! -d "$evidence_root" ]; then
  printf '::error::Evidence root is not a directory: %s\n' "$evidence_root"
  exit 1
fi

requested_root="$(CDPATH= cd -- "$evidence_root" && pwd -P)"
archive_root="$requested_root"
payload_root="$requested_root"

if [ -s "$requested_root/README.md" ] && [ -s "$requested_root/manifest.json" ]; then
  archive_root="$requested_root"
  if [ -d "$requested_root/evidence" ]; then
    payload_root="$(CDPATH= cd -- "$requested_root/evidence" && pwd -P)"
  fi
elif [ "$(basename -- "$requested_root")" = "evidence" ] && \
     [ -s "$(dirname -- "$requested_root")/README.md" ] && \
     [ -s "$(dirname -- "$requested_root")/manifest.json" ]; then
  archive_root="$(CDPATH= cd -- "$(dirname -- "$requested_root")" && pwd -P)"
  payload_root="$requested_root"
fi

case "$payload_root" in
  "$archive_root"|"$archive_root"/*) ;;
  *)
    printf '::error::Evidence payload resolves outside its archive: %s\n' "$payload_root"
    exit 1
    ;;
esac

readme_path="$archive_root/README.md"
manifest_path="$archive_root/manifest.json"

if [ ! -s "$readme_path" ]; then
  printf '::error::Evidence archive README is missing or empty: %s\n' "$readme_path"
  exit 1
fi

if [ ! -s "$manifest_path" ]; then
  printf '::error::Evidence archive manifest is missing or empty: %s\n' "$manifest_path"
  exit 1
fi

cd "$repo_root"
current_sha="$(git rev-parse HEAD)"

manifest_sha="$(
  ruby -rjson - "$manifest_path" <<'RUBY'
manifest_path = ARGV.fetch(0)

begin
  manifest = JSON.parse(File.read(manifest_path, encoding: "UTF-8"))
rescue JSON::ParserError => error
  abort "#{manifest_path}: invalid JSON: #{error.message}"
end

unless manifest.is_a?(Hash)
  abort "#{manifest_path}: top-level JSON value must be an object"
end

schema_version = manifest["schema_version"]
if !schema_version.nil? && schema_version != 1
  abort "#{manifest_path}: unsupported schema_version #{schema_version.inspect}; expected 1"
end

commit_sha =
  manifest["commit_sha"] ||
  manifest["source_commit_sha"] ||
  manifest["source_main_sha"] ||
  manifest["git_sha"] ||
  manifest.dig("git", "sha") ||
  manifest.dig("git", "commit_sha") ||
  manifest.dig("source", "commit_sha") ||
  manifest.dig("source", "main_sha") ||
  manifest.dig("source", "sha")

unless commit_sha.is_a?(String) && commit_sha.match?(/\A[0-9a-fA-F]{40,64}\z/)
  abort "#{manifest_path}: commit_sha must be a full hexadecimal Git commit id"
end

puts commit_sha.downcase
RUBY
)"

if [ "$manifest_sha" != "$current_sha" ]; then
  printf '::error::Stale runtime evidence: archive commit SHA %s does not match current commit %s.\n' \
    "$manifest_sha" "$current_sha"
  printf 'Capture a new archive from the current commit; old-SHA evidence is not release proof.\n'
  exit 1
fi

ruby -rjson -rdigest - "$manifest_path" "$archive_root" "$payload_root" <<'RUBY'
manifest_path, archive_root, payload_root = ARGV
manifest = JSON.parse(File.read(manifest_path, encoding: "UTF-8"))

entries = manifest.fetch("files", [])
unless entries.is_a?(Array)
  abort "#{manifest_path}: files must be an array when present"
end

checksums = manifest.fetch("checksums", {})
unless checksums.is_a?(Hash)
  abort "#{manifest_path}: checksums must be an object when present"
end
checksums.each do |path, sha256|
  entries << {"path" => path, "sha256" => sha256}
end

%w[MANIFEST.sha256 SHA256SUMS].each do |checksum_filename|
  checksum_file = File.join(archive_root, checksum_filename)
  next unless File.file?(checksum_file)

  File.readlines(checksum_file, chomp: true).each_with_index do |line, index|
    next if line.empty? || line.start_with?("#")
    match = line.match(/\A([0-9a-fA-F]{64})\s+\*?(.+)\z/)
    abort "#{checksum_file}:#{index + 1}: invalid checksum line" if match.nil?
    entries << {"path" => match[2], "sha256" => match[1]}
  end
end

problems = []
entries.each_with_index do |entry, index|
  case entry
  when String
    relative_path = entry
    expected_sha256 = nil
  when Hash
    relative_path = entry["path"]
    expected_sha256 = entry["sha256"]
  else
    problems << "files[#{index}] must be a path string or object"
    next
  end

  unless relative_path.is_a?(String) && !relative_path.empty?
    problems << "files[#{index}].path must be a non-empty string"
    next
  end

  if relative_path.start_with?("/") || relative_path.split("/").include?("..")
    problems << "files[#{index}].path must stay inside the archive: #{relative_path.inspect}"
    next
  end

  absolute_path = File.join(archive_root, relative_path)
  if !File.file?(absolute_path) && payload_root != archive_root
    absolute_path = File.join(payload_root, relative_path)
  end
  unless File.file?(absolute_path)
    problems << "manifest file is missing: #{relative_path}"
    next
  end

  begin
    real_path = File.realpath(absolute_path)
    unless real_path == archive_root || real_path.start_with?("#{archive_root}/")
      problems << "manifest file resolves outside archive: #{relative_path}"
      next
    end
  rescue StandardError => error
    problems << "cannot resolve manifest file #{relative_path}: #{error.message}"
    next
  end

  next if expected_sha256.nil?
  unless expected_sha256.is_a?(String) && expected_sha256.match?(/\A[0-9a-fA-F]{64}\z/)
    problems << "files[#{index}].sha256 is not a full SHA-256 digest"
    next
  end

  actual_sha256 = Digest::SHA256.file(absolute_path).hexdigest
  if actual_sha256.downcase != expected_sha256.downcase
    problems << "checksum mismatch for #{relative_path}: expected #{expected_sha256}, got #{actual_sha256}"
  end
end

abort problems.join("\n") unless problems.empty?
RUBY

printf 'OK: evidence archive README, manifest, and checksums are valid for commit %s.\n' "$current_sha"

if ! git diff --quiet --ignore-submodules -- || ! git diff --cached --quiet --ignore-submodules --; then
  printf '::error::Dirty tracked worktree/index: runtime evidence only proves committed HEAD %s.\n' "$current_sha"
  printf 'Commit or discard tracked changes before using archived evidence as release proof.\n'
  exit 1
fi

export MORI_EVIDENCE_ROOT="$payload_root"

run_evidence_check() {
  local description="$1"
  shift

  printf '\n==> %s\n' "$description"
  "$@"
}

run_evidence_check "Main-surface screenshots" \
  bash scripts/check_main_surface_screenshot_audit.sh
run_evidence_check "Refreshed Log, Life Grid, and Pulse screenshots" \
  bash scripts/check_main_surface_refresh_screenshot_audit.sh
run_evidence_check "No repeated brand-mark card wallpaper screenshots" \
  bash scripts/check_card_no_logo_screenshot_audit.sh
run_evidence_check "Reset progressive-disclosure screenshots" \
  bash scripts/check_reset_simplification_screenshot_audit.sh
run_evidence_check "Pulse progressive-disclosure screenshots" \
  bash scripts/check_pulse_simplification_screenshot_audit.sh
run_evidence_check "System-flow screenshots" \
  bash scripts/check_system_flow_screenshot_audit.sh
run_evidence_check "Dynamic Type screenshots" \
  bash scripts/check_dynamic_type_screenshot_audit.sh
run_evidence_check "Web viewport screenshots" \
  bash scripts/check_web_screenshot_audit.sh
run_evidence_check "zh-Hant core runtime screenshots" \
  bash scripts/check_zh_hant_runtime_localization_audit.sh
run_evidence_check "zh-Hant Advanced App Limits screenshots" \
  bash scripts/check_zh_hant_advanced_app_limits_audit.sh
run_evidence_check "zh-Hant gate-settings screenshots" \
  bash scripts/check_zh_hant_gate_settings_audit.sh
run_evidence_check "zh-Hant Pulse and Recovery screenshots" \
  bash scripts/check_zh_hant_pulse_recovery_audit.sh
run_evidence_check "zh-Hant Recovery ready/detail screenshots" \
  bash scripts/check_zh_hant_recovery_ready_detail_audit.sh
run_evidence_check "zh-Hant Watch runtime screenshots" \
  bash scripts/check_zh_hant_watch_runtime_audit.sh
run_evidence_check "iOS Widget runtime evidence" \
  bash scripts/check_widget_runtime_audit.sh
run_evidence_check "Native accessibility semantics evidence" \
  bash scripts/check_accessibility_semantics_audit.sh
run_evidence_check "Native accessibility target-order evidence" \
  bash scripts/check_accessibility_target_order_audit.sh
run_evidence_check "Reduce Motion runtime/source evidence" \
  bash scripts/check_reduced_motion_contract.sh
run_evidence_check "Recovery HealthKit-shaped sample evidence" \
  bash scripts/check_recovery_healthkit_sample_audit.sh
run_evidence_check "zh-Hant Watch and Widget source evidence" \
  bash scripts/check_zh_hant_watch_widget_source_audit.sh
run_evidence_check "Compiled app and extension design assets" \
  bash scripts/check_compiled_design_artifacts.sh
run_evidence_check "Watch complication source and compiled assets" \
  bash scripts/check_watch_complication_source_audit.sh

printf '\nRuntime evidence gate passed for commit %s.\n' "$current_sha"
