#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/lib/evidence_paths.sh
audit_dir="$(mori_evidence_path "output/accessibility-audit/native-semantics-2026-06-26" "${1:-}")"
export MORI_AUDIT_DIR="$audit_dir"

ruby <<'RUBY'
audit_path = File.join(ENV.fetch("MORI_AUDIT_DIR"), "AUDIT.md")
problems = []

unless File.file?(audit_path)
  abort "Missing native accessibility semantics audit: #{audit_path}"
end

audit = File.read(audit_path)
required_phrases = [
  "Mori Native Accessibility Semantics Audit - 2026-06-26",
  "iPhone 15 Pro Max Mori QA",
  "-MoriForceOnboardingForUITest",
  "-MoriSkipOnboardingForUITest",
  "screenHash `08ueimg`",
  "screenHash `0kax0p7`",
  "screenHash `07ttbdr`",
  "screenHash `0g6yrab`",
  "Allow Screen Time",
  "Skip App Limit for now",
  "App Limit setup. One app. Less gravity.",
  "Settings",
  "Set App Limit",
  "Set one focus",
  "Start reset",
  "Open weeks archive",
  "Today",
  "Reset",
  "Log",
  "Done",
  "First App Limit, Permission needed to choose apps and apply limits.",
  "Archive Span: 80 years, Decrement",
  "Archive Span: 80 years, Increment",
  "Self PIN",
  "Accountability PIN",
  "6-digit PIN",
  "Confirm PIN",
  "Save PIN",
  "This audit proves runtime semantic targets on inspected core surfaces; it does not prove full VoiceOver traversal, focus order, Switch Control, reduced motion, hit target sizing in every state, screenshot-level contrast in every route, or every localized state."
]

required_phrases.each do |phrase|
  problems << "#{audit_path} missing phrase #{phrase.inspect}" unless audit.include?(phrase)
end

source_contracts = {
  "App/MoriAppTabBar.swift" => [
    /\.accessibilityLabel\(tab\.title\)/
  ],
  "Features/Today/TodayView.swift" => [
    /\.accessibilityLabel\(MoriL10n\.display\("Settings"\)\)/
  ],
  "Features/Today/TodaySupportViews.swift" => [
    /Set one focus/,
    /Edit focus,/,
    /\.accessibilityAddTraits\(\.isButton\)/,
    /\.accessibilityLabel\(MoriL10n\.display\("Start reset"\)\)/,
    /\.accessibilityHint\(MoriL10n\.display\("Opens reset practices"\)\)/,
    /\.accessibilityAction/
  ],
  "Features/ScreenTime/FirstAppLimitSetupView.swift" => [
    /\.accessibilityElement\(children:\s*\.combine\)/,
    /App Limit setup\. One app\. Less gravity\./
  ],
  "Features/ScreenTime/ScreenTimeSettingsPrimarySections.swift" => [
    /Allow Screen Time/,
    /Lock App Limits/,
    /Default App List/,
    /Remove PIN Lock/
  ],
  "Features/ScreenTime/ScreenTimeSettingsLockAccessViews.swift" => [
    /Save PIN/,
    /Generate and Share PIN/,
    /Unlock App Limits/
  ],
  "Features/ScreenTime/ScreenTimeSettingsLockManagementViews.swift" => [
    /Save Self PIN/,
    /Generate and Share New PIN/,
    /Remove PIN Lock/
  ],
  "DesignSystem/MoriPaperBackground.swift" => [
    /\.accessibilityHidden\(true\)/
  ],
  "DesignSystem/MoriBotanicalBackdrops.swift" => [
    /\.accessibilityHidden\(true\)/
  ],
  "Shared/MoriGeneratedArt.swift" => [
    /\.accessibilityHidden\(true\)/
  ]
}

source_contracts.each do |path, patterns|
  unless File.file?(path)
    problems << "Missing source contract file: #{path}"
    next
  end

  source = File.read(path)
  patterns.each do |pattern|
    problems << "#{path} missing source contract #{pattern.inspect}" unless source.match?(pattern)
  end
end

if problems.empty?
  puts "Native accessibility semantics audit covers onboarding, Today, Settings, and App Limits lock setup runtime targets."
else
  abort problems.join("\n")
end
RUBY
