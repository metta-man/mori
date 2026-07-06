#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ruby <<'RUBY'
audit_dir = "output/screenshot-audit/main-surfaces-refresh-2026-06-26"
audit_path = File.join(audit_dir, "AUDIT.md")

required_screenshots = {
  "log-refresh.jpg" => "Log refresh",
  "week-archive-refresh.jpg" => "Week Archive refresh",
  "pulse-refresh.jpg" => "Pulse refresh"
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
  abort "Missing refresh screenshot audit directory: #{audit_dir}"
end

unless File.file?(audit_path)
  problems << "Missing refresh screenshot audit note: #{audit_path}"
end

required_screenshots.each do |filename, label|
  path = File.join(audit_dir, filename)
  if !File.file?(path)
    problems << "Missing #{label} screenshot: #{path}"
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
    "Native app build: `Mori` scheme on `iPhone 15 Pro Max Mori QA`.",
    "Launch argument: `-MoriSkipOnboardingForUITest`.",
    "mori://log?source=deep_link",
    "mori://week?source=deep_link",
    "mori://pulse?source=deep_link",
    "log-refresh.jpg",
    "week-archive-refresh.jpg",
    "pulse-refresh.jpg",
    "All captures are 369 x 800 runtime screenshots",
    "Latest XcodeBuildMCP build/run succeeded with 0 warnings and 0 errors.",
    "Pulse permission state now shows a readable `Connect Health` CTA",
    "No inspected refresh screenshot shows a logo, wordmark, app icon, funnel, hourglass, seed badge, circular emblem, or repeated brand-mark card wallpaper",
    "does not prove full accessibility compliance"
  ]

  required_phrases.each do |phrase|
    problems << "#{audit_path} missing phrase #{phrase.inspect}" unless audit.include?(phrase)
  end
end

if problems.empty?
  puts "Main-surface refresh screenshot audit includes Log, Week Archive, and Pulse runtime evidence."
else
  abort problems.join("\n")
end
RUBY
