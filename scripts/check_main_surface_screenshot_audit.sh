#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ruby <<'RUBY'
audit_dir = "output/screenshot-audit/main-surfaces-2026-06-25"
audit_path = File.join(audit_dir, "AUDIT.md")

required_screenshots = {
  "00-onboarding.jpg" => {
    label: "Onboarding",
    width: 369,
    height: 800
  },
  "01-today.jpg" => {
    label: "Today",
    width: 369,
    height: 800
  },
  "02-reset.jpg" => {
    label: "Reset",
    width: 369,
    height: 800
  },
  "03-log.jpg" => {
    label: "Log",
    width: 369,
    height: 800
  },
  "04-week-archive.jpg" => {
    label: "Week Archive deep link",
    width: 369,
    height: 800
  },
  "05-pulse.jpg" => {
    label: "Pulse deep link",
    width: 369,
    height: 800
  },
  "06-week-archive-direct-tap.jpg" => {
    label: "Week Archive direct tap",
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

unless Dir.exist?(audit_dir)
  abort "Missing screenshot audit directory: #{audit_dir}"
end

unless File.file?(audit_path)
  problems << "Missing screenshot audit note: #{audit_path}"
end

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

if File.file?(audit_path)
  audit = File.read(audit_path)
  required_phrases = [
    "Native app build: `Mori` scheme on `iPhone 15 Pro Max Mori QA`.",
    "Main-surface launch argument: `-MoriSkipOnboardingForUITest`.",
    "Onboarding launch argument: `-MoriForceOnboardingForUITest`.",
    "00-onboarding.jpg",
    "01-today.jpg",
    "02-reset.jpg",
    "03-log.jpg",
    "04-week-archive.jpg",
    "05-pulse.jpg",
    "06-week-archive-direct-tap.jpg",
    "369 x 800",
    "App Limit-first onboarding surface",
    "The onboarding surface was explicitly rechecked",
    "no funnel, hourglass, logo, wordmark, or repeated app-icon watermark",
    "Today Week Archive card",
    "full sanctuary card surface inside the `Button` label",
    "build/run succeeded with 0 warnings and 0 errors",
    "Tap `Open weeks archive`",
    "navigated to the `Weeks` detail surface",
    "No logo, wordmark, or repeated app-icon watermark"
  ]

  required_phrases.each do |phrase|
    problems << "#{audit_path} missing phrase #{phrase.inspect}" unless audit.include?(phrase)
  end
end

if problems.empty?
  puts "Main-surface screenshot audit includes required captures and direct-tap evidence."
else
  abort problems.join("\n")
end
RUBY
