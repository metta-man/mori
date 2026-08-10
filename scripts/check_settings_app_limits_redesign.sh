#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ruby <<'RUBY'
problems = []

settings = File.read("Features/Settings/SettingsView.swift")
app_limits = File.read("Features/ScreenTime/ScreenTimeSettingsView.swift")
locked_entry = File.read("Features/ScreenTime/LockedScreenTimeSettingsView.swift")
primary_sections = File.read("Features/ScreenTime/ScreenTimeSettingsPrimarySections.swift")

{
  "Settings root uses the editorial paper surface" => [settings, "MoriRootScrollScreen("],
  "Settings root gives App Limits a dedicated hero" => [settings, "SettingsAppLimitsCard(statusText:"],
  "App Limits root exposes Protected Apps" => [app_limits, "AppLimitsProtectedAppsCard("],
  "App Limits root keeps only the two everyday modes" => [app_limits, "AppLimitsSectionHeading("],
  "advanced controls have a dedicated destination" => [app_limits, "private func advancedSettings("],
  "diagnostics remain available in Advanced" => [app_limits, "ScreenTimeMonitorHealthSection("],
  "PIN protection is offered after setup" => [app_limits, "AppLimitsPINOfferCard("],
  "PIN prompt dismissal is persisted" => [app_limits, "mori_app_limits_pin_prompt_completed_v1"],
  "fresh App Limits entry opens settings without a mandatory PIN" => [locked_entry, "ScreenTimeSettingsView()"],
  "readiness UI provides one contextual action" => [primary_sections, "primaryActionTitle: String?"]
}.each do |label, (source, snippet)|
  problems << "Missing contract: #{label}" unless source.include?(snippet)
end

if locked_entry.include?("ScreenTimeSettingsPINSetupView")
  problems << "Fresh App Limits entry still forces PIN setup"
end

advanced_offset = app_limits.index("private func advancedSettings(")
monitor_offset = app_limits.index("ScreenTimeMonitorHealthSection(")
if advanced_offset.nil? || monitor_offset.nil? || monitor_offset < advanced_offset
  problems << "Screen Time diagnostics are visible before the Advanced destination"
end

required_localizations = {
  "Localization/en.lproj/Localizable.strings" => [
    '"Protect your attention" = "Protect your attention";',
    '"Prevent Changes" = "Prevent Changes";'
  ],
  "Localization/zh-Hant.lproj/Localizable.strings" => [
    '"Protect your attention" = "守住你的注意力";',
    '"Prevent Changes" = "防止修改";'
  ],
  "Localization/zh-Hans.lproj/Localizable.strings" => [
    '"Protect your attention" = "守住你的注意力";',
    '"Prevent Changes" = "防止修改";'
  ]
}

required_localizations.each do |path, lines|
  localized = File.read(path)
  lines.each do |line|
    problems << "#{path} missing #{line.inspect}" unless localized.include?(line)
  end
end

if problems.empty?
  puts "Settings and App Limits progressive-disclosure contracts pass."
else
  abort problems.join("\n")
end
RUBY
