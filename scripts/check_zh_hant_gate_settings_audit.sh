#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/lib/evidence_paths.sh
audit_dir="$(mori_evidence_path "output/localization-audit/zh-hant-gate-settings-2026-06-26" "${1:-}")"
export MORI_AUDIT_DIR="$audit_dir"

ruby <<'RUBY'
audit_dir = ENV.fetch("MORI_AUDIT_DIR")
audit_path = File.join(audit_dir, "AUDIT.md")

required_screenshots = {
  "morning-before-feed-settings-zh-hant.jpg" => "Morning Gate and Before Feed settings zh-Hant runtime screenshot",
  "before-feed-shortcut-guide-zh-hant.jpg" => "Before Feed Shortcut guide zh-Hant runtime screenshot"
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
  abort "Missing zh-Hant gate settings audit directory: #{audit_dir}"
end

unless File.file?(audit_path)
  problems << "Missing zh-Hant gate settings audit note: #{audit_path}"
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
    "Mori zh-Hant Gate Settings Runtime Localization Audit - 2026-06-26",
    "iPhone 15 Pro Max Mori QA",
    "-MoriSkipOnboardingForUITest",
    "-AppleLanguages",
    "(zh-Hant)",
    "zh_Hant_HK",
    "mori://app-limit-settings?source=deep_link",
    "morning-before-feed-settings-zh-hant.jpg",
    "runtime snapshot hash `1dnuugk`",
    "before-feed-shortcut-guide-zh-hant.jpg",
    "runtime snapshot hash `0gz9o9s`",
    "晨間門檻",
    "晨間視窗 30 分鐘",
    "打開資訊流 App -> 點準備重置 -> 打開 Mori -> 完成 5 分鐘。",
    "捷徑自動化",
    "可選自動化",
    "螢幕時間門檻更順暢",
    "打開捷徑",
    "does not claim full runtime coverage for Watch, Widget, recovery, Pulse"
  ]

  required_phrases.each do |phrase|
    problems << "#{audit_path} missing phrase #{phrase.inspect}" unless audit.include?(phrase)
  end
end

localized = File.read("Localization/zh-Hant.lproj/Localizable.strings")
required_localized_pairs = {
  "Morning Gate" => "晨間門檻",
  "screen_time.morning.window_duration" => "晨間視窗 %@",
  "Starts at your chosen time each day. Completing Morning Reset opens selected apps for that morning window." => "每天在你選擇的時間開始。完成晨間重設後，所選 App 會在晨間視窗內開啟。",
  "Ready. Open a selected feed app to trigger the reset." => "已就緒。打開已選資訊流 App 就會觸發重置。",
  "Allow Screen Time above before this can work." => "先允許 Screen Time，呢個功能先可以運作。",
  "Feed apps selected" => "已選資訊流 App",
  "screen_time.before_feed.handoff_detail" => "打開資訊流 App -> 點準備重置 -> 打開 Mori -> 完成 %@。",
  "Protect feed app launches" => "保護資訊流 App 啟動",
  "Shortcuts" => "捷徑",
  "Optional automation" => "可選自動化",
  "Use this only if you want Shortcuts to pop Mori open before selected feeds." => "僅當你想讓捷徑在打開所選資訊流前彈出 Mori 時使用。",
  "The Screen Time gate opens selected feed apps after the reset. A Shortcut automation can open Mori, but iOS does not tell Mori which app triggered it, so you may need to switch back manually." => "螢幕時間門檻會在重設後開啟所選資訊流 App。捷徑自動化可以打開 Mori，但 iOS 不會告訴 Mori 是哪個 App 觸發的，所以你可能需要手動切回去。",
  "Apple requires each personal automation to be created in Shortcuts. Mori can open Shortcuts, but cannot preselect apps, create the automation, or return to the app that launched it." => "Apple 要求每個個人自動化都在「捷徑」中建立。Mori 可以打開捷徑，但無法預選 App、建立自動化，或返回觸發它的 App。",
  "Screen Time prepared this reset from the blocked feed app." => "Screen Time 已從被封鎖的資訊流 App 準備好這次重置。",
  "Selected morning apps stay limited until this reset completes or the window ends." => "已選晨間 App 會保持受限，直到重置完成或晨間視窗結束。",
  "attention_reset.open_window.before_feed.default" => "完成後會開啟已選資訊流 App %@。"
}

required_localized_pairs.each do |key, value|
  line = "\"#{key}\" = \"#{value}\";"
  problems << "Localization/zh-Hant.lproj/Localizable.strings missing #{line.inspect}" unless localized.include?(line)
end

source_contracts = {
  "Features/ScreenTime/ScreenTimeGateSettingsSections.swift" => [
    "Text(MoriL10n.display(\"Activation flow\"))",
    "MoriL10n.string(\n                        \"screen_time.before_feed.handoff_detail\"",
    "screenTimeLabel(\"Protect feed app launches\", icon: .timer)",
    "screenTimeLabel(\"Morning Gate\", icon: .leaf)",
    "screenTimeLabel(\"Morning apps\", icon: .timer)",
    "MoriL10n.string(\n                    \"screen_time.morning.window_duration\""
  ],
  "Features/ScreenTime/ScreenTimeSettingsSupportViews.swift" => [
    "eyebrow: MoriL10n.display(\"Shortcuts\")",
    "title: MoriL10n.display(\"Optional automation\")",
    "subtitle: MoriL10n.display(\"Use this only if you want Shortcuts to pop Mori open before selected feeds.\")",
    "Text(MoriL10n.display(\"The Screen Time gate opens selected feed apps after the reset. A Shortcut automation can open Mori, but iOS does not tell Mori which app triggered it, so you may need to switch back manually.\"))",
    "screenTimeSupportLabel(\"Use the same apps you selected as Feed apps in Mori.\", icon: .timer)",
    "Text(MoriL10n.display(\"Apple requires each personal automation to be created in Shortcuts. Mori can open Shortcuts, but cannot preselect apps, create the automation, or return to the app that launched it.\"))",
    ".navigationTitle(MoriL10n.display(\"Auto-open\"))",
    "Button(MoriL10n.display(\"Done\"))"
  ],
  "Features/ScreenTime/MoriAttentionResetSheets.swift" => [
    "return MoriL10n.display(\"Screen Time prepared this reset from the blocked feed app.\")",
    "return MoriL10n.display(\"Selected morning apps stay limited until this reset completes or the window ends.\")",
    "MoriL10n.string(\n                    \"attention_reset.open_window.before_feed.default\"",
    "Button(MoriL10n.display(\"Done\"))"
  ],
  "Features/ScreenTime/ScreenTimeSettingsPickerSupport.swift" => [
    "Button(MoriL10n.display(\"Cancel\"))",
    "Button(MoriL10n.display(\"Done\"))"
  ]
}

source_contracts.each do |path, snippets|
  source = File.read(path)
  snippets.each do |snippet|
    problems << "#{path} missing source contract #{snippet.inspect}" unless source.include?(snippet)
  end
end

if problems.empty?
  puts "zh-Hant gate settings audit covers Morning Gate, Before Feed settings, and Shortcut guide evidence."
else
  abort problems.join("\n")
end
RUBY
