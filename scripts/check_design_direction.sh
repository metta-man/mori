#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

failures=0

run_no_match_check() {
  local description="$1"
  shift

  local output
  local status
  if output=$("$@" 2>&1); then
    printf '\n::error::%s\n' "$description"
    printf '%s\n' "$output"
    failures=$((failures + 1))
    return 0
  else
    status=$?
  fi

  if [ "$status" -eq 1 ]; then
    printf 'OK: %s\n' "$description"
    return 0
  fi

  printf '\n::error::%s check failed to run\n' "$description"
  printf '%s\n' "$output"
  exit "$status"
}

run_required_file_check() {
  local path="$1"

  if [ -f "$path" ]; then
    printf 'OK: required asset exists: %s\n' "$path"
  else
    printf '\n::error::Missing required asset: %s\n' "$path"
    failures=$((failures + 1))
  fi
}

run_no_file_name_match_check() {
  local description="$1"
  local pattern="$2"
  shift 2

  local output
  output=$(find "$@" -type f | LC_ALL=C rg -n --color never "$pattern" || true)

  if [ -n "$output" ]; then
    printf '\n::error::%s\n' "$description"
    printf '%s\n' "$output"
    failures=$((failures + 1))
  else
    printf 'OK: %s\n' "$description"
  fi
}

