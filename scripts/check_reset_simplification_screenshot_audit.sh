#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ruby <<'RUBY'
audit_dir = "output/screenshot-audit/reset-simplification-2026-06-26"
audit_path = File.join(audit_dir, "AUDIT.md")
screenshot_path = File.join(audit_dir, "reset-inline-summary.png")
expanded_options_screenshot_path = File.join(audit_dir, "reset-expanded-options.jpg")
expanded_cards_screenshot_path = File.join(audit_dir, "reset-expanded-practice-cards.jpg")

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

def require_no_match(path, pattern, message, problems)
  require_file(path, problems)
  return unless File.file?(path)

  body = File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
  problems << "#{path} must not contain #{message}" if body.match?(pattern)
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
  "Reset Simplification Screenshot Audit - 2026-06-26",
  "runtime evidence for the Reset root and first expanded reset-menu layer",
  "reset-inline-summary.png",
  "reset-expanded-options.jpg",
  "reset-expanded-practice-cards.jpg",
  "iPhone 15 Pro Max Mori QA",
  "-MoriSkipOnboardingForUITest",
  "mori://settle",
  "tap `More reset options`",
  "+1 Seed / Rest / Body / Mind",
  "instead of the previous dense Seed/domain pill stack",
  "Best Next Step",
  "Quiet Mode",
  "Start this reset",
  "Limit the next feed",
  "Hide reset menu",
  "Calm my body",
  "Breathe",
  "Settle",
  "+1 Seed / Body / Rest",
  "+1 Seed / Rest / Wonder",
  "MoriPracticeInlineSummary",
  "first expanded reset-menu runtime states",
  "They do not prove every lower practice card after scrolling through the full expanded reset menu",
  "does not prove every localized Reset layout",
  "does not prove VoiceOver traversal order or Dynamic Type behavior"
], problems)

require_include("DesignSystem/MoriSanctuaryComponents.swift", [
  "struct MoriPracticeInlineSummary: View",
  "Text(summaryText)",
  "MoriL10n.string(",
  "practice.inline_summary.accessibility",
  "MoriPracticeInlineSummary(practice: practice)"
], problems)

require_include("Features/Settle/SettleSupportViews.swift", [
  "MoriPracticeInlineSummary(practice: practice)"
], problems)

require_no_match(
  "DesignSystem/MoriSanctuaryComponents.swift",
  /FlowLayout\(spacing:\s*6\)\s*\{[\s\S]*?MoriPill\(title:\s*practice\.seedText/,
  "dense practice Seed/domain pill stack in MoriPracticeCard",
  problems
)

require_no_match(
  "Features/Settle/SettleSupportViews.swift",
  /FlowLayout\(spacing:\s*7\)\s*\{[\s\S]*?MoriPill\(title:\s*practice\.seedText/,
  "dense practice Seed/domain pill stack in PracticeHeroActionCard",
  problems
)

width, height = image_dimensions(screenshot_path, problems)
if width < 390 || height < 800
  problems << "#{screenshot_path} dimensions #{width}x#{height} are too small for Reset runtime evidence"
end

if File.file?(screenshot_path) && File.size(screenshot_path) < 20_000
  problems << "#{screenshot_path} is unexpectedly small: #{File.size(screenshot_path)} bytes"
end

[
  expanded_options_screenshot_path,
  expanded_cards_screenshot_path
].each do |path|
  width, height = image_dimensions(path, problems)
  if width < 360 || height < 760
    problems << "#{path} dimensions #{width}x#{height} are too small for expanded Reset runtime evidence"
  end

  if File.file?(path) && File.size(path) < 20_000
    problems << "#{path} is unexpectedly small: #{File.size(path)} bytes"
  end
end

if problems.empty?
  puts "Reset simplification screenshot audit covers the runtime inline-summary Reset root, expanded reset-menu cards, and source-level pill-stack removal."
else
  abort problems.join("\n")
end
RUBY
