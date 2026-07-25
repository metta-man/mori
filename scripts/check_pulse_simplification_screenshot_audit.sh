#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/lib/evidence_paths.sh
audit_dir="$(mori_evidence_path "output/screenshot-audit/pulse-simplification-2026-06-26" "${1:-}")"
export MORI_AUDIT_DIR="$audit_dir"

ruby <<'RUBY'
audit_dir = ENV.fetch("MORI_AUDIT_DIR")
audit_path = File.join(audit_dir, "AUDIT.md")
screenshot_paths = [
  File.join(audit_dir, "pulse-topic-summary-default.jpg"),
  File.join(audit_dir, "pulse-topic-manager-expanded.jpg"),
  File.join(audit_dir, "pulse-topic-manager-expanded-edit-row.jpg"),
  File.join(audit_dir, "pulse-topic-library-expanded.jpg")
]

problems = []

def require_file(path, problems)
  problems << "Missing required file: #{path}" unless File.file?(path)
end

def require_include(path, phrases, problems)
  require_file(path, problems)
  return unless File.file?(path)

  body = File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
  phrases.each do |phrase|
    problems << "#{path} missing phrase #{phrase.inspect}" unless body.include?(phrase)
  end
end

def require_match(path, pattern, message, problems)
  require_file(path, problems)
  return unless File.file?(path)

  body = File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
  problems << "#{path} missing #{message}" unless body.match?(pattern)
end

def image_dimensions(path, problems)
  require_file(path, problems)
  return [0, 0] unless File.file?(path)

  output = IO.popen(["sips", "-g", "pixelWidth", "-g", "pixelHeight", path], &:read)
  [
    output[/pixelWidth:\s*(\d+)/, 1].to_i,
    output[/pixelHeight:\s*(\d+)/, 1].to_i
  ]
end

require_include(audit_path, [
  "Pulse Simplification Screenshot Audit - 2026-06-26",
  "runtime evidence for the Pulse root simplification",
  "pulse-topic-summary-default.jpg",
  "pulse-topic-manager-expanded.jpg",
  "pulse-topic-manager-expanded-edit-row.jpg",
  "pulse-topic-library-expanded.jpg",
  "iPhone 15 Pro Max Mori QA",
  "-MoriSkipOnboardingForUITest",
  "-MoriUseMockPulseForUITest",
  "mori://pulse",
  "Pulse stats ribbon",
  "Recovery Pulse",
  "HealthKit permission call to action",
  "compact `Pulse topics` row",
  "first `Mind` topic insight in the first viewport",
  "previous always-visible `Manage Topics` card is no longer present",
  "defaults to a compact `Pulse topics` summary",
  "Recovery insight opt-in card is not shown while Recovery is still in the Health permission state",
  "PulseTopicPickerCard",
  "behind `showsTopicControls`",
  "explicit `Manage Topics` first layer",
  "active topics and the queued section appear",
  "default topic library and custom-topic input are still not dumped into the first expanded viewport",
  "second-level `Edit topic list` row",
  "Choose defaults or add one custom Pulse.",
  "second-level topic library after tapping `Edit topic list`",
  "default topic chips and `Add custom topic` input are visible only inside this explicit edit mode",
  "`Hide topic list` control remains available",
  "keeps this audit deterministic",
  "second-level topic library edit mode",
  "does not prove Pulse with real Apple Health recovery samples",
  "does not prove every localized Pulse layout, VoiceOver traversal order, or Dynamic Type behavior"
], problems)

require_include("Features/Pulse/ClarityPulseView.swift", [
  "@State private var showsTopicControls = false",
  "if recoveryStore.snapshot.status != .needsPermission",
  "MoriRecoveryInsightOptInCard(isEnabled: $recoveryInsightOptIn)",
  "PulseTopicControlsSummary(",
  "withAnimation(.snappy(duration: 0.22))",
  "showsTopicControls.toggle()",
  "if showsTopicControls {",
  "PulseTopicPickerCard(",
  ".transition(.opacity.combined(with: .move(edge: .top)))",
  "shouldUseMockPulseForUITest",
  "\"-MoriUseMockPulseForUITest\"",
  "MoriDailyPulse.mock(topics: clarityStore.activeTopicLabels)"
], problems)

require_include("Features/Pulse/PulseTopicPickerCard.swift", [
  "@State private var showsTopicLibrary = false",
  "topicLibraryToggle",
  "Edit topic list",
  "Hide topic list",
  "Choose defaults or add one custom Pulse.",
  "if showsTopicLibrary {",
  "topicLibrary",
  "defaultTopics",
  "customTopicEntry",
  "customTopics"
], problems)

require_include("Features/Pulse/ClarityPulseSupportViews.swift", [
  "struct PulseTopicControlsSummary: View",
  "Text(MoriL10n.display(\"Pulse topics\"))",
  "Text(isExpanded ? MoriL10n.display(\"Hide\") : MoriL10n.display(\"Manage\"))",
  "\"pulse.topic_controls.summary_more\"",
  "\"%@ and %d more · %d queued\"",
  "\"pulse.topic_controls.accessibility\""
], problems)

require_match(
  "Features/Pulse/ClarityPulseView.swift",
  /if\s+showsTopicControls\s*\{[\s\S]*?PulseTopicPickerCard\(/,
  "PulseTopicPickerCard gated behind showsTopicControls",
  problems
)

screenshot_paths.each do |screenshot_path|
  width, height = image_dimensions(screenshot_path, problems)
  if width != 369 || height != 800
    problems << "#{screenshot_path} expected 369x800, got #{width}x#{height}"
  end

  if File.file?(screenshot_path) && File.size(screenshot_path) < 20_000
    problems << "#{screenshot_path} is unexpectedly small: #{File.size(screenshot_path)} bytes"
  end
end

if problems.empty?
  puts "Pulse simplification screenshot audit covers the default compact summary, expanded first-layer manager, and second-level topic library."
else
  abort problems.join("\n")
end
RUBY