run_command_check() {
  local description="$1"
  shift

  local output
  if output=$("$@" 2>&1); then
    printf 'OK: %s\n' "$description"
    printf '%s\n' "$output"
  else
    printf '\n::error::%s\n' "$description"
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_no_direct_sf_symbol_check() {
  local description="$1"
  shift

  local output
  if output=$(ruby - "$@" 2>&1 <<'RUBY'
paths = ARGV.flat_map do |arg|
  if File.directory?(arg)
    Dir.glob(File.join(arg, "**/*.swift"))
  elsif File.file?(arg)
    [arg]
  else
    []
  end
end.uniq.sort

violations = []
paths.each do |path|
  source = File.read(path)

  source.each_line.with_index(1) do |line, line_number|
    if line.match?(/(?:\bImage|\bUIImage)\s*\(\s*systemName\s*:/)
      violations << "#{path}:#{line_number}: #{line.strip}"
    end
  end

  source.to_enum(:scan, /(?<!\.)\bLabel\s*\([\s\S]*?systemImage\s*:/).each do
    match = Regexp.last_match
    line_number = source[0...match.begin(0)].count("\n") + 1
    snippet = source.lines[line_number - 1]&.strip || "Label(... systemImage:)"
    violations << "#{path}:#{line_number}: #{snippet}"
  end
end

if violations.empty?
  puts "No direct SF Symbol rendering found."
else
  abort violations.join("\n")
end
RUBY
  ); then
    printf 'OK: %s\n' "$description"
    printf '%s\n' "$output"
  else
    printf '\n::error::%s\n' "$description"
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_archive_start_legacy_key_boundary_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
paths = %w[
  App
  DesignSystem
  Features
  Models
  Services
  Shared
  Widgets
  WatchApp
  WatchWidgets
  ScreenTimeMonitor
  ShieldAction
  ShieldConfiguration
  Localization
].flat_map do |root|
  next [] unless File.exist?(root)
  if File.directory?(root)
    Dir.glob(File.join(root, "**/*.{swift,strings}"))
  else
    [root]
  end
end

paths += Dir.glob("Mori/en.xcloc/**/*.{strings,xliff}")
paths += %w[project.yml Mori.xcodeproj/project.pbxproj].select { |path| File.file?(path) }
paths = paths.flatten.uniq.sort

blocked = /
  \bbirthDate\b|
  Birth\ Date|
  birth_date|
  birth\ date|
  trackBirthDate|
  birthDateSet|
  AnalyticsProperties\.birthDate|
  settings\.birthDate|
  generateWeeks\(birthDate|
  MoriWidgetSnapshot\(\s*birthDate|
  "birthDate"
/x

allowed = {
  "Models/UserSettingsStore.swift" => [
    /static let archiveStartDateLegacyKey = "birthDate"/,
    /defaults\.object\(forKey: Key\.archiveStartDateLegacyKey\) as\? Date/
  ],
  "Shared/MoriWidgetSnapshot.swift" => [
    /let savedLegacyArchiveStartDate = defaults\.object\(forKey: "birthDate"\) as\? Date/
  ],
  "WatchApp/MoriWatchSettingsReceiver.swift" => [
    /else if let legacyArchiveStartDate = context\["birthDate"\] as\? Date/
  ],
  "Services/AnalyticsStateStore.swift" => [
    /static let archiveStartDateLegacyKey = "birthDate"/,
    /defaults\.object\(forKey: Key\.archiveStartDateLegacyKey\) as\? Date/
  ]
}

violations = []
paths.each do |path|
  next unless File.file?(path)
  lines = File.readlines(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
  lines.each_with_index do |line, index|
    next unless line.match?(blocked)
    next if allowed.fetch(path, []).any? { |pattern| line.match?(pattern) }
    violations << "#{path}:#{index + 1}: #{line.strip}"
  end
end

if violations.empty?
  puts "Only explicit archive-start migration reads use the old birthDate defaults key."
else
  abort violations.join("\n")
end
RUBY
  ); then
    printf 'OK: active code uses archive-start naming, with legacy birthDate only at migration boundaries\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::active code must not use birthDate naming outside migration fallbacks\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_legacy_archive_readme_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
legacy_dirs = %w[
  design
  docs
  mockups
  q2-prep
  research
  icon-concepts
]

required_phrases = [
  "Historical Archive Only",
  "not source of truth",
  "DesignSystem/MoriDesignSystemDocumentation.md",
  "brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md",
  "scripts/check_design_direction.sh"
]

missing = []
root_readme = "README.md"
if File.file?(root_readme)
  root_body = File.read(root_readme)
  [
    "Active Source Of Truth",
    "Historical Archives",
    "DesignSystem/MoriDesignSystemDocumentation.md",
    "brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md",
    "q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md",
    "scripts/check_design_direction.sh",
    "not the current implementation source of truth"
  ].each do |phrase|
    missing << "#{root_readme}: missing phrase #{phrase.inspect}" unless root_body.include?(phrase)
  end
else
  missing << "#{root_readme}: missing"
end

legacy_dirs.each do |dir|
  readme = File.join(dir, "README.md")
  unless File.file?(readme)
    missing << "#{readme}: missing"
    next
  end

  body = File.read(readme)
  required_phrases.each do |phrase|
    missing << "#{readme}: missing phrase #{phrase.inspect}" unless body.include?(phrase)
  end

  if dir == "q2-prep"
    [
      "except for `q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md`",
      "active onboarding source of truth"
    ].each do |phrase|
      missing << "#{readme}: missing phrase #{phrase.inspect}" unless body.include?(phrase)
    end
  end
end

if missing.empty?
  puts "Legacy design/research folders are marked as non-authoritative archives."
else
  abort missing.join("\n")
end
RUBY
  ); then
    printf 'OK: legacy archive README notices are present\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::legacy design/research folders must be marked as non-authoritative archives\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_project_shared_source_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
require "yaml"

project = YAML.load_file("project.yml")
targets = project.fetch("targets")
required_targets = %w[
  Mori
  MoriScreenTimeMonitor
  MoriShieldConfiguration
  MoriShieldAction
  MoriWidgets
  MoriWatch
  MoriWatchWidgets
]

missing = required_targets.reject do |target_name|
  sources = Array(targets.fetch(target_name).fetch("sources"))
  paths = sources.map { |entry| entry.is_a?(Hash) ? entry["path"] : entry.to_s }
  paths.include?("Shared")
end

if missing.empty?
  puts "All native targets include Shared generated art source."
else
  abort "Missing Shared source in native targets: #{missing.join(", ")}"
end
RUBY
  ); then
    printf 'OK: native targets include Shared generated art source\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::native targets must include Shared generated art source\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_generated_art_asset_catalog_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
source = File.read("Shared/MoriGeneratedArt.swift")
asset_names = source.scan(/case\s+\w+\s*=\s*"([^"]+)"/).flatten.uniq
missing = asset_names.reject do |asset_name|
  Dir.exist?(File.join("Shared", "MoriGeneratedArt.xcassets", "#{asset_name}.imageset"))
end

if missing.empty?
  puts "All generated art enum assets resolve."
else
  abort "Missing generated art asset catalogs: #{missing.join(", ")}"
end
RUBY
  ); then
    printf 'OK: generated art enum assets resolve\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::generated art enum assets must resolve to xcassets\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_card_paper_material_boundary_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
paths = %w[
  App
  DesignSystem
  Features
  Shared
  Widgets
  WatchApp
  WatchWidgets
].flat_map { |root| Dir.glob(File.join(root, "**/*.swift")) }.sort

allowed = {
  "Shared/MoriGeneratedArt.swift" => [
    /case cardPaperWash = "moriCardPaperWash"/,
    /var paperWash: MoriGeneratedArt = \.cardPaperWash/,
    /if paperWash == \.cardPaperWash/,
    /MoriGeneratedArtImage\(art:\s*\.cardPaperWash,\s*contentMode:\s*\.fill\)/
  ],
  "DesignSystem/MoriSanctuaryBoxBackground.swift" => [
    /return \.cardPaperWash/
  ]
}

violations = []
paths.each do |path|
  File.readlines(path).each_with_index do |line, index|
    if line.include?(".botanicalCardWash")
      violations << "#{path}:#{index + 1}: botanicalCardWash is retired; use MoriPlainWatercolorCardBackground for cards and botanicalScreenWash only at screen level"
    end

    next unless line.include?(".cardPaperWash")
    next if allowed.fetch(path, []).any? { |rule| line.match?(rule) }

    violations << "#{path}:#{index + 1}: #{line.strip}"
  end
end

required = {
  "Shared/MoriGeneratedArt.swift" => /struct MoriPlainWatercolorCardBackground[\s\S]*?fill\(Color\(red:\s*1\.0,[\s\S]*?MoriGeneratedArtImage\(art:\s*\.cardPaperWash/,
  "DesignSystem/MoriSanctuaryBoxBackground.swift" => /MoriPlainWatercolorCardBackground\(/,
  "DesignSystem/MoriSanctuarySurfaces.swift" => /MoriPlainWatercolorCardBackground\(/,
  "Widgets/MoriWidgetComponents.swift" => /private struct MoriWidgetCardWash[\s\S]*?MoriPlainWatercolorCardBackground\(/,
  "WatchApp/MoriWatchSupport.swift" => /struct MoriWatchCardBackground[\s\S]*?MoriPlainWatercolorCardBackground\(/
}

required.each do |path, pattern|
  source = File.read(path)
  violations << "#{path}: default card material must use MoriPlainWatercolorCardBackground" unless source.match?(pattern)
end

forbidden_card_botanical = {
  "DesignSystem/MoriSanctuaryBoxBackground.swift" => /\.botanicalCardWash/,
  "DesignSystem/MoriActionComponents.swift" => /\.botanicalCardWash/,
  "Features/ScreenTime/FirstAppLimitSetupView.swift" => /\.botanicalCardWash/
}

forbidden_card_botanical.each do |path, pattern|
  File.readlines(path).each_with_index do |line, index|
    violations << "#{path}:#{index + 1}: card material must not use botanicalCardWash" if line.match?(pattern)
  end
end

if violations.empty?
  puts "Card materials use plain no-logo watercolor paper; botanical bitmap wash is reserved for screen-level atmosphere."
else
  abort violations.join("\n")
end
RUBY
  ); then
    printf 'OK: card materials keep botanical accents out of default surfaces\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::card surfaces must use plain no-logo paper wash by default\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_legacy_symbol_mapper_boundary_check() {
  local output_file output
  output_file="$(mktemp)"
  if ruby >"$output_file" 2>&1 <<'RUBY'
paths = Dir.glob("{App,Features,Models,DesignSystem,Services,Shared,Widgets,WatchApp,WatchWidgets,ShieldAction,ShieldConfiguration,ScreenTimeMonitor}/**/*.swift").sort
pattern = /(?:from\(systemName:|fromLegacySymbolName\()/
allowed = {
  "Shared/MoriGeneratedArt.swift" => [
    /static func fromLegacySymbolName\(_ symbolName: String\)/
  ],
  "Shared/MoriWidgetSnapshot.swift" => [
    /MoriBitmapIcon\.fromLegacySymbolName\(cleaned\)/
  ],
  "Models/MoriPulseCardModels.swift" => [
    /symbolName\.map \{ MoriBitmapIcon\.fromLegacySymbolName\(\$0\) \}/
  ],
  "Services/MoriClarityStore.swift" => [
    /MoriBitmapIcon\.fromLegacySymbolName\(symbolName\(forCustomTopic: topic\)\)/
  ],
  "Features/Settle/MoriBreathingLibrary.swift" => [
    /\.fromLegacySymbolName\(iconName\)/
  ]
}

violations = []
paths.each do |path|
  File.readlines(path).each_with_index do |line, index|
    next unless line.match?(pattern)
    if line.include?("from(systemName:")
      violations << "#{path}:#{index + 1}: remove generic from(systemName:) mapper usage: #{line.strip}"
      next
    end
    next if allowed.fetch(path, []).any? { |rule| line.match?(rule) }

    violations << "#{path}:#{index + 1}: legacy symbol mapping is only allowed in migration/model compatibility seams: #{line.strip}"
  end
end

if violations.empty?
  puts "Legacy SF Symbol mapping is explicitly named and limited to compatibility seams."
else
  abort violations.join("\n")
end
RUBY
  then
    output="$(cat "$output_file")"
    rm -f "$output_file"
    printf 'OK: legacy SF Symbol mapping is isolated to compatibility seams\n'
    printf '%s\n' "$output"
  else
    output="$(cat "$output_file")"
    rm -f "$output_file"
    printf '\n::error::legacy SF Symbol mapping must not be a general app/UI API\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_quiet_card_default_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
source = File.read("DesignSystem/MoriSanctuarySurfaces.swift")

violations = []

{
  "moriSanctuaryCard" => /func\s+moriSanctuaryCard\(([\s\S]*?)\)\s*->\s*some\s+View/,
  "moriSanctuaryBox" => /func\s+moriSanctuaryBox\(([\s\S]*?)\)\s*->\s*some\s+View/
}.each do |name, pattern|
  match = source.match(pattern)
  if match.nil?
    violations << "#{name} signature missing"
    next
  end

  violations << "#{name} must not expose backdrop imagery" if match[1].include?("backdrop")
end

checks = {
  "moriSanctuaryCard must route through moriSanctuaryBox" => /func\s+moriSanctuaryCard\([\s\S]*?moriSanctuaryBox\(/,
  "BotanicalPanel must stay in the shared card stack" => /struct\s+BotanicalPanel/,
  "OrganicCard must stay in the shared card stack" => /struct\s+OrganicCard/
}

violations.concat(checks.reject { |_label, pattern| source.match?(pattern) }.keys)

surface_escape_hatches = source.scan(/showsWave|showsTexture|showsWaveBackground|backdrop:\s*MoriBotanicalScreenBackdrop\.Variant/)
unless surface_escape_hatches.empty?
  violations << "shared card surfaces must not expose card-level decorative backdrop API"
end

if violations.empty?
  puts "Generic card defaults stay quiet paper; card-level decorative backdrop APIs are removed."
else
  abort violations.join("\n")
end
RUBY
  ); then
    printf 'OK: generic card defaults avoid repeated botanical/logo marks\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::generic cards must default to quiet watercolor paper, not repeated logo or botanical marks\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_no_card_decoration_escape_hatch_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
violations = []

docs_path = "DesignSystem/MoriDesignSystemDocumentation.md"
if File.file?(docs_path)
  docs = File.read(docs_path)
  docs.each_line.with_index(1) do |line, line_number|
    if line.match?(/shows(?:Texture|Wave):\s*true/)
      violations << "#{docs_path}:#{line_number}: docs must not teach card texture/wave opt-ins"
    end
  end
else
  violations << "#{docs_path}: missing"
end

product_paths = %w[
  App
  Features
  Widgets
  WatchApp
  WatchWidgets
  ShieldAction
  ShieldConfiguration
  ScreenTimeMonitor
].flat_map { |dir| Dir.glob(File.join(dir, "**/*.swift")) }.sort

product_paths.each do |path|
  File.read(path).each_line.with_index(1) do |line, line_number|
    if line.match?(/showsTexture:\s*true/)
      violations << "#{path}:#{line_number}: product cards must not force repeated texture accents"
    end

    if line.match?(/showsWave:\s*true/)
      violations << "#{path}:#{line_number}: product cards must not force repeated wave accents"
    end
  end
end

  component_path = "DesignSystem/MoriSanctuaryComponents.swift"
  if File.file?(component_path)
    component_source = File.read(component_path)
  if component_source.match?(/\bbackdrop:\s*MoriBotanicalScreenBackdrop\.Variant\?/)
    violations << "#{component_path}: product card components must not expose backdrop imagery"
  end

  if component_source.match?(/shows(?:Texture|Wave):\s*backdrop\s*!=\s*nil/)
    violations << "#{component_path}: MoriFeatureBox must not auto-add card decoration from backdrop"
  end

  if component_source.match?(/shows(?:Texture|Wave):\s*backdrop\s*!=\s*nil\s*\|\|\s*!isCompact/)
    violations << "#{component_path}: MoriFeatureBox must not auto-add card decoration from size alone"
  end
else
  violations << "#{component_path}: missing"
end

%w[
  DesignSystem/MoriSanctuarySurfaces.swift
  DesignSystem/MoriSanctuaryBoxBackground.swift
].each do |surface_path|
  if File.file?(surface_path)
    File.read(surface_path).each_line.with_index(1) do |line, line_number|
      if line.match?(/showsWave|showsTexture|MoriWatercolorHeroWash|MoriBotanicalScreenBackdrop/)
        violations << "#{surface_path}:#{line_number}: card surfaces must not expose screen or hero decorative wash hooks"
      end
    end
  else
    violations << "#{surface_path}: missing"
  end
end

if violations.empty?
  puts "Card decoration opt-ins are explicit, quiet by default, and not taught in docs."
else
  abort violations.join("\n")
end
RUBY
  ); then
    printf 'OK: card decoration escape hatches stay closed\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::card decoration escape hatches must stay closed\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_shield_icon_asset_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
source = File.read("ShieldConfiguration/MoriShieldConfigurationExtension.swift")
asset_names = source.scan(/iconAssetName:\s*"([^"]+)"/).flatten.uniq
expected_asset_names = %w[moriIconBreathe moriIconLeaf moriIconLockShield]
missing = asset_names.reject do |asset_name|
  Dir.exist?(File.join("Shared", "MoriGeneratedArt.xcassets", "#{asset_name}.imageset"))
end
unexpected = asset_names - expected_asset_names
missing_expected = expected_asset_names - asset_names
contract_checks = {
  "paper background color" => "backgroundColor: MoriShieldPalette.paper",
  "light paper blur" => "backgroundBlurStyle: .systemUltraThinMaterialLight",
  "bitmap icon loading" => "icon: UIImage(named: copy.iconAssetName)",
  "canopy title color" => "color: MoriShieldPalette.canopy",
  "muted subtitle color" => "color: MoriShieldPalette.muted",
  "canopy primary button" => "primaryButtonBackgroundColor: MoriShieldPalette.canopy"
}
missing_contract = contract_checks.reject { |_label, needle| source.include?(needle) }.keys
legacy_terms = source.scan(/logo|wordmark|hourglass|funnel|time[_-]?seed|forest_rings/i).uniq

if missing.empty? && unexpected.empty? && missing_expected.empty? && missing_contract.empty? && legacy_terms.empty?
  puts "Shield configuration uses only botanical bitmap icons and the paper/canopy contract."
else
  problems = []
  problems << "Missing shield icon asset catalogs: #{missing.join(", ")}" unless missing.empty?
  problems << "Unexpected shield icon assets: #{unexpected.join(", ")}" unless unexpected.empty?
  problems << "Missing expected shield icon assets: #{missing_expected.join(", ")}" unless missing_expected.empty?
  problems << "Missing shield contract checks: #{missing_contract.join(", ")}" unless missing_contract.empty?
  problems << "Legacy shield visual terms present: #{legacy_terms.join(", ")}" unless legacy_terms.empty?
  abort problems.join("\n")
end
RUBY
  ); then
    printf 'OK: shield visual contract uses botanical bitmap icons\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::shield visual contract must use botanical bitmap icons and paper/canopy colors\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_app_icon_bitmap_mirror_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
root = "AppIcon.appiconset"
mirror = "DesignSystem/MoriBackgrounds.xcassets/AppIcon.appiconset"
pattern = "*_paper_linework.png"

root_files = Dir.glob(File.join(root, pattern)).map { |path| File.basename(path) }.sort
mirror_files = Dir.glob(File.join(mirror, pattern)).map { |path| File.basename(path) }.sort
missing_from_mirror = root_files - mirror_files
missing_from_root = mirror_files - root_files

mismatched = (root_files & mirror_files).reject do |filename|
  File.binread(File.join(root, filename)) == File.binread(File.join(mirror, filename))
end

problems = []
problems << "Missing from design-system app icon catalog: #{missing_from_mirror.join(", ")}" unless missing_from_mirror.empty?
problems << "Missing from root app icon catalog: #{missing_from_root.join(", ")}" unless missing_from_root.empty?
problems << "Bitmap differs between app icon catalogs: #{mismatched.join(", ")}" unless mismatched.empty?

if problems.empty?
  puts "All paper-linework app icon PNGs mirror across active catalogs."
else
  abort problems.join("\n")
end
RUBY
  ); then
    printf 'OK: active app icon PNG catalogs mirror\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::active app icon PNG catalogs must mirror\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_direct_botanical_backdrop_usage_check() {
  local output
  local unexpected

  output=$(rg -n --color never --glob '*.swift' 'MoriBotanicalScreenBackdrop\(variant:' \
    App Features DesignSystem Widgets WatchApp WatchWidgets ShieldAction ShieldConfiguration ScreenTimeMonitor || true)
  unexpected=$(printf '%s\n' "$output" | rg -v '^(DesignSystem/MoriPaperBackground\.swift|DesignSystem/MoriViewModifiers\.swift):' || true)

  if [ -z "$unexpected" ]; then
    printf 'OK: direct botanical backdrops are limited to root paper surfaces\n'
  else
    printf '\n::error::card and hero surfaces must use no-logo watercolor accents, not direct botanical backdrops\n'
    printf '%s\n' "$unexpected"
    failures=$((failures + 1))
  fi
}

run_settle_typed_icon_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
paths = Dir.glob("Features/Settle/**/*.swift").sort
pattern = /(\.from\(systemName:|\.fromLegacySymbolName\(|\bsymbolName\b|\biconName\b|\bonSymbol\b|\boffSymbol\b)/
allowed = {
  "Features/Settle/MoriBreathingLibrary.swift" => [
    /let iconName: String/,
    /\.fromLegacySymbolName\(iconName\)/,
    /iconName:/,
    /var iconName: String/
  ],
  "Features/Settle/SettlePracticeShared.swift" => [
    /var symbolName: String \{ icon\.legacySystemName \}/
  ],
  "Features/Settle/PomodoroPracticeModels.swift" => [
    /var symbolName: String \{ icon\.legacySystemName \}/
  ]
}

violations = []
paths.each do |path|
  File.readlines(path).each_with_index do |line, index|
    next unless line.match?(pattern)
    next if allowed.fetch(path, []).any? { |rule| line.match?(rule) }

    violations << "#{path}:#{index + 1}: #{line.strip}"
  end
end

if violations.empty?
  puts "Settle UI surfaces use typed bitmap icons; model compatibility is isolated."
else
  abort violations.join("\n")
end
RUBY
  ); then
    printf 'OK: Settle UI surfaces use typed MoriBitmapIcon values\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::Settle UI surfaces must use typed MoriBitmapIcon values\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_pulse_typed_icon_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
ui_paths = Dir.glob("Features/Pulse/**/*.swift").sort
ui_pattern = /(\.from\(systemName:|\.fromLegacySymbolName\(|\bsymbolName\b|\bkind\.symbolName\b|\btopic\.symbolName\b|\bselectedCustomTopicIcon\.rawValue\b)/

compatibility_paths = [
  "Models/MoriClarityModels.swift",
  "Models/MoriPulseCardModels.swift",
  "Services/MoriClarityStore.swift"
]
compatibility_pattern = /(\.from\(systemName:|\.fromLegacySymbolName\(|\bsymbolName\b|symbolName:)/
allowed = {
  "Models/MoriClarityModels.swift" => [
    /var symbolName: String \{ icon\.legacySystemName \}/
  ],
  "Models/MoriPulseCardModels.swift" => [
    /var symbolName: String \{ icon\.legacySystemName \}/,
    /var symbolName: String\?/,
    /symbolName\.map \{ MoriBitmapIcon\.fromLegacySymbolName\(\$0\) \}/,
    /symbolName: String\? = nil/,
    /self\.symbolName = symbolName/
  ],
  "Services/MoriClarityStore.swift" => [
    /func addCustomTopic\(_ topic: String, symbolName: String = MoriCustomPulseTopicIcon\.leaf\.rawValue\)/,
    /customTopicSymbols\[trimmed\] = symbolName/,
    /addCustomTopic\(topic, symbolName: icon\.rawValue\)/,
    /func symbolName\(forCustomTopic topic: String\) -> String/,
    /MoriBitmapIcon\.fromLegacySymbolName\(symbolName\(forCustomTopic: topic\)\)/,
    /func symbolName\(forTopicLabel topic: String\) -> String/,
    /return defaultTopic\.symbolName/,
    /return symbolName\(forCustomTopic: topic\)/
  ]
}

violations = []
ui_paths.each do |path|
  File.readlines(path).each_with_index do |line, index|
    next unless line.match?(ui_pattern)
    violations << "#{path}:#{index + 1}: #{line.strip}"
  end
end

compatibility_paths.each do |path|
  File.readlines(path).each_with_index do |line, index|
    next unless line.match?(compatibility_pattern)
    next if allowed.fetch(path, []).any? { |rule| line.match?(rule) }

    violations << "#{path}:#{index + 1}: #{line.strip}"
  end
end

if violations.empty?
  puts "Pulse UI surfaces use typed bitmap icons; symbolName compatibility is isolated to models/store persistence."
else
  abort violations.join("\n")
end
RUBY
  ); then
    printf 'OK: Pulse UI surfaces use typed MoriBitmapIcon values\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::Pulse UI surfaces must use typed MoriBitmapIcon values\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_week_archive_typed_icon_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
paths = Dir.glob("Features/WeekArchive/**/*.swift").sort
pattern = /(\.from\(systemName:|\bsymbolName\b|symbolName:|\barchiveSymbolName\b)/

violations = []
paths.each do |path|
  File.readlines(path).each_with_index do |line, index|
    next unless line.match?(pattern)
    violations << "#{path}:#{index + 1}: #{line.strip}"
  end
end

if violations.empty?
  puts "WeekArchive UI surfaces use typed bitmap icons."
else
  abort violations.join("\n")
end
RUBY
  ); then
    printf 'OK: WeekArchive UI surfaces use typed MoriBitmapIcon values\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::WeekArchive UI surfaces must use typed MoriBitmapIcon values\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_quiet_typed_icon_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
paths = Dir.glob("Features/Quiet/**/*.swift").sort
paths += ["Services/QuietTimerCoordinator.swift"].select { |path| File.file?(path) }
pattern = /(\.from\(systemName:|\bsymbolName\b|symbolName:)/

violations = []
paths.each do |path|
  File.readlines(path).each_with_index do |line, index|
    next unless line.match?(pattern)
    violations << "#{path}:#{index + 1}: #{line.strip}"
  end
end

if violations.empty?
  puts "Quiet UI surfaces use typed bitmap icons."
else
  abort violations.join("\n")
end
RUBY
  ); then
    printf 'OK: Quiet UI surfaces use typed MoriBitmapIcon values\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::Quiet UI surfaces must use typed MoriBitmapIcon values\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_gratitude_typed_icon_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
paths = Dir.glob("Features/GratitudeJournal/**/*.swift").sort
pattern = /(\.from\(systemName:|\bsymbolName\b|symbolName:|\bsourceSymbolName\b)/

violations = []
paths.each do |path|
  File.readlines(path).each_with_index do |line, index|
    next unless line.match?(pattern)
    violations << "#{path}:#{index + 1}: #{line.strip}"
  end
end

if violations.empty?
  puts "GratitudeJournal UI surfaces use typed bitmap icons."
else
  abort violations.join("\n")
end
RUBY
  ); then
    printf 'OK: GratitudeJournal UI surfaces use typed MoriBitmapIcon values\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::GratitudeJournal UI surfaces must use typed MoriBitmapIcon values\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_widget_snapshot_typed_icon_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
violations = []

publisher_paths = [
  "Services/MoriWatchSettingsSync.swift",
  "Services/MoriRecoverySnapshotPublisher.swift"
]
publisher_pattern = /(suggestedPracticeSymbol|recoverySuggestedPracticeSymbol|\.symbolName)/
publisher_paths.each do |path|
  File.readlines(path).each_with_index do |line, index|
    next unless line.match?(publisher_pattern)
    violations << "#{path}:#{index + 1}: #{line.strip}"
  end
end

snapshot_path = "Shared/MoriWidgetSnapshot.swift"
snapshot_pattern = /(\blet suggestedPracticeSymbol\b|\blet recoverySuggestedPracticeSymbol\b|displayRecoveryPracticeSymbol|suggestedPracticeSymbol:|recoverySuggestedPracticeSymbol:)/
File.readlines(snapshot_path).each_with_index do |line, index|
  next unless line.match?(snapshot_pattern)
  violations << "#{snapshot_path}:#{index + 1}: #{line.strip}"
end

required_usages = {
  "Widgets/MoriPulseWidgetViews.swift" => "displayRecoveryPracticeIcon",
  "WatchApp/MoriWatchPracticeViews.swift" => "displayRecoveryPracticeIcon"
}
required_usages.each do |path, token|
  next if File.read(path).include?(token)
  violations << "#{path}: missing #{token}"
end

if violations.empty?
  puts "Widget and Watch context snapshots publish typed bitmap icons."
else
  abort violations.join("\n")
end
RUBY
  ); then
    printf 'OK: Widget and Watch context snapshots use typed MoriBitmapIcon values\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::Widget and Watch context snapshots must use typed MoriBitmapIcon values\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_widget_surface_shell_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
components = File.read("Widgets/MoriWidgetComponents.swift")
widgets = File.read("Widgets/MoriWidgets.swift")
watch_widgets = File.read("WatchWidgets/MoriWatchWidgets.swift")
widget_sources = Dir.glob("Widgets/*.swift").sort.map { |path| [path, File.read(path)] }

problems = []
[
  "struct MoriWidgetShell",
  "MoriGeneratedArtImage(art: .widgetPaperWash",
  "MoriGeneratedArtImage(art: .widgetBotanicalWash",
  "moriWidgetContainerBackground",
  "let icon: MoriBitmapIcon"
].each do |needle|
  problems << "Widgets/MoriWidgetComponents.swift missing #{needle.inspect}" unless components.include?(needle)
end

widget_sources.each do |path, source|
  problems << "#{path} still routes widget icons through SF Symbol names" if source.match?(/\.from\(systemName:|\bsymbol\s*:/)
end

static_configs = widgets.scan(/StaticConfiguration\(/).length
container_backgrounds = widgets.scan(/\.moriWidgetContainerBackground\(\)/).length
if static_configs != container_backgrounds
  problems << "Every iOS widget StaticConfiguration must use .moriWidgetContainerBackground() (#{container_backgrounds}/#{static_configs})"
end

watch_configs = watch_widgets.scan(/StaticConfiguration\(/).length
watch_clear_backgrounds = watch_widgets.scan(/\.containerBackground\(\.clear,\s*for:\s*\.widget\)/).length
if watch_configs != watch_clear_backgrounds
  problems << "Watch complications should keep transparent watch-face backgrounds (#{watch_clear_backgrounds}/#{watch_configs})"
end

if problems.empty?
  puts "Widget shells use dedicated widget-sized bitmap paper wash and explicit widget backgrounds."
else
  abort problems.join("\n")
end
RUBY
  ); then
    printf 'OK: widget surfaces use paper-watercolor shell infrastructure\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::widget surfaces must use the paper-watercolor shell infrastructure\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

run_watch_surface_shell_check() {
  local output
  if output=$(ruby <<'RUBY' 2>&1
support = File.read("WatchApp/MoriWatchSupport.swift")
practice = File.read("WatchApp/MoriWatchPracticeViews.swift")
bell = File.read("WatchApp/MoriWatchBellSettingsView.swift")

problems = []
[
  "struct MoriWatchPaperBackground",
  "MoriGeneratedArtImage(art: .paperWash",
  "MoriGeneratedArtImage(art: .botanicalScreenWash",
  "struct MoriWatchCardBackground",
  "func moriWatchPaperBackground()",
  "func moriWatchCard"
].each do |needle|
  problems << "WatchApp/MoriWatchSupport.swift missing #{needle.inspect}" unless support.include?(needle)
end

practice_backgrounds = practice.scan(/\.moriWatchPaperBackground\(\)/).length
problems << "Watch reset hub/timer must use .moriWatchPaperBackground() in both root flows" if practice_backgrounds < 2

problems << "Watch bell settings must use .moriWatchPaperBackground()" unless bell.include?(".moriWatchPaperBackground()")
problems << "Watch bell settings must use .moriWatchCard" unless bell.include?(".moriWatchCard")
problems << "Watch bell settings must use MoriWatchCardBackground for nested options" unless bell.include?("MoriWatchCardBackground")

if problems.empty?
  puts "Watch app roots and cards use bitmap paper wash infrastructure."
else
  abort problems.join("\n")
end
RUBY
  ); then
    printf 'OK: Watch app surfaces use paper-watercolor shell infrastructure\n'
    printf '%s\n' "$output"
  else
    printf '\n::error::Watch app surfaces must use paper-watercolor shell infrastructure\n'
    printf '%s\n' "$output"
    failures=$((failures + 1))
  fi
}

source_paths=(
  App
  Features
  Services
  Shared
  Widgets
  WatchApp
  WatchWidgets
  ShieldAction
  ShieldConfiguration
  ScreenTimeMonitor
  www/src
)

localization_paths=(
  Localization/en.lproj/Localizable.strings
  Localization/zh-Hans.lproj/Localizable.strings
  Localization/zh-Hant.lproj/Localizable.strings
)

xcloc_string_paths=(
  "Mori/en.xcloc/Source Contents/en.lproj/Localizable.strings"
)

xcloc_xml_paths=(
  "Mori/en.xcloc/Localized Contents/en.xliff"
)

icon_paths=(
  AppIcon.appiconset
  DesignSystem/MoriBackgrounds.xcassets/AppIcon.appiconset
)

asset_file_name_paths=(
  AppIcon.appiconset
  DesignSystem/MoriBackgrounds.xcassets
  Shared/MoriGeneratedArt.xcassets
  www/src/assets
)

brand_asset_paths=(
  brand-assets
  outputs/logos
)

run_legacy_archive_readme_check

run_command_check \
  "active localization strings are parseable" \
  plutil -lint \
  "${localization_paths[@]}"

run_command_check \
  "localization export strings are parseable" \
  plutil -lint \
  "${xcloc_string_paths[@]}"

run_command_check \
  "localization XLIFF exports are parseable XML" \
  xmllint --noout \
  "${xcloc_xml_paths[@]}"

run_no_match_check \
  "legacy visual motifs must not appear in active source" \
  rg -n --color never \
  --glob '*.swift' --glob '*.tsx' --glob '*.ts' --glob '*.css' \
  '(hourglass|funnel|Memento mori|time_seed|forest_rings|Time Seed)' \
  "${source_paths[@]}"

run_no_match_check \
  "active app source must not describe current UI/data paths as legacy" \
  rg -n --color never \
  --glob '*.swift' --glob '*.tsx' --glob '*.ts' --glob '*.css' \
  '\blegacy\b' \
  "${source_paths[@]}"

run_no_match_check \
  "legacy visual motifs must not appear in localization values" \
  rg -n --color never \
  '= "[^"]*(hourglass|funnel|Memento mori|Time Seed|time seed|forest_rings)' \
  "${localization_paths[@]}"

run_no_match_check \
  "active localization keys and exports must not keep old death-framed tagline" \
  rg -n --color never \
  'Memento mori — remember that you will die|remember that you will die' \
  "${localization_paths[@]}" \
  "Mori/en.xcloc/Source Contents/en.lproj/Localizable.strings" \
  "Mori/en.xcloc/Localized Contents/en.xliff"

run_no_match_check \
  "active localization and exports must not keep old onboarding countdown setup copy" \
  rg -n --color never \
  '(This helps us calculate your life remaining|Welcome to Mori|When were you born\?|You have approximately %@ weeks remaining|onboarding\.(progress_lived|time_remaining_accessibility|age_years|approx_weeks_remaining|age_old|life_expectancy_estimate))' \
  "${localization_paths[@]}" \
  "${xcloc_string_paths[@]}" \
  "${xcloc_xml_paths[@]}"

run_no_match_check \
  "Health permission copy must not frame Mori as a life timeline product" \
  rg -n --color never \
  'life timeline|人生時間線|人生时间线' \
  Localization/en.lproj/InfoPlist.strings \
  Localization/zh-Hant.lproj/InfoPlist.strings \
  Localization/zh-Hans.lproj/InfoPlist.strings \
  Mori/Info.plist \
  project.yml \
  Mori.xcodeproj/project.pbxproj

run_no_match_check \
  "Info.plist and project settings must not request old location/life-expectancy permissions" \
  rg -n --color never \
  '(NSLocationWhenInUseUsageDescription|estimate life expectancy|life expectancy for your country)' \
  Mori/Info.plist \
  project.yml \
  Mori.xcodeproj/project.pbxproj \
  Localization/en.lproj/InfoPlist.strings \
  Localization/zh-Hant.lproj/InfoPlist.strings \
  Localization/zh-Hans.lproj/InfoPlist.strings

run_no_match_check \
  "Health permission copy must match current recovery signals only" \
  rg -n --color never \
  '(birth date|biological sex|出生日期|生理性別|生理性别)' \
  Mori/Info.plist \
  project.yml \
  Mori.xcodeproj/project.pbxproj \
  Localization/en.lproj/InfoPlist.strings \
  Localization/zh-Hant.lproj/InfoPlist.strings \
  Localization/zh-Hans.lproj/InfoPlist.strings

run_no_match_check \
  "localization exports must not keep old Life Grid positioning copy" \
  rg -n --color never \
  'Use this grid to visualize your life|make each week count' \
  "${xcloc_string_paths[@]}" \
  "${xcloc_xml_paths[@]}"

run_no_match_check \
  "visible reset copy must not regress to old Practice wording" \
  rg -n --color never \
  '= "[^"]*(Practice App Limit active|Choose a reset practice|Which practice fits now|small practice|next practice|practice history|practice records|breathing practice|The practice is waiting|Recommended practice)' \
  "${localization_paths[@]}"

run_no_match_check \
  "active source must not reintroduce old Practice wording in user-facing strings" \
  rg -n --color never \
  --glob '*.swift' --glob '*.tsx' --glob '*.ts' \
  '"[^"]*(Practice App Limit active|Choose a reset practice|Which practice fits now|small practice|next practice|practice history|practice records|breathing practice|The practice is waiting|Recommended practice)' \
  "${source_paths[@]}"

run_no_match_check \
  "active source must use WeekArchive naming instead of old LifeGrid/LifeArchive UI names" \
  rg -n --color never \
  --glob '*.swift' --glob '*.tsx' --glob '*.ts' --glob '*.css' \
  '(LifeGrid|Life Grid|life-grid|life-cell|LifeArchive|LifeCalendar|life_grid\.(domain_completed|domain_chosen|week_age))' \
  "${source_paths[@]}" \
  Mori.xcodeproj/project.pbxproj

run_no_match_check \
  "localization keys and values must use Week Archive naming" \
  rg -n --color never \
  '(Life Grid|Life grid|life_grid|life grid)' \
  "${localization_paths[@]}"

run_no_match_check \
  "active source must not use old lifeGridProof or loop_grid analytics naming" \
  rg -n --color never \
  --glob '*.swift' \
  '(\.lifeGridProof|case lifeGridProof|gridViewed|loop_grid_view)' \
  App Features Models Services Shared Widgets WatchApp WatchWidgets ShieldAction ShieldConfiguration ScreenTimeMonitor

run_no_match_check \
  "onboarding design spec must not teach the old logo/countdown setup flow" \
  rg -n --color never \
  '(Mori Logo|mori-logo-gold|Welcome to Mori|When were you born\?|Life Grid|life grid|Your Life Grid|生命格子|生命以格子|每一格 = 一周|Memento mori|remember that you will die|hourglass|funnel|Make this week real)' \
  q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md

run_command_check \
  "onboarding design spec is App Limit-first with no-mark card surfaces" \
  bash -c "rg -q -- 'Onboarding is App Limit-first' q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md && rg -q -- 'screen-level wash through .*MoriPaperBackground.*not as a repeated card motif' q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md && rg -q -- 'Cards must not use app-icon art, brand lockups, wordmarks, seedling marks, circular emblems, leaf marks, or badge art as background imagery' q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md"

run_no_match_check \
  "App Limit-first onboarding must not keep location/life-expectancy infrastructure" \
  rg -n --color never \
  '(OnboardingLocationProvider|LifeExpectancyService|NSLocationWhenInUseUsageDescription|estimate life expectancy|life expectancy for your country)' \
  App Features Services Models Mori.xcodeproj/project.pbxproj Localization/*/InfoPlist.strings

run_no_match_check \
  "Settings UI must not expose old life-expectancy setup copy" \
  rg -n --color never \
  '(Your Life|Life Expectancy|Life Summary|Weeks Remaining|Looking up life expectancy|World Bank country and gender)' \
  Features/Settings/SettingsView.swift

run_no_file_name_match_check \
  "WeekArchive UI filenames must not use old archive/calendar view names" \
  '(LifeArchive|LifeCalendar|LifeWeek(Activity|Detail)Views)' \
  Features/WeekArchive

run_no_file_name_match_check \
  "WeekArchive Swift filenames must not keep old LifeWeek domain names" \
  'LifeWeek(Store|Calculator)?\.swift$' \
  Models \
  Services \
  Features/WeekArchive

run_no_match_check \
  "WeekArchive UI must use WeekArchiveRecord API, not LifeWeek domain names" \
  rg -n --color never \
  --glob '*.swift' \
  'LifeWeek(Store|Calculator|SyncStatus)?|LifeWeek\(' \
  Features/WeekArchive

run_command_check \
  "WeekArchive persistence exposes WeekArchiveRecord names at the Swift boundary" \
  bash -c "rg -q -- 'struct WeekArchiveRecord' Models/WeekArchiveCalculator.swift && rg -q -- 'final class WeekArchiveRecordStore' Services/WeekArchiveRecordStore.swift"

run_no_match_check \
  "app icon catalogs must not contain archived icon families" \
  rg -n --color never \
  '(hourglass|time_seed|forest_rings|forest_canopy|high_contrast|_mono|android_adaptive|android_foreground|/icon_[0-9]+\.png$|/android_icon_[0-9]+\.png$|/icon_1024\.png$)' \
  "${icon_paths[@]}"

run_no_match_check \
  "app icon catalogs must not reference archived icon families" \
  rg -n --color never \
  '(hourglass|time_seed|forest_rings|forest_canopy|high_contrast|_mono|icon_1024\.png)' \
  AppIcon.appiconset/Contents.json \
  DesignSystem/MoriBackgrounds.xcassets/AppIcon.appiconset/Contents.json

run_app_icon_bitmap_mirror_check

run_no_match_check \
  "web app assets must use the paper-watercolor direction" \
  rg -n --color never \
  '(mori-forest-canopy|forest_canopy|forest-canopy)' \
  www/src

run_no_match_check \
  "web token layer must not define old compatibility aliases" \
  rg -n --color never \
  '(Compatibility aliases|--mori-forest\b|--color-mori-forest\b|--mori-gold\b|--mori-sand\b|--time-gold\b|--deep-night\b|--ash-gray\b|--mori-cream\b|--mori-dark\b|--mori-gray-(dark|mid|light)\b|--mori-white\b|--mori-gold-gradient\b|--mori-dark-gradient\b|--shadow-gold\b|--color-mori-(gold|cream|charcoal)\b)' \
  www/src/styles/variables.css \
  www/src/index.css

run_no_match_check \
  "web UI must use bitmap assets instead of inline SVG icon markup" \
  rg -n --color never \
  --glob '*.tsx' --glob '*.ts' \
  '(<svg|</svg>|<path|<polyline)' \
  www/src

run_no_match_check \
  "web icon API must expose only typed bitmap icon names, not legacy aliases" \
  rg -n --color never \
  --glob '*.tsx' --glob '*.ts' \
  '(MoriLegacyIconAlias|\b(rose|chart|sunset|target|star|book|sun|moon|clock):|type\s+MoriIconName\s*=\s*MoriBitmapIconName\s*\|)' \
  www/src

run_no_match_check \
  "web app layer must not expose logo components or logo assets" \
  rg -n --color never \
  '(MoriLogo|mori-logo|mori-paper-linework-(logo|wordmark|icon)|Logo\.tsx|Logo\.css)' \
  www/src

run_no_match_check \
  "product UI source must not use logo or app-icon art as card/surface decoration" \
  rg -n --color never \
  --glob '*.swift' --glob '*.tsx' --glob '*.ts' --glob '*.css' \
  '\b(AppIcon|MoriLogo|wordmark)\b|mori-logo|mori-paper-linework-(logo|wordmark|icon)|paper_linework|\blogo\b' \
  App Features DesignSystem Shared Widgets WatchApp WatchWidgets ShieldAction ShieldConfiguration ScreenTimeMonitor www/src

run_no_match_check \
  "web shell must use App Limit-first bitmap direction" \
  rg -n --color never \
  '(favicon\.svg|image/svg|Nurture Good Habits|Track habits|grow mindfully)' \
  www/index.html

run_command_check \
  "web bitmap icon assets must mirror native generated art" \
  scripts/sync_web_bitmap_assets.sh --check

run_command_check \
  "web card component uses bitmap paper background" \
  rg -n --color never \
  'card-paper\.png' \
  www/src/components/Card.css

run_project_shared_source_check

run_generated_art_asset_catalog_check

run_command_check \
  "botanical watercolor assets must stay no-logo and no-badge" \
  scripts/generate_botanical_watercolor_assets.py --check

run_card_paper_material_boundary_check

run_no_match_check \
  "card backgrounds must not reference brand/logo/app-icon imagery" \
  rg -n --color never \
  --glob '*.swift' \
  '(Image\("[^"]*(AppIcon|logo|wordmark|paper_linework|mori-paper-linework)|UIImage\(named:\s*"[^"]*(AppIcon|logo|wordmark|paper_linework|mori-paper-linework))' \
  App \
  DesignSystem \
  Features \
  Shared \
  Widgets \
  WatchApp \
  WatchWidgets \
  ShieldAction \
  ShieldConfiguration \
  ScreenTimeMonitor

run_legacy_symbol_mapper_boundary_check

run_quiet_card_default_check

run_no_card_decoration_escape_hatch_check

run_command_check \
  "Reset practice cards use one inline summary instead of dense pill stacks" \
  bash -c "rg -q -- 'struct MoriPracticeInlineSummary' DesignSystem/MoriSanctuaryComponents.swift && rg -q -- 'MoriPracticeInlineSummary\\(practice: practice\\)' DesignSystem/MoriSanctuaryComponents.swift && rg -q -- 'MoriPracticeInlineSummary\\(practice: practice\\)' Features/Settle/SettleSupportViews.swift && ! rg -n --color never 'FlowLayout\\(spacing: [67]\\) \\{[[:space:]]*MoriPill\\(title: practice\\.seedText' DesignSystem/MoriSanctuaryComponents.swift Features/Settle/SettleSupportViews.swift"

run_command_check \
  "Pulse topic manager is source-gated behind a compact default summary" \
  bash -c "rg -q -- '@State private var showsTopicControls = false' Features/Pulse/ClarityPulseView.swift && rg -q -- 'PulseTopicControlsSummary\\(' Features/Pulse/ClarityPulseView.swift && rg -q -- 'if recoveryStore\\.snapshot\\.status != \\.needsPermission' Features/Pulse/ClarityPulseView.swift && rg -q -- 'if showsTopicControls \\{' Features/Pulse/ClarityPulseView.swift && rg -q -- 'PulseTopicPickerCard\\(' Features/Pulse/ClarityPulseView.swift && rg -q -- 'shouldUseMockPulseForUITest' Features/Pulse/ClarityPulseView.swift && rg -q -- '-MoriUseMockPulseForUITest' Features/Pulse/ClarityPulseView.swift && rg -q -- '@State private var showsTopicLibrary = false' Features/Pulse/PulseTopicPickerCard.swift && rg -q -- 'Edit topic list' Features/Pulse/PulseTopicPickerCard.swift && rg -q -- 'if showsTopicLibrary \\{' Features/Pulse/PulseTopicPickerCard.swift && rg -q -- 'struct PulseTopicControlsSummary' Features/Pulse/ClarityPulseSupportViews.swift && rg -q -- 'Pulse topics' Features/Pulse/ClarityPulseSupportViews.swift"

run_command_check \
  "main surfaces screenshot audit covers direct runtime navigation" \
  bash scripts/check_main_surface_screenshot_audit.sh

run_command_check \
  "Reset simplification screenshot audit covers inline-summary root and expanded-menu runtime evidence" \
  bash scripts/check_reset_simplification_screenshot_audit.sh

run_command_check \
  "Pulse simplification screenshot audit covers compact default topic summary" \
  bash scripts/check_pulse_simplification_screenshot_audit.sh

run_command_check \
  "main surface refresh screenshot audit covers latest Log, Week Archive, and Pulse surfaces" \
  bash scripts/check_main_surface_refresh_screenshot_audit.sh

run_command_check \
  "system-flow screenshot audit covers Settings, First App Limit setup, and Advanced App Limits lock" \
  bash scripts/check_system_flow_screenshot_audit.sh

run_command_check \
  "no-logo card screenshot audit covers forced onboarding and Today surfaces" \
  bash scripts/check_card_no_logo_screenshot_audit.sh

run_command_check \
  "Dynamic Type screenshot audit covers onboarding, Today, and Settings at accessibility-large" \
  bash scripts/check_dynamic_type_screenshot_audit.sh

run_command_check \
  "zh-Hant runtime localization audit covers onboarding, Today, and first-layer Settings" \
  bash scripts/check_zh_hant_runtime_localization_audit.sh

run_command_check \
  "zh-Hant advanced App Limits audit covers lock lifecycle runtime localization" \
  bash scripts/check_zh_hant_advanced_app_limits_audit.sh

run_command_check \
  "zh-Hant gate settings audit covers Morning Gate, Before Feed detailed settings, and Shortcut guide" \
  bash scripts/check_zh_hant_gate_settings_audit.sh

run_command_check \
  "zh-Hant Pulse / Recovery audit covers Pulse root, Recovery permission state, and generated-card fallback" \
  bash scripts/check_zh_hant_pulse_recovery_audit.sh

run_command_check \
  "zh-Hant Recovery ready/detail audit covers deterministic runtime localization" \
  bash scripts/check_zh_hant_recovery_ready_detail_audit.sh

run_command_check \
  "Recovery HealthKit sample audit covers HealthKit-shaped service samples" \
  bash scripts/check_recovery_healthkit_sample_audit.sh

run_command_check \
  "zh-Hant Watch / Widget source audit covers localized watch controls and widget component title paths" \
  bash scripts/check_zh_hant_watch_widget_source_audit.sh

run_command_check \
  "iOS Widget runtime audit covers rendered Today, Journal, Pulse, and Lock Screen accessory proof" \
  bash scripts/check_widget_runtime_audit.sh

run_command_check \
  "color contrast tokens meet WCAG AA text thresholds" \
  bash scripts/check_color_contrast_tokens.sh

run_command_check \
  "Reduce Motion contract covers native and web motion surfaces" \
  bash scripts/check_reduced_motion_contract.sh

run_command_check \
  "web screenshot audit covers no-logo botanical desktop and mobile surfaces" \
  bash scripts/check_web_screenshot_audit.sh

run_shield_icon_asset_check

run_no_match_check \
  "central native background must stay bitmap watercolor, not synthetic bloom art" \
  rg -n --color never \
  '(MoriCanopyBackground|MoriCanopyWash|MoriCanopyBloom|RadialGradient)' \
  DesignSystem/MoriPaperBackground.swift

run_command_check \
  "central native background uses screen-level botanical watercolor bitmap" \
  rg -n --color never \
  'MoriBotanicalScreenBackdrop\(variant:\s*variant\)' \
  DesignSystem/MoriPaperBackground.swift

run_no_match_check \
  "active native source must use MoriPaperBackground naming" \
  rg -n --color never \
  --glob '*.swift' \
  'MoriForestBackground' \
  App Features DesignSystem Shared Widgets WatchApp WatchWidgets ShieldAction ShieldConfiguration ScreenTimeMonitor

run_no_match_check \
  "native token layer must not expose forest compatibility aliases" \
  rg -n --color never \
  --glob '*.swift' \
  'static let forest[A-Za-z]+' \
  DesignSystem/MoriThemeTokens.swift

run_no_match_check \
  "card component API must not use seed/logo language" \
  rg -n --color never \
  --glob '*.swift' \
  'MoriSeedCard|LogoCard|WordmarkCard|AppIconCard' \
  App Features DesignSystem Shared Widgets WatchApp WatchWidgets ShieldAction ShieldConfiguration ScreenTimeMonitor

run_no_match_check \
  "card surfaces must use no-logo watercolor paper wash" \
  rg -n --color never \
  --glob '*.swift' \
  'MoriGeneratedArtImage\(art:\s*\.cardWash' \
  App Features DesignSystem Widgets WatchApp WatchWidgets ShieldAction ShieldConfiguration ScreenTimeMonitor

run_no_match_check \
  "active surfaces must not use leaf mark as decorative background watermark" \
  rg -n --color never \
  --glob '*.swift' \
  'MoriGeneratedHeroArt\(art:\s*\.leafMark' \
  App Features DesignSystem Widgets WatchApp WatchWidgets ShieldAction ShieldConfiguration ScreenTimeMonitor

run_no_match_check \
  "active app surfaces must not render logo or leaf-mark art directly" \
  rg -n --color never \
  --glob '*.swift' \
  '(\.leafMark\b|moriArtLeafMark|\.cardWash\b|moriCardWash)' \
  App Features DesignSystem Widgets WatchApp WatchWidgets ShieldAction ShieldConfiguration ScreenTimeMonitor

run_no_match_check \
  "active app source must not expose unused generated hero art assets" \
  rg -n --color never \
  --glob '*.swift' \
  '(moriArtBreatheOrb|moriArtFocusRing|moriArtRootsHero|\.breatheOrb\b|\.focusRing\b|\.rootsHero\b)' \
  App Features DesignSystem Shared Widgets WatchApp WatchWidgets ShieldAction ShieldConfiguration ScreenTimeMonitor

run_no_file_name_match_check \
  "generated art catalog must not keep unused hero art imagesets" \
  '(moriArtBreatheOrb|moriArtFocusRing|moriArtRootsHero)' \
  Shared/MoriGeneratedArt.xcassets

run_no_match_check \
  "native product surfaces must not call legacy card or input compatibility APIs" \
  rg -n --color never \
  --glob '*.swift' \
  '\b(MoriCard|MoriTextField)\s*[\(\{]' \
  App Features Widgets WatchApp WatchWidgets ShieldAction ShieldConfiguration ScreenTimeMonitor

run_no_match_check \
  "DesignSystem must not expose legacy v1 component APIs" \
  rg -n --color never \
  --glob '*.swift' \
  '((struct|class|enum)\s+(MoriCard|MoriTextField|MoriCheckbox|MoriToggle|MoriRadioGroup|MoriSegmentedControl|MoriProgressBar|MoriCircularProgress|MoriActivityIndicator|MoriLoadingSpinner|MoriCardStyle|MoriButtonStyle)\b|func\s+moriCard\s*\(|static\s+func\s+mori\s*\(|static\s+var\s+mori\b)' \
  DesignSystem

run_no_match_check \
  "DesignSystem Swift must not define removed legacy token aliases" \
  rg -n --color never \
  --glob '*.swift' \
  'static\s+let\s+(moriGold|moriGoldLight|moriGoldDark|zenCream|zenCreamDark|zenCreamLight|charcoal|charcoalLight|charcoalMuted|sageGreen|sageGreenLight|mistBlue|mistBlueLight|emberOrange|emberOrangeLight|textPrimary|textSecondary|textTertiary|textDisabled|bgPrimary|bgSecondary|bgTertiary|bgDark|borderLight|borderMedium|borderDark|shadowSoft|shadowMedium|shadowStrong|moriDark|moriDarkElevated|moriDarkSurface|moriCream|moriCreamLight|moriCreamMuted|moriHairline|headline1|display2|subhead|creamWhite|softCream|warmGray|softTaupe|warmCharcoal|deepEspresso|accentAmber|softSage|warmClay|morningGold)\b' \
  DesignSystem

run_no_match_check \
  "active native source must use botanical color aliases, not forest compatibility aliases" \
  bash -c "rg -n --color never --glob '*.swift' 'MoriColors\\.forest[A-Z]' App Features DesignSystem Widgets WatchApp WatchWidgets ShieldAction ShieldConfiguration ScreenTimeMonitor | rg -v '^DesignSystem/MoriThemeTokens\\.swift:'"

run_no_match_check \
  "active design docs must not teach removed legacy token aliases" \
  rg -n --color never \
  --glob '*.md' \
  '(Compatibility Warm Palette|Design Spec Compatibility|--mori-gold|--zen-cream|--charcoal|--sage-green|--mist-blue|--ember-orange|\b(moriGold|zenCream|sageGreen|mistBlue|emberOrange|bgPrimary|borderLight|shadowSoft|moriDark|moriCream|moriHairline)\b)' \
  DesignSystem/MoriDesignSystemDocumentation.md \
  brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md

run_no_match_check \
  "native product surfaces and active docs must use botanical metric naming" \
  rg -n --color never \
  --glob '*.swift' --glob '*.md' \
  '\bMoriForestProgressBar\b' \
  App Features Widgets WatchApp WatchWidgets ShieldAction ShieldConfiguration ScreenTimeMonitor \
  DesignSystem \
  DesignSystem/MoriDesignSystemDocumentation.md \
  brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md

run_command_check \
  "native screenshot audit launch arguments are available" \
  rg -n --color never \
  'MoriForceOnboardingForUITest|MoriSkipOnboardingForUITest' \
  Models/UserSettingsStore.swift

run_direct_botanical_backdrop_usage_check
run_widget_surface_shell_check
run_no_match_check \
  "widget color APIs must use botanical/paper names, not old palette aliases" \
  rg -n --color never \
  'MoriWidgetColors\.(gold|cream|creamMuted|dark)\b|static\s+let\s+(gold|cream|creamMuted|dark|forestDeep)\b' \
  Widgets

run_watch_surface_shell_check
run_widget_snapshot_typed_icon_check

run_no_match_check \
  "Watch app surfaces must not use flat palette backgrounds as root paper" \
  rg -n --color never \
  --glob '*.swift' \
  'MoriWatchPalette\.background\.ignoresSafeArea\(\)' \
  WatchApp

run_no_match_check \
  "Shield configuration must use generated bitmap icon assets, not system icons" \
  rg -n --color never \
  'UIImage\(systemName:' \
  ShieldConfiguration

run_no_direct_sf_symbol_check \
  "Today surface must use Mori bitmap icons instead of direct SF Symbol imagery" \
  Features/Today

run_no_direct_sf_symbol_check \
  "Reset, Log, and Pulse root surfaces must use Mori bitmap icons instead of direct SF Symbol imagery" \
  Features/Settle/SettleView.swift \
  Features/Settle/SettleSupportViews.swift \
  Features/DailySpark/DailySparkCard.swift \
  Features/GratitudeJournal/GratitudeJournalScreenSupport.swift \
  Features/Pulse/ClarityPulseSupportViews.swift \
  Features/Pulse/PulseComponents.swift \
  Features/Recovery/MoriRecoveryPulseCardSections.swift

run_no_direct_sf_symbol_check \
  "HabitTracker, Log, Practice, Pulse, Quiet, Recovery, Settle, Screen Time, and WeekArchive feature folders must not reintroduce direct SF Symbol imagery" \
  Features/HabitTracker \
  Features/GratitudeJournal \
  Features/Practice \
  Features/Pulse \
  Features/Quiet \
  Features/Recovery \
  Features/Settle \
  Features/ScreenTime \
  Features/WeekArchive

run_no_direct_sf_symbol_check \
  "native app, widget, watch, shield, and design-system surfaces must not reintroduce direct SF Symbol imagery" \
  App \
  Features \
  DesignSystem \
  Shared \
  Widgets \
  WatchApp \
  WatchWidgets \
  ShieldAction \
  ShieldConfiguration \
  ScreenTimeMonitor

run_no_match_check \
  "DesignSystem Swift APIs must expose typed MoriBitmapIcon values, not SF Symbol string adapters" \
  rg -n --color never \
  --glob '*.swift' \
  '(\.from\(systemName:|\bsymbolName\b|symbolName:|\bsystemIconName\b|\bsystemImage\b|systemName:)' \
  DesignSystem

run_no_match_check \
  "practice UI surfaces must use MoriPractice.icon instead of practice.symbolName adapter" \
  rg -n --color never \
  --glob '*.swift' \
  '(practice\.symbolName|suggestedPractice\.symbolName|recommendedPractice\.symbolName|\.from\(systemName:[^\n]*practice)' \
  App \
  Features \
  DesignSystem \
  Widgets \
  WatchApp \
  WatchWidgets

run_no_match_check \
  "Screen Time UI surfaces must use typed MoriBitmapIcon values" \
  rg -n --color never \
  --glob '*.swift' \
  '(\.from\(systemName:|\bsymbolName\b|permissionSymbolName|primarySystemImage|summary\.feature\.symbolName|currentSource\.symbolName)' \
  Features/ScreenTime

run_no_match_check \
  "Recovery UI surfaces must use typed MoriBitmapIcon values" \
  rg -n --color never \
  --glob '*.swift' \
  '(\.from\(systemName:|\bsymbolName\b|tagID\.symbolName|tag\.id\.symbolName|insight\.factorTag\.symbolName|signal\.symbolName|snapshot\.state\.symbolName)' \
  Features/Recovery

run_no_match_check \
  "Recovery signal builders must construct typed bitmap icons" \
  rg -n --color never \
  --glob '*.swift' \
  'symbolName:' \
  Services/MoriRecoverySignalBuilder.swift

run_settle_typed_icon_check

run_pulse_typed_icon_check

run_week_archive_typed_icon_check

run_quiet_typed_icon_check

run_gratitude_typed_icon_check

run_no_match_check \
  "App Limit-first surfaces must not reintroduce life-countdown copy" \
  rg -n --color never \
  --glob '*.swift' \
  '(primaryCountdown|primaryCompactCountdown|life\.today\.time_left|Countdown unit|weeks left|days to spend well|left today|widget\.countdown|watch\.countdown)' \
  Features/Today \
  Features/Settings \
  Widgets \
  WatchApp \
  WatchWidgets \
  Shared

run_no_match_check \
  "retired countdown/profile infrastructure must not return" \
  rg -n --color never \
  --glob '*.swift' \
  --glob '*.pbxproj' \
  '(ClockTimeUnit|clockTimeUnit|MoriWidgetTimeUnit|UserGender|locationCountry|HealthProfileProvider|HealthProfile|MoriCountdownDisplay|largeNumber)' \
  App \
  Features \
  Models \
  Services \
  Shared \
  Widgets \
  WatchApp \
  WatchWidgets \
  Mori.xcodeproj

run_no_match_check \
  "WeekArchive must not depend on legacy UserManager profile plumbing" \
  rg -n --color never \
  --glob '*.swift' \
  --glob '*.pbxproj' \
  '(UserManager|updateLifeExpectancy|currentUser|life_expectancy)' \
  App \
  Features \
  Models \
  Services \
  Shared \
  Widgets \
  WatchApp \
  WatchWidgets \
  Mori.xcodeproj

run_no_match_check \
  "active localization must not keep retired countdown/profile strings" \
  rg -n --color never \
  '("time_unit\.|gender\.|settings\.life_expectancy|Mori can estimate life expectancy|Looking up life expectancy|Your Life|Countdown unit|life\.today\.time_left|widget\.countdown|weeks left|days to spend well|week_archive\.clock_cta\.detail|days remaining|weeks lived|%lld weeks)' \
  Localization \
  Mori/en.xcloc

run_archive_start_legacy_key_boundary_check

run_no_match_check \
  "active brand docs must not keep old logo directions as source of truth" \
  rg -n --color never \
  '(MoriForestBackground|forest-paper|forest-canopy|time-seed|Time Seed|hourglass|MORI_TIME_SEED|MORI_FOREST_CANOPY)' \
  brand-assets

run_command_check \
  "active brand docs must define generated PNG as the only visual master" \
  bash -c "rg -q -- 'Generated PNG source, not SVG/vector, as the visual master' brand-assets/MORI_PAPER_LINEWORK_LOGO.md && rg -q -- 'SVG exports are not allowed to replace the generated PNG master' brand-assets/MORI_PAPER_LINEWORK_LOGO.md && rg -q -- 'Generated raster PNG, not SVG' brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md"

run_command_check \
  "active design docs must treat the logo as brand identity, not UI texture" \
  bash -c "rg -q -- 'Logo Is Not Texture' DesignSystem/MoriDesignSystemDocumentation.md && rg -q -- 'In-app cards use paper, ink, and breathing room, not a repeated brand signature' DesignSystem/MoriDesignSystemDocumentation.md"

run_command_check \
  "active design docs must teach watercolor bitmap action materials" \
  bash -c "rg -q -- 'Bitmap Actions' DesignSystem/MoriDesignSystemDocumentation.md && rg -q -- 'moriButtonWash' DesignSystem/MoriDesignSystemDocumentation.md && rg -q -- 'not flat synthetic slabs or brand badges' DesignSystem/MoriDesignSystemDocumentation.md"

run_no_match_check \
  "active design docs must teach bitmap icon APIs, not SF Symbol fallbacks" \
  rg -n --color never \
  '(MoriIconButton\(systemName:|Image\(systemName:|Label\([^\n]*systemImage:|SF Symbols?)' \
  DesignSystem/MoriDesignSystemDocumentation.md \
  brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md

run_no_match_check \
  "active design docs must not teach legacy v1 component APIs" \
  rg -n --color never \
  '(MoriCard|MoriTextField|MoriCheckbox|MoriToggle|MoriRadioGroup|MoriSegmentedControl|MoriProgressBar|MoriCircularProgress|MoriActivityIndicator|MoriLoadingSpinner)' \
  DesignSystem/MoriDesignSystemDocumentation.md \
  brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md

run_no_match_check \
  "active design docs must teach sanctuary tokens, not legacy color aliases" \
  rg -n --color never \
  '(MoriColors\.(creamWhite|softCream|warmCharcoal|accentAmber|warmGray|softTaupe|deepEspresso|morningGold|warmClay)\b)' \
  DesignSystem/MoriDesignSystemDocumentation.md \
  brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md

run_no_match_check \
  "active design docs must not claim unresolved legacy component files remain" \
  rg -n --color never \
  '(remaining legacy|duplicate legacy components|legacy design-system files|legacy component files|legacy mockups)' \
  DesignSystem/MoriDesignSystemDocumentation.md \
  brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md

run_no_match_check \
  "active design docs must not point builders at legacy source-of-truth paths" \
  rg -n --color never \
  '(v1\.0 \(Current\)|v1\.1 Planned Features|v2\.0 Roadmap|Icon system integration|Design system playground|/design/|/mockups/|q2-prep|Icon Concepts)' \
  DesignSystem/MoriDesignSystemDocumentation.md \
  brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md

run_no_match_check \
  "active design docs and tokens must not teach retired countdown UI" \
  rg -n --color never \
  '(MoriCountdownDisplay|largeNumber|days remaining|big countdown numbers|life expectancy settings|HealthProfileProvider)' \
  DesignSystem/MoriDesignSystemDocumentation.md \
  DesignSystem/MoriDesignTokens.swift \
  DesignSystem/MoriStateComponents.swift \
  brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md

run_required_file_check "MORI_REDESIGN_OPERATING_MODEL.md"
run_required_file_check "MORI_REDESIGN_RELEASE_AUDIT.md"
run_required_file_check "scripts/check_redesign_release_readiness.sh"
run_required_file_check "scripts/check_card_no_logo_screenshot_audit.sh"
run_required_file_check "scripts/check_reset_simplification_screenshot_audit.sh"
run_required_file_check "scripts/check_pulse_simplification_screenshot_audit.sh"
run_required_file_check "scripts/check_color_contrast_tokens.sh"
run_required_file_check "scripts/check_dynamic_type_screenshot_audit.sh"
run_required_file_check "scripts/check_zh_hant_runtime_localization_audit.sh"
run_required_file_check "scripts/check_zh_hant_advanced_app_limits_audit.sh"
run_required_file_check "scripts/check_zh_hant_gate_settings_audit.sh"
run_required_file_check "scripts/check_zh_hant_pulse_recovery_audit.sh"
run_required_file_check "scripts/check_zh_hant_recovery_ready_detail_audit.sh"
run_required_file_check "scripts/check_recovery_healthkit_sample_audit.sh"
run_required_file_check "scripts/check_zh_hant_watch_widget_source_audit.sh"
run_required_file_check "scripts/check_zh_hant_watch_runtime_audit.sh"
run_required_file_check "scripts/check_watch_complication_source_audit.sh"
run_required_file_check "scripts/check_widget_runtime_audit.sh"
run_required_file_check "scripts/check_accessibility_semantics_audit.sh"
run_required_file_check "scripts/check_accessibility_target_order_audit.sh"
run_required_file_check "scripts/check_reduced_motion_contract.sh"
run_required_file_check "scripts/check_main_surface_refresh_screenshot_audit.sh"
run_required_file_check "scripts/check_system_flow_screenshot_audit.sh"

run_command_check \
  "redesign operating model defines active product and infrastructure contracts" \
  bash -c "rg -q -- 'Mori is a Screen Time-first calm app with a botanical watercolor interface' MORI_REDESIGN_OPERATING_MODEL.md && rg -q -- 'Cards are content containers, not brand billboards' MORI_REDESIGN_OPERATING_MODEL.md && rg -q -- 'Botanical art is screen atmosphere, hero support, or a tiny functional accent, not repeated card wallpaper' MORI_REDESIGN_OPERATING_MODEL.md && rg -q -- 'brand mark as the texture' MORI_REDESIGN_OPERATING_MODEL.md && rg -q -- 'generated Xcode project must be produced from .*project.yml' MORI_REDESIGN_OPERATING_MODEL.md && rg -q -- 'scripts/check_redesign_release_readiness.sh' MORI_REDESIGN_OPERATING_MODEL.md && rg -q -- 'MORI_REDESIGN_RELEASE_AUDIT.md' MORI_REDESIGN_OPERATING_MODEL.md"

run_command_check \
  "README points builders at the redesign operating model" \
  bash -c "rg -q -- 'MORI_REDESIGN_OPERATING_MODEL.md' README.md && rg -q -- 'MORI_REDESIGN_RELEASE_AUDIT.md' README.md && rg -q -- 'scripts/check_redesign_release_readiness.sh' README.md"

run_command_check \
  "release-readiness script stitches source, generated project, design, web, and native checks" \
  bash -c "bash -n scripts/check_redesign_release_readiness.sh && rg -q -- 'xcodegen generate' scripts/check_redesign_release_readiness.sh && rg -q -- 'bash scripts/check_design_direction.sh' scripts/check_redesign_release_readiness.sh && rg -q -- 'pnpm --dir www --config.node-linker=hoisted build' scripts/check_redesign_release_readiness.sh && rg -q -- 'scripts/check_compiled_design_artifacts.sh' scripts/check_redesign_release_readiness.sh && rg -q -- 'scripts/check_reset_simplification_screenshot_audit.sh' scripts/check_redesign_release_readiness.sh && rg -q -- 'scripts/check_pulse_simplification_screenshot_audit.sh' scripts/check_redesign_release_readiness.sh && rg -q -- 'scripts/check_zh_hant_recovery_ready_detail_audit.sh' scripts/check_redesign_release_readiness.sh && rg -q -- 'scripts/check_recovery_healthkit_sample_audit.sh' scripts/check_redesign_release_readiness.sh && rg -q -- 'scripts/check_zh_hant_watch_runtime_audit.sh' scripts/check_redesign_release_readiness.sh && rg -q -- 'scripts/check_watch_complication_source_audit.sh' scripts/check_redesign_release_readiness.sh && rg -q -- 'scripts/check_widget_runtime_audit.sh' scripts/check_redesign_release_readiness.sh && rg -q -- 'scripts/check_accessibility_target_order_audit.sh' scripts/check_redesign_release_readiness.sh"

run_command_check \
  "compiled design artifact gate requires watercolor button material assets" \
  bash -c "bash -n scripts/check_compiled_design_artifacts.sh && rg -q -- 'moriButtonWash' scripts/check_compiled_design_artifacts.sh"

run_command_check \
  "redesign release audit records screenshot-backed UX and accessibility risks" \
  bash -c "rg -q -- 'Pass with refreshed runtime evidence and non-blocking polish risks' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'card-no-logo-2026-06-26/onboarding-no-logo-card.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'card-no-logo-2026-06-26/today-no-logo-card.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'main-surfaces-refresh-2026-06-26/log-refresh.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'main-surfaces-refresh-2026-06-26/week-archive-refresh.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'main-surfaces-refresh-2026-06-26/pulse-refresh.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'pulse-simplification-2026-06-26/pulse-topic-summary-default.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'pulse-topic-library-expanded.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'system-flows-2026-06-26/settings.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'system-flows-2026-06-26/first-app-limit-setup.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'system-flows-2026-06-26/advanced-app-limits-lock.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'system-flows-2026-06-26/advanced-app-limits-incorrect-pin.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'system-flows-2026-06-26/advanced-app-limits-cooldown.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'system-flows-2026-06-26/advanced-app-limits-unlocked.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'system-flows-2026-06-26/advanced-app-limits-lock-removed.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'dynamic-type-2026-06-26/onboarding-accessibility-large.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'dynamic-type-2026-06-26/today-accessibility-large.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'dynamic-type-2026-06-26/settings-accessibility-large.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'native-semantics-2026-06-26/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'reduced-motion-2026-06-26/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Core runtime semantic targets now have dedicated evidence' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Reduced Motion source contracts now cover native repeating motion and web motion surfaces' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Token-level native and web contrast checks now pass' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'token-level contrast checks now have dedicated evidence' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Fresh runtime evidence resolves the previous Log, Week Archive, Pulse default dashboard-density, Pulse expanded first-layer topic-manager, Pulse second-level topic-library, Reset root chip-density, Reset expanded first-layer menu, and Advanced App Limits incorrect-PIN/cooldown screenshot gaps' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Dynamic Type core surfaces, semantic accessibility targets, reduced-motion source contracts, and token-level contrast checks now have dedicated evidence' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Screenshot audit proves visible direction and major regression absence, not complete accessibility compliance' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records Reset inline-summary screenshot evidence" \
  bash -c "rg -q -- 'reset-simplification-2026-06-26/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'reset-simplification-2026-06-26/reset-inline-summary.png' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'reset-simplification-2026-06-26/reset-expanded-options.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'reset-simplification-2026-06-26/reset-expanded-practice-cards.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'MoriPracticeInlineSummary' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'instead of dense Seed/domain pill stacks' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'first expanded practice cards' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records Pulse compact-topic screenshot evidence" \
  bash -c "rg -q -- 'pulse-simplification-2026-06-26/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'pulse-simplification-2026-06-26/pulse-topic-summary-default.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'pulse-topic-manager-expanded.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'pulse-topic-manager-expanded-edit-row.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'pulse-topic-library-expanded.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'collapses the previous always-visible .*Manage Topics.* card into one compact .*Pulse topics.* row' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'hides the Recovery insight opt-in while Recovery is still in the Health permission state' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'expanded first layer shows active topics, queued topics, and a second-level .*Edit topic list.* row' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'full topic library and custom-topic input appear only after the second deliberate tap' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'localized Pulse topic-library layout' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records watercolor button material asset coverage" \
  bash -c "rg -q -- 'moriButtonWash' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'buttons share the watercolor-paper system' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'main app, shield extension, iOS widgets, Watch app, and Watch widgets' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records zh-Hant runtime localization evidence" \
  bash -c "rg -q -- 'zh-hant-runtime-2026-06-26/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'zh-Hant runtime localization: healthy for the core path' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'zh-Hant core runtime surfaces' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'zh-Hant runtime snapshots prove the inspected core path, Advanced App Limits lock lifecycle, Gate Settings branches, Pulse / Recovery permission-state surfaces, deterministic Recovery ready/detail surfaces, and the Watch app root surface only' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Widget rendered localized-layout evidence, live Apple Health database Recovery sample coverage, and long-tail settings still need separate proof' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records zh-Hant advanced App Limits evidence" \
  bash -c "rg -q -- 'zh-hant-advanced-app-limits-2026-06-26/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'zh-Hant Advanced App Limits lock lifecycle' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'locked entry, incorrect PIN, cooldown, and unlocked management' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'zh-Hant Advanced App Limits snapshots prove App Limits Lock setup, locked entry, incorrect PIN, cooldown, and unlocked App Limits management' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records zh-Hant gate settings evidence" \
  bash -c "rg -q -- 'zh-hant-gate-settings-2026-06-26/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'zh-Hant Gate Settings: healthy for the inspected Morning Gate and Before Feed branches' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Morning Gate, Before Feed detailed settings, and the Shortcut guide' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Widget rendered localized-layout evidence' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records zh-Hant Pulse / Recovery evidence" \
  bash -c "rg -q -- 'zh-hant-pulse-recovery-2026-06-26/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'zh-Hant Pulse / Recovery: healthy for the inspected Pulse root and Recovery permission-state branches' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Pulse root, Recovery permission state, and generated-card fallback' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'MoriDailyPulse locale fallback now prevents English cached or generated cards from leaking into the inspected zh-Hant Pulse topic-card stack' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records zh-Hant Recovery ready/detail evidence" \
  bash -c "rg -q -- 'zh-hant-recovery-ready-detail-2026-06-26/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'zh-Hant Recovery ready/detail: healthy for deterministic runtime evidence' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'recovery-ready-card-zh-hant.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'recovery-detail-zh-hant.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'does not claim live Apple Health database sample coverage' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records Recovery HealthKit sample service evidence" \
  bash -c "rg -q -- 'recovery-healthkit-samples-2026-06-26/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Recovery HealthKit sample service: healthy for service-level HealthKit-shaped coverage' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'MoriRecoveryHealthService.snapshot\\(requestAuthorization:\\)' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'HKQuantitySample' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'HKCategorySample' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'HKWorkout' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'live Apple Health database sample coverage' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records zh-Hant Watch / Widget source evidence" \
  bash -c "rg -q -- 'zh-hant-watch-widget-source-2026-06-26/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'zh-Hant Watch / Widget source localization: healthy for source-level controls and widget component paths' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Watch Bell settings, Watch timer setup, Watch notification copy, Widget title component paths, and WidgetKit gallery metadata descriptions now have source-level zh-Hant coverage' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records zh-Hant Watch runtime root evidence" \
  bash -c "rg -q -- 'watch-runtime-zh-hant-20260626/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'zh-Hant Watch app root runtime: healthy for the inspected root surface' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'watch-app-root-fixed.png' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'archive week' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- '歸檔週' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Widget rendered families, notification delivery UI, and full VoiceOver traversal remain outside this proof' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records Watch complication source and compiled asset proof" \
  bash -c "rg -q -- 'watch-complications-source-20260626/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Watch complication source/compiled proof: healthy for bounded source and compiled-asset evidence' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'both define .*accessoryCircular.*, .*accessoryCorner.*, .*accessoryRectangular.*, and .*accessoryInline.* family branches' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'mori://week/archive' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'mori://pulse/recovery' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'moriIconRoots' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'moriIconPulse' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'moriIconHeart' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'does not prove rendered complications on an Apple Watch face' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Watch complication rendered watch-face layout' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records iOS Widget rendered runtime evidence" \
  bash -c "rg -q -- 'widget-runtime-20260626/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'iOS Widget runtime: healthy for Today Home Screen system families, Journal / Pulse Home Screen inspected system families, Pulse Lock Screen editor accessory placement, Journal / Pulse WidgetKit system-family logs, and Today / Pulse Lock Screen circular/rectangular accessory paths' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'ios-home-mori-today-small-widget-fixed.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'ios-home-mori-today-medium-widget-fixed.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'ios-home-mori-today-large-widget-fixed.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'ios-home-mori-pulse-small-widget-fixed.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'ios-home-mori-pulse-medium-widget-fixed.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'ios-home-mori-pulse-large-widget-fixed.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'ios-home-mori-journal-pulse-small-widgets-fixed.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'ios-home-mori-journal-medium-widget-fixed.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'ios-lockscreen-editor-mori-pulse-accessory-widgets.jpg' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'widgetkit-log-journal-pulse-widgets.txt' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'widgetkit-log-lockscreen-accessory-attempt.txt' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'MoriWidgets' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'MoriPulseWidget' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'MoriJournalQuickStartWidget' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'systemMedium' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'systemLarge' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'accessoryCircular' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'accessoryRectangular' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Content state did change to ready' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Content load successful' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'no imageTooLarge, ArchivingError, or timelineReloadFailed' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Today and Pulse Lock Screen accessoryCircular and accessoryRectangular via WidgetKit ready/live logs' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Pulse accessoryCircular/accessoryRectangular placement via a Lock Screen editor screenshot' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Widget rendered proof now covers iOS Today systemSmall, systemMedium, and systemLarge via Home Screen screenshots, Journal systemSmall/systemMedium and Pulse systemSmall/systemMedium/systemLarge via Home Screen screenshots' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "redesign release audit records bounded accessoryInline WidgetKit evidence" \
  bash -c "rg -q -- 'Today / Pulse .*accessoryInline.* descriptor, placeholder archive, and reload success evidence' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'proving only descriptor, placeholder archive, and reload success for Today / Pulse .*accessoryInline' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'It also proves Today and Pulse .*accessoryInline.* descriptor, placeholder archive, and reload success through .*widgetkit-log-after-fix.txt' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'It does not prove accessoryInline live rendering' MORI_REDESIGN_RELEASE_AUDIT.md"

run_command_check \
  "Watch complication source audit covers watchOS family wiring and compiled assets" \
  bash scripts/check_watch_complication_source_audit.sh

run_command_check \
  "zh-Hant Watch runtime screenshot audit covers root app surface" \
  bash scripts/check_zh_hant_watch_runtime_audit.sh

run_command_check \
  "native accessibility semantics audit covers core runtime targets" \
  bash scripts/check_accessibility_semantics_audit.sh

run_command_check \
  "native accessibility target-order audit covers modal target isolation" \
  bash scripts/check_accessibility_target_order_audit.sh

run_command_check \
  "redesign release audit records target-order accessibility evidence" \
  bash -c "rg -q -- 'native-target-order-2026-06-26/AUDIT.md' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'Core runtime target order and modal target isolation now have dedicated evidence' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'runtime target-list proxy' MORI_REDESIGN_RELEASE_AUDIT.md && rg -q -- 'full OS VoiceOver traversal order or Switch Control scan behavior' MORI_REDESIGN_RELEASE_AUDIT.md"

run_no_file_name_match_check \
  "active asset filenames must use the paper-watercolor direction" \
  '(hourglass|time_seed|forest_rings|forest_canopy|forest-canopy|mori-forest-canopy|MoriCanopySoft|CanopySoft|moriArtLeafMark|moriCardWash|moriBotanicalCardWash|high_contrast|_mono|android_adaptive|android_foreground|/icon_[0-9]+\.png$|/android_icon_[0-9]+\.png$|/icon_1024\.png$)' \
  "${asset_file_name_paths[@]}"

run_no_file_name_match_check \
  "brand asset filenames must only expose the paper-linework direction" \
  '(hourglass|time_seed|time-seed|forest_rings|forest_canopy|forest-canopy|mori-forest-canopy|MORI_TIME_SEED|MORI_FOREST_CANOPY|legacy-comparison)' \
  "${brand_asset_paths[@]}"

run_required_file_check "AppIcon.appiconset/icon_1024_paper_linework.png"
run_required_file_check "DesignSystem/MoriBackgrounds.xcassets/AppIcon.appiconset/icon_1024_paper_linework.png"
run_required_file_check "DesignSystem/MoriBackgrounds.xcassets/BotanicalBackdropOnboarding.imageset/BotanicalBackdropOnboarding.png"
run_required_file_check "DesignSystem/MoriBackgrounds.xcassets/BotanicalBackdropAppLimit.imageset/BotanicalBackdropAppLimit.png"
run_required_file_check "DesignSystem/MoriBackgrounds.xcassets/BotanicalBackdropSoftCanopy.imageset/BotanicalBackdropSoftCanopy.png"
run_required_file_check "Shared/MoriGeneratedArt.xcassets/moriCardPaperWash.imageset/moriCardPaperWash@3x.png"
run_required_file_check "Shared/MoriGeneratedArt.xcassets/moriCardSageWash.imageset/moriCardSageWash@3x.png"
run_required_file_check "Shared/MoriGeneratedArt.xcassets/moriCardWarmWash.imageset/moriCardWarmWash@3x.png"
run_required_file_check "Shared/MoriGeneratedArt.xcassets/moriCardCoolWash.imageset/moriCardCoolWash@3x.png"
run_required_file_check "Shared/MoriGeneratedArt.xcassets/moriBotanicalScreenWash.imageset/moriBotanicalScreenWash@3x.png"
run_required_file_check "Shared/MoriGeneratedArt.xcassets/moriButtonWash.imageset/moriButtonWash@3x.png"
run_required_file_check "www/src/assets/botanical/card-paper.png"
run_required_file_check "brand-assets/MORI_PAPER_LINEWORK_LOGO.md"
run_required_file_check "brand-assets/mori-paper-linework-icon-master-1024.png"
run_required_file_check "brand-assets/mori-paper-linework-logo.png"
run_required_file_check "www/src/assets/botanical/onboarding-paper.png"
run_required_file_check "www/public/favicon.png"
run_required_file_check "www/src/assets/icons/mori-icon-leaf.png"
run_required_file_check "www/src/assets/icons/mori-icon-pulse.png"
run_required_file_check "www/src/assets/icons/mori-icon-roots.png"
run_required_file_check "Features/WeekArchive/WeekArchiveDateMath.swift"
run_required_file_check "Features/WeekArchive/WeekArchiveViews.swift"
run_required_file_check "Features/WeekArchive/WeekArchiveSupportViews.swift"
run_required_file_check "Features/WeekArchive/WeekArchiveDetailViews.swift"
run_required_file_check "Features/Today/TodayWeekArchiveReferenceCard.swift"
run_required_file_check "www/src/components/WeekArchive.tsx"

if [ "$failures" -ne 0 ]; then
  printf '\nDesign direction gate failed with %d issue(s).\n' "$failures"
  exit 1
fi

printf '\nDesign direction gate passed.\n'
