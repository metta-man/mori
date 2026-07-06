#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ruby <<'RUBY'
audit_path = "output/accessibility-audit/native-target-order-2026-06-26/AUDIT.md"
problems = []

unless File.file?(audit_path)
  abort "Missing native target-order accessibility audit: #{audit_path}"
end

audit = File.read(audit_path)
required_phrases = [
  "Mori Native Target Order And Modal Isolation Audit - 2026-06-26",
  "iPhone 15 Pro Max Mori QA",
  "CODE_SIGNING_ALLOWED=NO",
  "-MoriSkipOnboardingForUITest",
  "-MoriForceOnboardingForUITest",
  "Today / Settings / App Limits path: `build_run_sim` succeeded, process `75599`, 0 warnings, 0 errors.",
  "Forced onboarding path: `build_run_sim` succeeded, process `76263`, 0 warnings, 0 errors.",
  "screenHash `0lzaph6`",
  "screenHash `07gp6nz`",
  "screenHash `12ocb39`",
  "screenHash `1f76owv`",
  "screenHash `1msffw6`",
  "target order:",
  "1. `Allow Screen Time`",
  "2. `Skip App Limit for now`",
  "1. `Settings`",
  "2. `Set App Limit`",
  "3. `Set one focus`",
  "4. `Start reset`",
  "5. `Open weeks archive`",
  "6. `Today`",
  "7. `Reset`",
  "8. `Log`",
  "No underlying Today root action targets remained in the Settings target list.",
  "The rs/1 text tree still included underlying labels from the off-modal hierarchy",
  "1. `6-digit PIN`",
  "2. `Confirm PIN`",
  "3. `Settings` back button",
  "5. `Self PIN`",
  "6. `Accountability PIN`",
  "7. `Save PIN`",
  "Save PIN` becomes an actionable target only after both PIN fields are filled with matching values.",
  "This audit proves a runtime target-list proxy for the inspected core path",
  "It does not prove full OS VoiceOver traversal order, Switch Control scan behavior",
  "Only the `targets` list is used here as action-order evidence."
]

required_phrases.each do |phrase|
  problems << "#{audit_path} missing phrase #{phrase.inspect}" unless audit.include?(phrase)
end

content_path = "App/ContentView.swift"
unless File.file?(content_path)
  problems << "Missing source contract file: #{content_path}"
else
  source = File.read(content_path)
  contracts = {
    ".allowsHitTesting(presentation.activeSheet == nil)" => source.scan(/\.allowsHitTesting\(presentation\.activeSheet == nil\)/).length,
    ".disabled(presentation.activeSheet != nil)" => source.scan(/\.disabled\(presentation\.activeSheet != nil\)/).length,
    ".accessibilityHidden(presentation.activeSheet != nil)" => source.scan(/\.accessibilityHidden\(presentation\.activeSheet != nil\)/).length
  }

  contracts.each do |contract, count|
    problems << "#{content_path} expected at least two #{contract} modal-isolation contracts, got #{count}" if count < 2
  end
end

sheet_path = "App/MoriAppSheets.swift"
if File.file?(sheet_path)
  sheet_source = File.read(sheet_path)
  [
    "case .settings:",
    "SettingsView()",
    "case .appLimits:",
    "LockedScreenTimeSettingsView()",
    "case .appLimitSetup:",
    "FirstAppLimitSetupView(routeSource: routeSource)"
  ].each do |needle|
    problems << "#{sheet_path} missing sheet source contract #{needle.inspect}" unless sheet_source.include?(needle)
  end
else
  problems << "Missing source contract file: #{sheet_path}"
end

settings_path = "Features/Settings/SettingsView.swift"
if File.file?(settings_path)
  settings_source = File.read(settings_path)
  [
    "Button(MoriL10n.display(\"Done\"))",
    "NavigationLink(value: SettingsRoute.appLimits)",
    "Stepper(",
    "ClockReminderSettingsRow()",
    "DailySparkReminderSettingsRow()",
    "JournalReminderSettingsRow()"
  ].each do |needle|
    problems << "#{settings_path} missing settings target contract #{needle.inspect}" unless settings_source.include?(needle)
  end
else
  problems << "Missing source contract file: #{settings_path}"
end

lock_access_path = "Features/ScreenTime/ScreenTimeSettingsLockAccessViews.swift"
if File.file?(lock_access_path)
  lock_source = File.read(lock_access_path)
  [
    "Save PIN",
    "Self PIN",
    "Accountability PIN",
    "6-digit PIN",
    "Confirm PIN"
  ].each do |needle|
    problems << "#{lock_access_path} missing lock target contract #{needle.inspect}" unless lock_source.include?(needle)
  end
else
  problems << "Missing source contract file: #{lock_access_path}"
end

if problems.empty?
  puts "Native target-order audit covers onboarding, Today, Settings modal isolation, and App Limits PIN setup target order."
else
  abort problems.join("\n")
end
RUBY
