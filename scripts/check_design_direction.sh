#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
repo_root="$(git -C "$script_dir/.." rev-parse --show-toplevel 2>/dev/null || true)"

if [ -z "$repo_root" ] || [ "$repo_root" != "$(CDPATH= cd -- "$script_dir/.." && pwd -P)" ]; then
  printf '::error::check_design_direction.sh must live in the tracked Mori repository scripts directory.\n'
  exit 2
fi

cd "$repo_root"

failures=0

ok() {
  printf 'OK: %s\n' "$1"
}

fail() {
  printf '\n::error::%s\n' "$1"
  if [ "$#" -gt 1 ] && [ -n "$2" ]; then
    printf '%s\n' "$2"
  fi
  failures=$((failures + 1))
}

run_check() {
  local description="$1"
  shift

  local output
  if output=$("$@" 2>&1); then
    ok "$description"
    if [ -n "$output" ]; then
      printf '%s\n' "$output"
    fi
  else
    fail "$description" "$output"
  fi
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    fail "required command is unavailable: $command_name" ""
  fi
}

require_tracked_file() {
  local path="$1"

  if ! git ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
    fail "required source is not tracked: $path" ""
  elif [ ! -f "$path" ]; then
    fail "required tracked source is missing from the worktree: $path" ""
  else
    ok "required tracked source exists: $path"
  fi
}

require_command git
require_command ruby
require_command plutil
require_command python3

required_sources=(
  "DesignReferences/MORI_DESIGN_SPEC.md"
  "DesignReferences/mori-approved-reference.jpeg"
  "DesignReferences/mori-today-view-reference.jpg"
  "DesignReferences/mori-screen-flow-reference.jpg"
  "project.yml"
  "Mori.xcodeproj/project.pbxproj"
  "Shared/MoriGeneratedArt.swift"
  "Shared/MoriGeneratedArt.xcassets/Contents.json"
  "Localization/en.lproj/Localizable.strings"
  "Localization/zh-Hans.lproj/Localizable.strings"
  "Localization/zh-Hant.lproj/Localizable.strings"
  "www/package.json"
  "scripts/sync_web_bitmap_assets.sh"
  "scripts/generate_botanical_watercolor_assets.py"
)

for path in "${required_sources[@]}"; do
  require_tracked_file "$path"
done

run_check \
  "approved design specification names the tracked visual references and Life Grid" \
  ruby <<'RUBY'
spec_path = "DesignReferences/MORI_DESIGN_SPEC.md"
spec = File.read(spec_path, encoding: "UTF-8")
required = [
  "DesignReferences/mori-approved-reference.jpeg",
  "DesignReferences/mori-today-view-reference.jpg",
  "DesignReferences/mori-screen-flow-reference.jpg",
  "Life Grid",
  "Illustration belongs to the composition",
  "Do not put every section in an identical white rounded card."
]
missing = required.reject { |phrase| spec.include?(phrase) }
abort "#{spec_path} is missing: #{missing.join(", ")}" unless missing.empty?
puts "Life Grid and reference-led screen/hero illustration remain approved UI vocabulary."
RUBY

run_check \
  "tracked localization string tables are parseable" \
  ruby <<'RUBY'
tracked = IO.popen(["git", "ls-files", "-z", "--", "*.strings"], &:read).split("\0")
abort "No tracked .strings files found." if tracked.empty?

problems = []
tracked.sort.each do |path|
  unless File.file?(path)
    problems << "#{path}: tracked file is missing"
    next
  end

  output = IO.popen(["plutil", "-lint", path], err: [:child, :out], &:read)
  problems << output.strip unless $?.success?
end

abort problems.join("\n") unless problems.empty?
puts "#{tracked.length} tracked .strings files parsed."
RUBY

run_check \
  "tracked localization XLIFF exports are parseable XML" \
  ruby <<'RUBY'
require "rexml/document"

tracked = IO.popen(["git", "ls-files", "-z", "--", "*.xliff"], &:read).split("\0")
problems = []
tracked.sort.each do |path|
  unless File.file?(path)
    problems << "#{path}: tracked file is missing"
    next
  end

  begin
    REXML::Document.new(File.read(path, encoding: "UTF-8"))
  rescue StandardError => error
    problems << "#{path}: #{error.message}"
  end
end

abort problems.join("\n") unless problems.empty?
puts "#{tracked.length} tracked .xliff files parsed."
RUBY

run_check \
  "XcodeGen target source wiring resolves and shared sources reach every native target" \
  ruby <<'RUBY'
require "yaml"

project = YAML.safe_load_file("project.yml", aliases: true)
targets = project.fetch("targets")
required_shared_targets = %w[
  Mori
  MoriScreenTimeMonitor
  MoriShieldConfiguration
  MoriShieldAction
  MoriWidgets
  MoriWatch
  MoriWatchWidgets
]

