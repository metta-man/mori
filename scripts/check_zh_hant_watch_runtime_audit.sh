#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ruby <<'RUBY'
audit_dir = "outputs/design-audit/watch-runtime-zh-hant-20260626"
audit_path = File.join(audit_dir, "AUDIT.md")
before_path = File.join(audit_dir, "watch-app-root.png")
fixed_path = File.join(audit_dir, "watch-app-root-fixed.png")

problems = []

def require_file(path, problems)
  problems << "Missing required file: #{path}" unless File.file?(path)
end

def require_png_dimensions(path, min_width, min_height, problems)
  require_file(path, problems)
  return unless File.file?(path)

  data = File.binread(path, 24)
  unless data.start_with?("\x89PNG\r\n\x1A\n".b)
    problems << "#{path} is not a PNG file"
    return
  end

  width, height = data[16, 8].unpack("NN")
  if width < min_width || height < min_height
    problems << "#{path} is too small: #{width}x#{height}, expected at least #{min_width}x#{min_height}"
  end

  if File.size(path) < 10_000
    problems << "#{path} is unexpectedly small: #{File.size(path)} bytes"
  end
end

def require_include(path, phrases, problems)
  require_file(path, problems)
  return unless File.file?(path)

  body = File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
  phrases.each do |phrase|
    problems << "#{path} missing phrase #{phrase.inspect}" unless body.include?(phrase)
  end
end

require_png_dimensions(before_path, 300, 300, problems)
require_png_dimensions(fixed_path, 300, 300, problems)

require_include(audit_path, [
  "zh-Hant Watch Runtime Localization Audit - 2026-06-26",
  "Apple Watch Ultra 3",
  "A6324D42-E261-4D66-8B0E-C8B24079FE7E",
  "iPhone 17",
  "41625A0F-0972-481A-9544-B84D9E70D01D",
  "com.mettalabs.mori.watch",
  "-AppleLanguages '(zh-Hant)' -AppleLocale zh_Hant_HK",
  "watch-app-root.png",
  "watch-app-root-fixed.png",
  "archive week",
  "歸檔週",
  "重置",
  "鈴聲已暫停",
  "422 x 514",
  "Watch app root only",
  "not prove Widget rendered families",
  "notification delivery UI",
  "full VoiceOver traversal"
], problems)

if problems.empty?
  puts "zh-Hant Watch runtime audit includes before/fixed screenshots and bounded runtime claims."
else
  abort problems.join("\n")
end
RUBY
