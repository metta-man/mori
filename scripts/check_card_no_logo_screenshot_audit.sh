#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/lib/evidence_paths.sh
audit_dir="$(mori_evidence_path "output/screenshot-audit/card-no-logo-2026-06-26" "${1:-}")"
export MORI_AUDIT_DIR="$audit_dir"

ruby <<'RUBY'
audit_dir = ENV.fetch("MORI_AUDIT_DIR")
audit_path = File.join(audit_dir, "AUDIT.md")

required_screenshots = {
  "onboarding-no-logo-card.jpg" => {
    label: "Forced onboarding no-logo card",
    width: 369,
    height: 800
  },
  "today-no-logo-card.jpg" => {
    label: "Today no-logo card",
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
  abort "Missing no-logo card screenshot audit directory: #{audit_dir}"
end

unless File.file?(audit_path)
  problems << "Missing no-logo card screenshot audit note: #{audit_path}"
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
    "Mori No-Logo Card Surface Audit - 2026-06-26",
    "iPhone 15 Pro Max Mori QA simulator",
    "onboarding-no-logo-card.jpg",
    "-MoriForceOnboardingForUITest",
    "The onboarding screen keeps botanical watercolor at the screen layer",
    "plain watercolor paper material",
    "today-no-logo-card.jpg",
    "The Today card stack uses paper surfaces",
    "No logo, wordmark, app icon, funnel, hourglass, or repeated brand-mark wallpaper is visible",
    "does not claim that every app route has fresh screenshot evidence"
  ]

  required_phrases.each do |phrase|
    problems << "#{audit_path} missing phrase #{phrase.inspect}" unless audit.include?(phrase)
  end
end

active_swift_roots = %w[
  App
  DesignSystem
  Features
  Shared
  Widgets
  WatchApp
  WatchWidgets
  ScreenTimeMonitor
  ShieldAction
  ShieldConfiguration
]

blocked_brand_surface_reference = /
  mori-paper-linework|
  paper-linework|
  wordmark|
  logo|
  Logo|
  AppIcon|
  MORI_TIME_SEED|
  mori-time-seed|
  time_seed|
  hourglass|
  funnel
/x

active_swift_roots.flat_map { |root| Dir.glob(File.join(root, "**/*.swift")) }.sort.each do |path|
  File.readlines(path, encoding: "UTF-8", invalid: :replace, undef: :replace).each_with_index do |line, index|
    next unless line.match?(blocked_brand_surface_reference)

    problems << "#{path}:#{index + 1}: active app source must not reference logo, wordmark, app-icon, funnel, hourglass, or paper-linework art for in-app card/surface backgrounds"
  end
end

Dir.glob("www/src/**/*.{css,ts,tsx}").sort.each do |path|
  File.readlines(path, encoding: "UTF-8", invalid: :replace, undef: :replace).each_with_index do |line, index|
    next unless line.match?(/background|background-image|url\(|img|src/i)
    next unless line.match?(blocked_brand_surface_reference)

    problems << "#{path}:#{index + 1}: web UI must not use logo, wordmark, app-icon, funnel, hourglass, or paper-linework art as card/surface imagery"
  end
end

if problems.empty?
  puts "No-logo card screenshot audit includes forced onboarding and Today evidence, plus active source guardrails."
else
  abort problems.join("\n")
end
RUBY
