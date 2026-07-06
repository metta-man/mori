#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ruby <<'RUBY'
audit_dir = "output/localization-audit/zh-hant-pulse-recovery-2026-06-26"
audit_path = File.join(audit_dir, "AUDIT.md")

required_screenshots = {
  "pulse-recovery-root-zh-hant.jpg" => {
    label: "zh-Hant Pulse / Recovery root",
    width: 369,
    height: 800
  },
  "pulse-topic-cards-zh-hant.jpg" => {
    label: "zh-Hant Pulse topic cards",
    width: 369,
    height: 800
  }
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

unless Dir.exist?(audit_dir)
  abort "Missing zh-Hant Pulse / Recovery audit directory: #{audit_dir}"
end

require_file(audit_path, problems)

required_screenshots.each do |filename, expected|
  path = File.join(audit_dir, filename)
  if !File.file?(path)
    problems << "Missing #{expected[:label]} screenshot: #{path}"
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
    if width != expected[:width] || height != expected[:height]
      problems << "#{path} expected #{expected[:width]}x#{expected[:height]}, got #{width}x#{height}"
    end
  end
end

require_include(audit_path, [
  "zh-Hant Pulse / Recovery Runtime Audit - 2026-06-26",
  "iPhone 15 Pro Max Mori QA",
  "-MoriSkipOnboardingForUITest",
  "(zh-Hant)",
  "zh_Hant_HK",
  "mori://pulse?source=deep_link",
  "pulse-recovery-root-zh-hant.jpg",
  "Runtime snapshot hash: `0qhra11`",
  "pulse-topic-cards-zh-hant.jpg",
  "Runtime snapshot hash: `1b8o3kc`",
  "Recovery permission-state card",
  "MoriDailyPulse stores `localeIdentifier`",
  "localizedForCurrentLocaleIfNeeded",
  "non-English generated-card fallback behavior",
  "does not prove"
], problems)

require_include("Localization/zh-Hant.lproj/Localizable.strings", [
  "\"Choose a reset action\" = \"選擇一次重置\";",
  "\"Choose reset action\" = \"選擇重置\";",
  "\"HealthKit readiness signals before the attention scan.\" = \"注意力掃描之前的 HealthKit 準備度信號。\";",
  "\"Connect Apple Health to read recovery signals.\" = \"連接 Apple 健康以讀取恢復信號。\";",
  "\"When on, coarse recovery labels are sent to the Pulse proxy. Raw HealthKit samples stay local.\" = \"開啟後，粗略恢復標籤會傳送到 Pulse 代理。原始 HealthKit 樣本仍保留在本地。\";",
  "\"Topic labels, aggregate clarity stats, selected Pulse cards, and your follow-up questions are sent to the configured proxy. Recovery labels are included only when you opt in. Raw HealthKit, log, habit, and screen-time details stay local whenever possible.\"",
  "\"pulse.source.fallback\" = \"來源 %d\";",
  "\"Mark useful\" = \"標記有用\";",
  "\"Let it pass\" = \"讓它經過\";",
  "\"Name the trap\" = \"說出陷阱\";",
  "\"Choose practice\" = \"選擇重置\";"
], problems)

require_include("Localization/en.lproj/Localizable.strings", [
  "\"Choose a reset action\" = \"Choose a reset\";",
  "\"Choose reset action\" = \"Choose reset\";",
  "\"HealthKit readiness signals before the attention scan.\"",
  "\"Connect Apple Health to read recovery signals.\"",
  "\"When on, coarse recovery labels are sent to the Pulse proxy. Raw HealthKit samples stay local.\"",
  "\"pulse.source.fallback\" = \"Source %d\";",
  "\"Mark useful\"",
  "\"Let it pass\"",
  "\"Name the trap\"",
  "\"Choose practice\""
], problems)

require_include("Localization/zh-Hans.lproj/Localizable.strings", [
  "\"Choose a reset action\" = \"选择一次重置\";",
  "\"Choose reset action\" = \"选择重置\";",
  "\"HealthKit readiness signals before the attention scan.\"",
  "\"Connect Apple Health to read recovery signals.\"",
  "\"When on, coarse recovery labels are sent to the Pulse proxy. Raw HealthKit samples stay local.\"",
  "\"pulse.source.fallback\" = \"来源 %d\";",
  "\"Mark useful\"",
  "\"Let it pass\"",
  "\"Name the trap\"",
  "\"Choose practice\""
], problems)

require_include("Models/MoriPulseModels.swift", [
  "var localeIdentifier: String?",
  "var isUsableForCurrentLocale: Bool",
  "func taggedForCurrentLocale() -> MoriDailyPulse",
  "func localizedForCurrentLocaleIfNeeded() -> MoriDailyPulse",
  "private static func localizedCardIfNeeded",
  "private static func needsLocalizedFallback",
  "try container.encodeIfPresent(localeIdentifier, forKey: .localeIdentifier)",
  "try container.decodeIfPresent(String.self, forKey: .localeIdentifier)",
  "fallback.id = card.id"
], problems)

require_include("Services/MoriPulseService.swift", [
  ".localizedForCurrentLocaleIfNeeded()"
], problems)

require_include("Features/Pulse/ClarityPulseView.swift", [
  "MoriL10n.display(\"Pulse\")",
  "MoriL10n.display(\"HealthKit readiness signals before the attention scan.\")",
  "cachedPulse.isUsableForCurrentLocale"
], problems)

require_include("Features/Pulse/ClarityPulseSupportViews.swift", [
  "MoriL10n.display(\"Back\")",
  "MoriL10n.display(\"Live Pulse unavailable\")",
  "MoriL10n.display(\"Topic labels, aggregate clarity stats, selected Pulse cards, and your follow-up questions are sent to the configured proxy. Recovery labels are included only when you opt in. Raw HealthKit, log, habit, and screen-time details stay local whenever possible.\")"
], problems)

require_include("Features/Pulse/PulseComponents.swift", [
  "MoriL10n.display(\"Choose a reset action\")",
  "MoriL10n.display(\"Breathe, Settle, Log, Focus, Quiet Mode, or walk offline.\")",
  "MoriL10n.display(card.actionLabel"
], problems)

require_include("Features/Pulse/PulseCardDetailRows.swift", [
  "MoriL10n.string(\"pulse.source.fallback\"",
  "MoriL10n.display(\"Retry\")"
], problems)

require_include("Features/Pulse/PulseCardDetailSheet.swift", [
  "MoriL10n.display(\"Choose reset action\")",
  "MoriL10n.display(\"No follow-ups yet.\")",
  "MoriL10n.display(\"Listening for signal...\")",
  "MoriL10n.display(\"Ask a follow-up\")",
  "MoriL10n.display(\"Close\")"
], problems)

require_include("Features/Pulse/PulseTopicPickerCard.swift", [
  "MoriL10n.display(\"Queued\")",
  "MoriL10n.display(\"Add custom topic\")"
], problems)

require_include("Features/Recovery/MoriRecoveryPulseCardSections.swift", [
  "MoriL10n.display(\"Connect Apple Health\")"
], problems)

if problems.empty?
  puts "zh-Hant Pulse / Recovery audit includes runtime screenshots, localization keys, and Pulse locale fallback source contracts."
else
  abort problems.join("\n")
end
RUBY
