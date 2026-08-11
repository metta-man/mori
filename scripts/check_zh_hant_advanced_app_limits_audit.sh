#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/lib/evidence_paths.sh
audit_dir="$(mori_evidence_path "output/localization-audit/zh-hant-advanced-app-limits-2026-06-26" "${1:-}")"
export MORI_AUDIT_DIR="$audit_dir"

ruby <<'RUBY'
audit_dir = ENV.fetch("MORI_AUDIT_DIR")
audit_path = File.join(audit_dir, "AUDIT.md")

required_screenshots = {
  "app-limits-lock-self-pin-zh-hant.jpg" => "App Limits Lock self PIN zh-Hant runtime screenshot",
  "app-limits-lock-accountability-pin-zh-hant.jpg" => "App Limits Lock accountability PIN zh-Hant runtime screenshot",
  "app-limits-unlocked-management-zh-hant.jpg" => "App Limits unlocked management zh-Hant runtime screenshot",
  "app-limits-locked-entry-zh-hant.jpg" => "App Limits locked entry zh-Hant runtime screenshot",
  "app-limits-incorrect-pin-zh-hant.jpg" => "App Limits incorrect PIN zh-Hant runtime screenshot",
  "app-limits-cooldown-zh-hant.jpg" => "App Limits cooldown zh-Hant runtime screenshot"
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
  abort "Missing zh-Hant advanced App Limits audit directory: #{audit_dir}"
end

unless File.file?(audit_path)
  problems << "Missing zh-Hant advanced App Limits audit note: #{audit_path}"
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
    "Mori zh-Hant Advanced App Limits Runtime Localization Audit - 2026-06-26",
    "iPhone 15 Pro Max Mori QA",
    "-MoriSkipOnboardingForUITest",
    "-AppleLanguages",
    "(zh-Hant)",
    "zh_Hant_HK",
    "app-limits-lock-self-pin-zh-hant.jpg",
    "runtime snapshot hash `1wwo1mh`",
    "app-limits-lock-accountability-pin-zh-hant.jpg",
    "runtime snapshot hash `0i3b7by`",
    "app-limits-unlocked-management-zh-hant.jpg",
    "runtime snapshot hash `11vtlgu`",
    "app-limits-locked-entry-zh-hant.jpg",
    "runtime snapshot hash `0j1t2k6`",
    "app-limits-incorrect-pin-zh-hant.jpg",
    "runtime snapshot hash `1cvk9m6`",
    "app-limits-cooldown-zh-hant.jpg",
    "runtime snapshot hash `1oin2ww`",
    "自用 PIN",
    "任何人打開 Screen Time 與 App 限制前，都需要呢個 PIN。",
    "問責 PIN",
    "生成並分享 PIN",
    "App 限制已鎖定",
    "解鎖 App 限制",
    "PIN 不正確。",
    "59 秒後重試。",
    "移除 PIN 鎖",
    "does not claim full runtime coverage for Morning Gate"
  ]

  required_phrases.each do |phrase|
    problems << "#{audit_path} missing phrase #{phrase.inspect}" unless audit.include?(phrase)
  end
end

localized = File.read("Localization/zh-Hant.lproj/Localizable.strings")
required_localized_pairs = {
  "This PIN is required before anyone can open Screen Time & App Limits." => "任何人打開 Screen Time 與 App 限制前，都需要呢個 PIN。",
  "A 6-digit PIN will open in the iOS share sheet. Send it to 1-3 trusted friends and do not save it for yourself." => "一個 6 位 PIN 會在 iOS 分享頁打開。把它發給 1-3 位可信朋友，不要自己保存。",
  "Generate and Share PIN" => "生成並分享 PIN",
  "Accountability PIN" => "問責 PIN",
  "Self PIN" => "自用 PIN",
  "App Limits are locked" => "App 限制已鎖定",
  "Unlock App Limits" => "解鎖 App 限制",
  "There is no in-app forgotten-PIN reset in this version." => "此版本沒有 App 內忘記 PIN 重設。",
  "Incorrect PIN." => "PIN 不正確。",
  "screen_time.lock.retry_seconds" => "%d 秒後重試。",
  "Change to Self PIN" => "改為自用 PIN",
  "Generate Accountability PIN" => "生成問責 PIN",
  "Remove PIN Lock" => "移除 PIN 鎖",
  "Configure permission, the PIN gate, and the default app list once. Reset App Limits below can reuse this base setup." => "先設定一次權限、PIN 門檻和預設 App 清單。下面的重置 App 限制可以重用這套基礎設定。"
}

required_localized_pairs.each do |key, value|
  line = "\"#{key}\" = \"#{value}\";"
  problems << "Localization/zh-Hant.lproj/Localizable.strings missing #{line.inspect}" unless localized.include?(line)
end

source_contracts = {
  "Features/ScreenTime/ScreenTimeSettingsLockAccessViews.swift" => [
    "Text(MoriL10n.display(\"This PIN is required before anyone can open Screen Time & App Limits.\"))",
    "Text(MoriL10n.display(\"A 6-digit PIN will open in the iOS share sheet. Send it to 1-3 trusted friends and do not save it for yourself.\"))",
    "screenTimeLockLabel(\"Generate and Share PIN\", icon: .lockShield)",
    "Text(MoriL10n.display(\"App Limits are locked\"))",
    "screenTimeLockLabel(\"Unlock App Limits\", icon: .lockShield)",
    "MoriL10n.string(\"screen_time.lock.retry_seconds\"",
    "Text(MoriL10n.display(\"There is no in-app forgotten-PIN reset in this version.\"))",
    ".navigationTitle(MoriL10n.display(\"App Limits Lock\"))"
  ],
  "Features/ScreenTime/ScreenTimeSettingsPrimarySections.swift" => [
    "screenTimeSettingsLabel(\"Change to Self PIN\", icon: .lockShield)",
    "screenTimeSettingsLabel(\"Generate Accountability PIN\", icon: .lockShield)",
    "screenTimeSettingsLabel(\"Remove PIN Lock\", icon: .minus)",
    "Text(MoriL10n.display(\"Configure permission, the PIN gate, and the default app list once. Reset App Limits below can reuse this base setup.\"))"
  ]
}

source_contracts.each do |path, snippets|
  source = File.read(path)
  snippets.each do |snippet|
    problems << "#{path} missing source contract #{snippet.inspect}" unless source.include?(snippet)
  end
end

if problems.empty?
  puts "zh-Hant advanced App Limits audit covers App Limits Lock setup, locked entry, incorrect PIN, cooldown, and unlocked management evidence."
else
  abort problems.join("\n")
end
RUBY
