#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(git -C "$script_dir/.." rev-parse --show-toplevel 2>/dev/null || true)"
large_file_policy="${MORI_LARGE_FILE_POLICY:-fail}"
large_file_threshold_bytes="${MORI_LARGE_FILE_THRESHOLD_BYTES:-10485760}"
large_file_hard_limit_bytes="${MORI_LARGE_FILE_HARD_LIMIT_BYTES:-104857600}"

usage() {
  cat <<'EOF'
Usage: bash scripts/check_repo_hygiene.sh [options]

Checks the Git index and worktree for repository hygiene regressions.

Options:
  --large-file-policy warn|fail
      Files larger than 10 MiB fail by default. "warn" makes files between the
      configured threshold and the 100 MiB hard limit non-blocking.
  -h, --help

Environment:
  MORI_LARGE_FILE_POLICY             warn or fail (default: fail)
  MORI_LARGE_FILE_THRESHOLD_BYTES    default: 10485760 (10 MiB)
  MORI_LARGE_FILE_HARD_LIMIT_BYTES   default: 104857600 (100 MiB)
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --large-file-policy)
      if [ "$#" -lt 2 ]; then
        printf '::error::--large-file-policy requires warn or fail.\n'
        exit 2
      fi
      large_file_policy="$2"
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
  printf '::error::check_repo_hygiene.sh must live in the Mori repository scripts directory.\n'
  exit 2
fi

case "$large_file_policy" in
  warn|fail) ;;
  *)
    printf '::error::Invalid large-file policy %s; expected warn or fail.\n' "$large_file_policy"
    exit 2
    ;;
esac

case "$large_file_threshold_bytes" in
  ''|*[!0-9]*)
    printf '::error::MORI_LARGE_FILE_THRESHOLD_BYTES must be a positive integer.\n'
    exit 2
    ;;
esac

case "$large_file_hard_limit_bytes" in
  ''|*[!0-9]*)
    printf '::error::MORI_LARGE_FILE_HARD_LIMIT_BYTES must be a positive integer.\n'
    exit 2
    ;;
esac

if [ "$large_file_threshold_bytes" -le 0 ] || \
   [ "$large_file_hard_limit_bytes" -le "$large_file_threshold_bytes" ]; then
  printf '::error::Large-file thresholds must be positive and hard limit must exceed warning threshold.\n'
  exit 2
fi

cd "$repo_root"

failures=0

run_index_check() {
  local output
  if output=$(
    MORI_LARGE_FILE_POLICY="$large_file_policy" \
    MORI_LARGE_FILE_THRESHOLD_BYTES="$large_file_threshold_bytes" \
    MORI_LARGE_FILE_HARD_LIMIT_BYTES="$large_file_hard_limit_bytes" \
    ruby 2>&1 <<'RUBY'
policy = ENV.fetch("MORI_LARGE_FILE_POLICY")
threshold = Integer(ENV.fetch("MORI_LARGE_FILE_THRESHOLD_BYTES"), 10)
hard_limit = Integer(ENV.fetch("MORI_LARGE_FILE_HARD_LIMIT_BYTES"), 10)
tracked = IO.popen(["git", "ls-files", "-z"], &:read).split("\0").sort

denylist_patterns = {
  "local environment file" => %r{(?:\A|/)\.env(?:\..+)?\z},
  "local signing credential" => %r{(?:\A|/)(?:AuthKey[^/]*\.p8|[^/]+\.(?:p12|mobileprovision|provisionprofile))\z}i,
  "generated dependency directory" => %r{(?:\A|/)(?:node_modules|DerivedData|xcuserdata|\.swiftpm|\.vercel|\.venv|__pycache__|\.pytest_cache|\.pnpm-store|\.turbo)(?:/|\z)},
  "generated build or evidence directory" => %r{(?:\A|/)(?:\.build|build|dist|\.codex-build|artifacts|output|outputs|coverage|\.playwright-cli)(?:/|\z)},
  "Xcode archive or result" => %r{(?:\A|/)[^/]+\.(?:xcarchive|dSYM|xcresult)(?:/|\z)|\.(?:ipa|dSYM\.zip)\z}i,
  "Python bytecode" => /\.py[cod]\z/i,
  "local assistant settings" => %r{(?:\A|/)\.claude/settings\.local\.json\z},
  "generated log or temporary file" => /\.(?:log|tmp|swp)\z/i,
  "Xcode user state" => /\.(?:xcuserstate|xccheckout|moved-aside)\z/i
}

problems = []
nested_workflows = []
large_files = []

tracked.each do |path|
  if path.end_with?("/.DS_Store") || path == ".DS_Store"
    problems << "#{path}: tracked .DS_Store"
  end

  if path.match?(%r{(?:\A|/)\.github/workflows/}) && !path.start_with?(".github/workflows/")
    nested_workflows << path
  end

  denylist_patterns.each do |label, pattern|
    next unless path.match?(pattern)
    next if label == "local environment file" && path.end_with?(".env.example")
    problems << "#{path}: tracked #{label}"
  end

  next unless File.file?(path)
  size = File.size(path)
  large_files << [path, size] if size > threshold
end

unless nested_workflows.empty?
  problems.concat(nested_workflows.map { |path| "#{path}: nested workflow; workflows belong only in root .github/workflows/" })
end

large_failures = []
large_warnings = []
large_files.each do |path, size|
  message = "#{path}: #{size} bytes exceeds #{threshold}-byte tracked-file threshold"
  if size >= hard_limit
    large_failures << "#{message} and #{hard_limit}-byte hard limit"
  elsif policy == "fail"
    large_failures << message
  else
    large_warnings << message
  end
end

large_warnings.each { |message| warn "::warning::#{message}" }
problems.concat(large_failures)

abort problems.uniq.join("\n") unless problems.empty?
puts "#{tracked.length} tracked paths inspected; #{large_files.length} over the configured large-file threshold."
RUBY
  ); then
    printf 'OK: tracked denylist, workflow placement, and large-file policy\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::Repository index hygiene check failed\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_index_check

ds_store_paths="$(
  find . \
    -path './.git' -prune -o \
    -name .DS_Store -print |
    LC_ALL=C sort
)"

if [ -n "$ds_store_paths" ]; then
  printf '\n::error::.DS_Store files are not allowed in the repository worktree\n'
  printf '%s\n' "$ds_store_paths"
  printf 'Run bash scripts/clean_workspace.sh --apply to remove allowlisted workspace metadata.\n'
  failures=$((failures + 1))
else
  printf 'OK: worktree contains no .DS_Store files\n'
fi

if [ "$failures" -ne 0 ]; then
  printf '\nRepository hygiene gate failed with %d issue(s).\n' "$failures"
  exit 1
fi

printf '\nRepository hygiene gate passed.\n'
