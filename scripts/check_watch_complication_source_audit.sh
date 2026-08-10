#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/lib/evidence_paths.sh
audit_dir="$(mori_evidence_path "outputs/design-audit/watch-complications-source-20260626" "${1:-}")"
compiled_app_bundle="$(mori_evidence_path ".codex-build/DerivedData/Build/Products/Debug-iphonesimulator/Mori.app" "${2:-}")"
export MORI_AUDIT_DIR="$audit_dir"
export MORI_COMPILED_APP_BUNDLE="$compiled_app_bundle"

ruby -rjson <<'RUBY'
audit_dir = ENV.fetch("MORI_AUDIT_DIR")
audit_path = File.join(audit_dir, "AUDIT.md")
watch_source = "WatchWidgets/MoriWatchWidgets.swift"
project_path = "project.yml"
compiled_appex = File.join(
  ENV.fetch("MORI_COMPILED_APP_BUNDLE"),
  "Watch",
  "MoriWatch.app",
  "PlugIns",
  "MoriWatchWidgets.appex"
)
compiled_assets = File.join(compiled_appex, "Assets.car")
compiled_info = File.join(compiled_appex, "Info.plist")

problems = []

def require_file(path, problems)
  problems << "Missing required file: #{path}" unless File.file?(path)
end

def require_dir(path, problems)
  problems << "Missing required directory: #{path}" unless File.directory?(path)
end

def read_file(path)
  File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
end

def require_include(path, phrases, problems)
  require_file(path, problems)
  return unless File.file?(path)

  body = read_file(path)
  phrases.each do |phrase|
    problems << "#{path} missing phrase #{phrase.inspect}" unless body.include?(phrase)
  end
end

def require_match(path, pattern, message, problems)
  require_file(path, problems)
  return unless File.file?(path)

  body = read_file(path)
  problems << "#{path} missing #{message}" unless body.match?(pattern)
end

def require_asset_names(assets_car, names, problems)
  require_file(assets_car, problems)
  return unless File.file?(assets_car)

  assetutil_output = IO.popen(["assetutil", "--info", assets_car], &:read)
  assets = JSON.parse(assetutil_output)
  actual_names = assets.filter_map { |asset| asset["Name"] }.uniq
  missing = names - actual_names
  problems << "#{assets_car} missing compiled asset names: #{missing.join(", ")}" unless missing.empty?
end

def require_plist_value(path, expected, problems)
  require_file(path, problems)
  return unless File.file?(path)

  output = IO.popen(["plutil", "-p", path], &:read)
  problems << "#{path} missing plist value #{expected.inspect}" unless output.include?(expected)
end

require_include(audit_path, [
  "Watch Complications Source And Compiled Asset Audit - 2026-06-26",
  "bounded source-level and compiled-artifact evidence",
  "MoriWatchWidgetBundle",
  "MoriWatchWidgets",
  "MoriWatchPulseWidget",
  "`MoriWatchWidgets` uses `StaticConfiguration(kind: kind, provider: MoriWatchWidgetProvider())`",
  "`MoriWatchPulseWidget` uses `StaticConfiguration(kind: kind, provider: MoriWatchPulseProvider())`",
  ".accessoryCircular",
  ".accessoryCorner",
  ".accessoryRectangular",
  ".accessoryInline",
  "mori://week/archive",
  "mori://pulse/recovery",
  "MoriBitmapIconImage(icon: .roots",
  "MoriBitmapIconImage(icon: context.hasRecoverySnapshot ? .heart : .pulse",
  "project.yml` wires `MoriWatchWidgets` as a watchOS target",
  "com.apple.widgetkit-extension",
  "com.mettalabs.mori.watch.widgets",
  "moriIconRoots",
  "moriIconPulse",
  "moriIconHeart",
  "does not prove rendered complications on an Apple Watch face",
  "does not prove Watch complication WidgetKit gallery rendering",
  "does not prove localized rendered layout across watchOS complication families"
], problems)

