#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/lib/evidence_paths.sh
audit_dir="$(mori_evidence_path "output/localization-audit/zh-hant-runtime-2026-06-26" "${1:-}")"
export MORI_AUDIT_DIR="$audit_dir"

ruby <<'RUBY'
audit_dir = ENV.fetch("MORI_AUDIT_DIR")
audit_path = File.join(audit_dir, "AUDIT.md")

required_screenshots = {
  "onboarding-zh-hant.jpg" => "Forced onboarding zh-Hant runtime screenshot",
  "today-zh-hant.jpg" => "Today zh-Hant runtime screenshot",
  "settings-zh-hant.jpg" => "Settings zh-Hant runtime screenshot"
}

problems = []

def jpeg_dimensions(bytes)
  return nil unless bytes.start_with?("\xFF\xD8".b)

  index = 2
  sof_markers = [
    0xC0, 0xC1, 0xC2, 0xC3,
    0xC5, 0xC6, 0xC7,
    0xC9, 0xCA, 0xCB,
    0xCD, 0xCE, 0xCF
  ]

  while index < bytes.bytesize
    index += 1 while index < bytes.bytesize && bytes.getbyte(index) != 0xFF
    return nil if index >= bytes.bytesize

    index += 1
    marker = bytes.getbyte(index)
    index += 1

    next if marker == 0xFF || marker == 0x00
    return nil if marker == 0xD9 || marker == 0xDA
    next if marker == 0x01 || (0xD0..0xD7).include?(marker)
    return nil if index + 2 > bytes.bytesize

    length = bytes.byteslice(index, 2).unpack1("n")
    return nil if length.nil? || length < 2 || index + length > bytes.bytesize

    if sof_markers.include?(marker)
      return nil if length < 7
      height = bytes.byteslice(index + 3, 2).unpack1("n")
      width = bytes.byteslice(index + 5, 2).unpack1("n")
      return [width, height]
    end

    index += length
  end

  nil
end

unless Dir.exist?(audit_dir)
  abort "Missing zh-Hant runtime localization audit directory: #{audit_dir}"
end

unless File.file?(audit_path)
  problems << "Missing zh-Hant runtime localization audit note: #{audit_path}"
end

required_screenshots.each do |filename, label|
  path = File.join(audit_dir, filename)
  if !File.file?(path)
    problems << "Missing #{label}: #{path}"
    next
  end

  bytes = File.binread(path)
  problems << "#{path} is too small to be a useful screenshot (#{bytes.bytesize} bytes)" if bytes.bytesize < 10_000
  problems << "#{path} is not a JPEG screenshot" unless bytes.start_with?("\xFF\xD8\xFF".b)

  dimensions = jpeg_dimensions(bytes)
  if dimensions.nil?
    problems << "#{path} has unreadable JPEG dimensions"
  else
    width, height = dimensions
    problems << "#{path} expected 369x800, got #{width}x#{height}" unless width == 369 && height == 800
  end
end

if File.file?(audit_path)
  audit = File.read(audit_path)
  required_phrases = [
    "Mori zh-Hant Runtime Localization Audit - 2026-06-26",
    "iPhone 15 Pro Max Mori QA",
    "-AppleLanguages",
    "(zh-Hant)",
    "zh_Hant_HK",
    "onboarding-zh-hant.jpg",
    "Runtime snapshot hash `00g6qq5`",
    "today-zh-hant.jpg",
    "Runtime snapshot hash `1m6q2gb`",
    "settings-zh-hant.jpg",
    "Runtime snapshot hash `1pg3yjl`",
    "第一個 APP 限制",
    "設定 App 限制",
    "歸檔跨度：80 年",
    "does not claim every Watch, Widget, advanced App Limits, recovery, Pulse, or long-tail settings route"
  ]

  required_phrases.each do |phrase|
    problems << "#{audit_path} missing phrase #{phrase.inspect}" unless audit.include?(phrase)
  end
end

localized = File.read("Localization/zh-Hant.lproj/Localizable.strings")
required_localized_pairs = {
  "Set App Limit" => "設定 App 限制",
  "One clear action before the next feed." => "下一次資訊流前，只做一個清楚動作。",
  "archive week" => "歸檔週",
  "settings.week_archive.years_shown" => "歸檔跨度：%d 年",
  "This PIN is required before anyone can open Screen Time & App Limits." => "任何人打開 Screen Time 與 App 限制前，都需要呢個 PIN。"
}

required_localized_pairs.each do |key, value|
  line = "\"#{key}\" = \"#{value}\";"
  problems << "Localization/zh-Hant.lproj/Localizable.strings missing #{line.inspect}" unless localized.include?(line)
end

source_contracts = {
  "Features/ScreenTime/FirstAppLimitSetupView.swift" => [
    "Text(MoriL10n.display(value))",
    ".navigationTitle(MoriL10n.display(\"First App Limit\"))"
  ],
  "Features/ScreenTime/ScreenTimeLimitControls.swift" => [
    "Text(MoriL10n.display(\"Allow Screen Time\"))",
    "Picker(MoriL10n.display(\"App list\")"
  ],
  "Features/Today/TodaySupportViews.swift" => [
    "Text(MoriL10n.display(presentation.stateLabel))",
    "MoriL10n.display(\"Set one focus\")",
    ".accessibilityLabel(MoriL10n.display(\"Start reset\"))"
  ],
  "Features/Today/TodayWeekArchiveReferenceCard.swift" => [
    "Text(MoriL10n.display(\"Week Archive\"))",
    ".accessibilityLabel(MoriL10n.display(\"Open weeks archive\"))"
  ]
}

source_contracts.each do |path, snippets|
  source = File.read(path)
  snippets.each do |snippet|
    problems << "#{path} missing source contract #{snippet.inspect}" unless source.include?(snippet)
  end
end

if problems.empty?
  puts "zh-Hant runtime localization audit covers onboarding, Today, and first-layer Settings evidence."
else
  abort problems.join("\n")
end
RUBY
