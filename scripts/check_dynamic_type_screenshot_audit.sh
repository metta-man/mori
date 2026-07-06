#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ruby <<'RUBY'
audit_dir = "output/screenshot-audit/dynamic-type-2026-06-26"
audit_path = File.join(audit_dir, "AUDIT.md")

required_screenshots = {
  "onboarding-accessibility-large.jpg" => {
    label: "Forced onboarding accessibility-large",
    width: 1290,
    height: 2796
  },
  "today-accessibility-large.jpg" => {
    label: "Today accessibility-large",
    width: 1290,
    height: 2796
  },
  "settings-accessibility-large.jpg" => {
    label: "Settings accessibility-large",
    width: 1290,
    height: 2796
  }
}

typography_sources = [
  "DesignSystem/MoriDesignTokens.swift",
  "DesignSystem/MoriThemeTokens.swift",
  "DesignSystem/MoriSanctuaryHeaders.swift",
  "DesignSystem/MoriActionComponents.swift",
  "Features/Onboarding/MoriOnboardingSupport.swift"
]

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
  abort "Missing Dynamic Type screenshot audit directory: #{audit_dir}"
end

unless File.file?(audit_path)
  problems << "Missing Dynamic Type screenshot audit note: #{audit_path}"
end

required_screenshots.each do |filename, expected|
  path = File.join(audit_dir, filename)
  if !File.file?(path)
    problems << "Missing #{expected[:label]} screenshot: #{path}"
    next
  end

  bytes = File.binread(path)
  problems << "#{path} is too small to be a useful full-resolution screenshot (#{bytes.bytesize} bytes)" if bytes.bytesize < 100_000
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

if File.file?(audit_path)
  audit = File.read(audit_path)
  required_phrases = [
    "Mori Dynamic Type Screenshot Audit - 2026-06-26",
    "iPhone 15 Pro Max Mori QA simulator",
    "Content size: `accessibility-large`",
    "onboarding-accessibility-large.jpg",
    "-MoriForceOnboardingForUITest",
    "quiet no-logo watercolor paper",
    "today-accessibility-large.jpg",
    "-MoriSkipOnboardingForUITest",
    "settings-accessibility-large.jpg",
    "normal scrollable content",
    "MoriTypography now uses SwiftUI Dynamic Type text styles",
    "does not claim full WCAG compliance"
  ]

  required_phrases.each do |phrase|
    problems << "#{audit_path} missing phrase #{phrase.inspect}" unless audit.include?(phrase)
  end
end

typography_sources.each do |path|
  if !File.file?(path)
    problems << "Missing typography source: #{path}"
    next
  end

  source = File.read(path)
  if source.match?(/(?:Font\.system|\.font\(\.system)\(size:/)
    problems << "#{path} must not use fixed point-size Font.system(size:) in central Dynamic Type surfaces"
  end
end

token_source = File.read("DesignSystem/MoriDesignTokens.swift")
theme_source = File.read("DesignSystem/MoriThemeTokens.swift")

[
  /static let display = Font\.system\(\.largeTitle/,
  /static let title1 = Font\.system\(\.title/,
  /static let title2 = Font\.system\(\.title2/,
  /static let body = Font\.system\(\.body/,
  /static let callout = Font\.system\(\.callout/,
  /static let caption = Font\.system\(\.caption/,
  /static let micro = Font\.system\(\.caption2/,
  /static let largeMetric = Font\.system\(\.largeTitle/
].each do |pattern|
  problems << "MoriTypography missing Dynamic Type token pattern #{pattern.inspect}" unless token_source.match?(pattern)
end

[
  /static let sanctuaryDisplay = Font\.system\(\.largeTitle/,
  /static let sanctuaryRootTitle = Font\.system\(\.title/,
  /static let sanctuaryTitle = Font\.system\(\.title/,
  /static let sanctuarySection = Font\.system\(\.title3/,
  /static let sanctuaryMetric = Font\.system\(\.largeTitle/,
  /static let sanctuaryBody = Font\.system\(\.body/,
  /static let sanctuaryCaption = Font\.system\(\.caption/
].each do |pattern|
  problems << "Sanctuary typography missing Dynamic Type token pattern #{pattern.inspect}" unless theme_source.match?(pattern)
end

if problems.empty?
  puts "Dynamic Type screenshot audit includes onboarding, Today, and Settings evidence at accessibility-large."
else
  abort problems.join("\n")
end
RUBY