require_include(watch_source, [
  "struct MoriWatchWidgetProvider: TimelineProvider",
  "struct MoriWatchWidgetsEntryView: View",
  "struct MoriWatchWidgets: Widget",
  "let kind = \"MoriWatchWidgets\"",
  "StaticConfiguration(kind: kind, provider: MoriWatchWidgetProvider())",
  ".widgetURL(URL(string: \"mori://week/archive\"))",
  ".configurationDisplayName(\"Today\")",
  ".description(\"Keep today and the week archive on your watch face.\")",
  "struct MoriWatchPulseProvider: TimelineProvider",
  "struct MoriWatchPulseEntryView: View",
  "struct MoriWatchPulseWidget: Widget",
  "let kind = \"MoriWatchPulseWidget\"",
  "StaticConfiguration(kind: kind, provider: MoriWatchPulseProvider())",
  ".widgetURL(URL(string: \"mori://pulse/recovery\"))",
  ".configurationDisplayName(\"Pulse\")",
  ".description(\"Track Pulse, Recovery, Bloom, Seeds, and reclaimed time.\")",
  "@main",
  "struct MoriWatchWidgetBundle: WidgetBundle",
  "MoriWatchWidgets()",
  "MoriWatchPulseWidget()",
  "private struct MoriWatchCircularComplication: View",
  "private struct MoriWatchCornerComplication: View",
  "private struct MoriWatchRectangularComplication: View",
  "private struct MoriWatchPulseCircularComplication: View",
  "private struct MoriWatchPulseCornerComplication: View",
  "private struct MoriWatchPulseRectangularComplication: View",
  "Gauge(value: snapshot.progress)",
  "Gauge(value: context.hasRecoverySnapshot ? context.recoveryProgress : context.bloomProgress)",
  ".gaugeStyle(.accessoryCircularCapacity)",
  ".widgetCurvesContent()",
  "MoriBitmapIconImage(icon: .roots, size: 12)",
  "MoriBitmapIconImage(icon: .roots, size: 10)",
  "MoriBitmapIconImage(icon: context.hasRecoverySnapshot ? .heart : .pulse, size: 12)",
  "MoriBitmapIconImage(icon: context.hasRecoverySnapshot ? .heart : .pulse, size: 10)",
  "Text(entry.snapshot.archiveWeekText)",
  "\"watch_widget.inline.recovery\"",
  "\"watch_widget.inline.pulse_topic\"",
  "\"widget.inline.bloom\""
], problems)

watch_body = File.file?(watch_source) ? read_file(watch_source) : ""
supported_family_blocks = watch_body.scan(/\.supportedFamilies\(\[\s*\.accessoryCircular,\s*\.accessoryCorner,\s*\.accessoryRectangular,\s*\.accessoryInline\s*\]\)/m)
problems << "#{watch_source} must declare all four watchOS complication families for both widgets" if supported_family_blocks.length < 2

require_match(
  watch_source,
  /struct MoriWatchWidgetsEntryView: View[\s\S]*?case \.accessoryCircular:[\s\S]*?case \.accessoryCorner:[\s\S]*?case \.accessoryRectangular:[\s\S]*?case \.accessoryInline:/,
  "Today entry view switch coverage for all watchOS complication families",
  problems
)

require_match(
  watch_source,
  /struct MoriWatchPulseEntryView: View[\s\S]*?case \.accessoryCircular:[\s\S]*?case \.accessoryCorner:[\s\S]*?case \.accessoryRectangular:[\s\S]*?case \.accessoryInline:/,
  "Pulse entry view switch coverage for all watchOS complication families",
  problems
)

require_match(
  project_path,
  /MoriWatch:[\s\S]*?platform: watchOS[\s\S]*?- path: WatchApp[\s\S]*?- target: MoriWatchWidgets[\s\S]*?embed: true/,
  "MoriWatch watchOS target embedding MoriWatchWidgets",
  problems
)

require_match(
  project_path,
  /MoriWatchWidgets:[\s\S]*?platform: watchOS[\s\S]*?- path: WatchWidgets[\s\S]*?INFOPLIST_FILE: WatchWidgets\/Info.plist/,
  "MoriWatchWidgets watchOS target source and Info.plist wiring",
  problems
)

require_match(
  project_path,
  /Mori:[\s\S]*?dependencies:[\s\S]*?- target: MoriWatch[\s\S]*?embed: true/,
  "iOS Mori target embedding MoriWatch",
  problems
)

require_dir(compiled_appex, problems)
require_file(compiled_assets, problems)
require_file(compiled_info, problems)
require_file(File.join(compiled_appex, "MoriWatchWidgets"), problems)

require_plist_value(compiled_info, "com.apple.widgetkit-extension", problems)
require_plist_value(compiled_info, "com.mettalabs.mori.watch.widgets", problems)
require_asset_names(compiled_assets, %w[moriIconRoots moriIconPulse moriIconHeart], problems)

if problems.empty?
  puts "Watch complication source audit proves watchOS complication family source wiring and compiled botanical assets with bounded runtime limits."
else
  abort problems.join("\n")
end
RUBY
