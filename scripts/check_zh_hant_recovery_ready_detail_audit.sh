#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/lib/evidence_paths.sh
audit_dir="$(mori_evidence_path "output/localization-audit/zh-hant-recovery-ready-detail-2026-06-26" "${1:-}")"
export MORI_AUDIT_DIR="$audit_dir"

ruby <<'RUBY'
audit_dir = ENV.fetch("MORI_AUDIT_DIR")
audit_path = File.join(audit_dir, "AUDIT.md")

required_screenshots = {
  "recovery-ready-card-zh-hant.jpg" => {
    label: "zh-Hant Recovery ready card",
    width: 369,
    height: 800
  },
  "recovery-detail-zh-hant.jpg" => {
    label: "zh-Hant Recovery detail",
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
  abort "Missing zh-Hant Recovery ready/detail audit directory: #{audit_dir}"
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
  "zh-Hant Recovery Ready / Detail Runtime Audit - 2026-06-26",
  "iPhone 15 Pro Max Mori QA",
  "-MoriSkipOnboardingForUITest",
  "-MoriUseMockRecoveryReadyForUITest",
  "-MoriOpenRecoveryDetailsForUITest",
  "(zh-Hant)",
  "zh_Hant_HK",
  "mori://pulse?source=deep_link",
  "recovery-ready-card-zh-hant.jpg",
  "Runtime snapshot hash: `1453e83`",
  "recovery-detail-zh-hant.jpg",
  "Runtime snapshot hash: `08gmady`",
  "deterministic ready-state sleep, training, HRV, resting-heart-rate, respiratory, and temperature signals",
  "does not prove"
], problems)

require_include("Services/MoriRecoveryModels.swift", [
  "static var uiTestReadyFixture: MoriRecoverySnapshot",
  "score: 86",
  "state: .openReady",
  "status: .ready",
  "nervousSystemLabel: MoriL10n.display(\"Calm\")",
  "bodyLoadLabel: MoriL10n.display(\"Steady\")",
  "suggestedPractice: .focusFifteen",
  "id: \"ui-test-hrv\"",
  "id: \"ui-test-resting-heart-rate\"",
  "id: \"ui-test-sleep\"",
  "id: \"ui-test-respiratory-rate\"",
  "id: \"ui-test-temperature\"",
  "missingSignals: []"
], problems)

require_include("Services/MoriRecoveryStore.swift", [
  "static let uiTestReadyFixtureArgument = \"-MoriUseMockRecoveryReadyForUITest\"",
  "applyUITestReadyFixtureIfNeeded()",
  "snapshot = .uiTestReadyFixture",
  "guard !applyUITestReadyFixtureIfNeeded() else { return }"
], problems)

require_include("Features/Pulse/ClarityPulseView.swift", [
  "ProcessInfo.processInfo.arguments.contains(\"-MoriOpenRecoveryDetailsForUITest\")",
  "openRecoveryDetailsForUITestIfNeeded()",
  "navigationPath.append(.recoverySignals)"
], problems)

require_include("Features/Recovery/MoriRecoveryPatternViews.swift", [
  "Not enough local recovery history yet. Mori needs at least 3 tagged days with next-day recovery samples before it shows a pattern."
], problems)

if File.file?("Features/Recovery/MoriRecoveryPatternViews.swift")
  source = File.read("Features/Recovery/MoriRecoveryPatternViews.swift")
  if source.include?("Patterns need at least 3 tagged days")
    problems << "Features/Recovery/MoriRecoveryPatternViews.swift still contains unlocalized one-off English pattern empty-state copy"
  end
end

require_include("Localization/zh-Hant.lproj/Localizable.strings", [
  "\"Recovery Pulse\" = \"恢復 Pulse\";",
  "\"Open / Ready\" = \"開放 / 就緒\";",
  "\"Calm\" = \"平靜\";",
  "\"Steady\" = \"穩定\";",
  "\"recovery.detail.readiness_title\" = \"準備度 %@\";",
  "\"Recovery Signals\" = \"恢復信號\";",
  "\"Baseline-based wellness signal. Not medical advice.\" = \"基於基線的健康信號。不是醫療建議。\";",
  "\"Sleep supports recovery\" = \"睡眠正在支持恢復\";",
  "\"Training Load\" = \"訓練負荷\";",
  "\"Compared with your own recent baseline.\" = \"與你自己最近的基線相比。\";",
  "\"Not enough local recovery history yet. Mori needs at least 3 tagged days with next-day recovery samples before it shows a pattern.\""
], problems)

require_include("Localization/en.lproj/Localizable.strings", [
  "\"Recovery Pulse\" = \"Recovery Pulse\";",
  "\"recovery.detail.readiness_title\" = \"Readiness %@\";",
  "\"Recovery Signals\" = \"Recovery Signals\";",
  "\"Not enough local recovery history yet. Mori needs at least 3 tagged days with next-day recovery samples before it shows a pattern.\""
], problems)

require_include("Localization/zh-Hans.lproj/Localizable.strings", [
  "\"Recovery Pulse\" = \"恢复 Pulse\";",
  "\"recovery.detail.readiness_title\" = \"准备度 %@\";",
  "\"Recovery Signals\" = \"恢复信号\";",
  "\"Not enough local recovery history yet. Mori needs at least 3 tagged days with next-day recovery samples before it shows a pattern.\""
], problems)

if problems.empty?
  puts "zh-Hant Recovery ready/detail audit includes runtime screenshots and deterministic fixture source contracts."
else
  abort problems.join("\n")
end
RUBY