problems = []
required_shared_targets.each do |target_name|
  target = targets[target_name]
  if target.nil?
    problems << "project.yml: missing target #{target_name}"
    next
  end

  source_entries = Array(target["sources"])
  source_paths = source_entries.map { |entry| entry.is_a?(Hash) ? entry["path"] : entry.to_s }
  problems << "project.yml: #{target_name} must include Shared" unless source_paths.include?("Shared")

  source_paths.compact.each do |source_path|
    problems << "project.yml: #{target_name} source does not exist: #{source_path}" unless File.exist?(source_path)
  end
end

abort problems.join("\n") unless problems.empty?
puts "#{required_shared_targets.length} native target source graphs inspected."
RUBY

run_check \
  "generated art enum cases resolve to tracked asset catalogs" \
  ruby <<'RUBY'
source_path = "Shared/MoriGeneratedArt.swift"
source = File.read(source_path, encoding: "UTF-8")
asset_names = source.scan(/case\s+\w+\s*=\s*"([^"]+)"/).flatten.uniq.sort
problems = []

asset_names.each do |asset_name|
  contents = File.join("Shared", "MoriGeneratedArt.xcassets", "#{asset_name}.imageset", "Contents.json")
  unless File.file?(contents)
    problems << "#{source_path}: #{asset_name.inspect} has no imageset"
    next
  end
  unless system("git", "ls-files", "--error-unmatch", "--", contents, out: File::NULL, err: File::NULL)
    problems << "#{contents}: asset catalog is not tracked"
  end
end

abort problems.join("\n") unless problems.empty?
puts "#{asset_names.length} generated art cases resolve to tracked imagesets."
RUBY

run_check \
  "tracked app-icon catalog entries resolve to tracked files" \
  ruby <<'RUBY'
require "json"

catalogs = %w[
  AppIcon.appiconset/Contents.json
  DesignSystem/MoriBackgrounds.xcassets/AppIcon.appiconset/Contents.json
  WatchApp/MoriWatchAssets.xcassets/AppIcon.appiconset/Contents.json
]
problems = []

catalogs.each do |contents_path|
  unless File.file?(contents_path)
    problems << "#{contents_path}: missing"
    next
  end

  body = JSON.parse(File.read(contents_path, encoding: "UTF-8"))
  filenames = Array(body["images"]).filter_map { |image| image["filename"] }.uniq
  filenames.each do |filename|
    image_path = File.join(File.dirname(contents_path), filename)
    problems << "#{contents_path}: missing #{filename}" unless File.file?(image_path)
    unless system("git", "ls-files", "--error-unmatch", "--", image_path, out: File::NULL, err: File::NULL)
      problems << "#{image_path}: app-icon image is not tracked"
    end
  end
end

abort problems.join("\n") unless problems.empty?
puts "#{catalogs.length} app-icon catalogs inspected."
RUBY

run_check \
  "product cards do not use logo, app-icon, wordmark, or brand-mark art as wallpaper" \
  ruby <<'RUBY'
active_roots = %w[
  App/
  DesignSystem/
  Features/
  ScreenTimeMonitor/
  Shared/
  ShieldAction/
  ShieldConfiguration/
  WatchApp/
  WatchWidgets/
  Widgets/
  www/src/
]
extensions = %w[.swift .ts .tsx .js .jsx .css .scss]
paths = IO.popen(["git", "ls-files", "-z"], &:read).split("\0").select do |path|
  active_roots.any? { |root| path.start_with?(root) } &&
    extensions.include?(File.extname(path)) &&
    File.file?(path)
end

brand = /(?:app[_-]?icon|appicon|mori[_-]?logo|wordmark|brand[_-]?mark|paper[_-]?linework|mori-paper-linework)/i
surface = /(?:card|panel|tile|surface|wallpaper|texture|background|backdrop|watermark)/i
patterns = [
  /#{surface.source}[^\n]{0,240}#{brand.source}/i,
  /#{brand.source}[^\n]{0,240}#{surface.source}/i,
  /background(?:-image)?\s*:[^;{}]{0,320}url\([^)]*#{brand.source}/i
]

violations = []
paths.sort.each do |path|
  source = File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
  patterns.each do |pattern|
    source.to_enum(:scan, pattern).each do
      match = Regexp.last_match
      line_number = source.byteslice(0, match.begin(0)).to_s.count("\n") + 1
      snippet = match[0].gsub(/\s+/, " ").strip
      violations << "#{path}:#{line_number}: #{snippet[0, 300]}"
    end
  end
end

abort violations.uniq.join("\n") unless violations.empty?
puts "Standard platform SF Symbols, Life Grid copy, and reference-led botanical screen/hero art are allowed."
puts "Only repeated brand identity used as card/surface texture is rejected."
RUBY

run_check \
  "web bitmap mirrors match tracked native generated art" \
  bash scripts/sync_web_bitmap_assets.sh --check

run_check \
  "generated botanical watercolor assets match their deterministic recipe" \
  python3 scripts/generate_botanical_watercolor_assets.py --check

run_check \
  "source-level native and web contrast tokens meet the project thresholds" \
  bash scripts/check_color_contrast_tokens.sh

if [ "$failures" -ne 0 ]; then
  printf '\nDesign direction source gate failed with %d issue(s).\n' "$failures"
  exit 1
fi

printf '\nDesign direction source gate passed.\n'
