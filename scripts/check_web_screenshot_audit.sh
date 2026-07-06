#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ruby <<'RUBY'
audit_dir = "output/screenshot-audit/web-2026-06-26"
audit_path = File.join(audit_dir, "AUDIT.md")

required_screenshots = {
  "desktop.png" => {
    label: "desktop web",
    width: 1280,
    height: 720
  },
  "mobile.png" => {
    label: "mobile web",
    width: 390,
    height: 844
  },
  "desktop-full-page.png" => {
    label: "desktop full-page web",
    width: 1280,
    height: 2117
  },
  "mobile-full-page.png" => {
    label: "mobile full-page web",
    width: 390,
    height: 3242
  }
}

problems = []

unless Dir.exist?(audit_dir)
  abort "Missing web screenshot audit directory: #{audit_dir}"
end

unless File.file?(audit_path)
  problems << "Missing web screenshot audit note: #{audit_path}"
end

required_screenshots.each do |filename, expected|
  path = File.join(audit_dir, filename)
  if !File.file?(path)
    problems << "Missing #{expected[:label]} screenshot: #{path}"
    next
  end

  bytes = File.binread(path)
  problems << "#{path} is too small to be a useful screenshot (#{bytes.bytesize} bytes)" if bytes.bytesize < 100_000
  problems << "#{path} is not a PNG screenshot" unless bytes.start_with?("\x89PNG\r\n\x1A\n".b)

  if bytes.bytesize >= 24 && bytes.start_with?("\x89PNG\r\n\x1A\n".b)
    width = bytes.byteslice(16, 4).unpack1("N")
    height = bytes.byteslice(20, 4).unpack1("N")
    if width != expected[:width] || height != expected[:height]
      problems << "#{path} expected #{expected[:width]}x#{expected[:height]}, got #{width}x#{height}"
    end
  end
end

if File.file?(audit_path)
  audit = File.read(audit_path)
  required_phrases = [
    "Web build passed with `pnpm --dir www build`.",
    "Vite dev server rendered `Mori | First App Limit`",
    "0 console errors",
    "no `logo`, `wordmark`, `mori-paper-linework`, `hourglass`, `funnel`, `time_seed`, `forest_rings`, `LifeGrid`, or `Memento mori` hits",
    "onboarding-paper.png",
    "app-limit-paper.png",
    "practice-paper.png",
    "today-paper.png",
    "desktop.png",
    "mobile.png",
    "desktop-full-page.png",
    "mobile-full-page.png",
    "Card backgrounds do not repeat the logo, wordmark, app icon, hourglass, or funnel.",
    "Default card material now uses plain watercolor paper",
    "same watercolor-paper botanical theme",
    "Browser screenshot API timed out"
  ]

  required_phrases.each do |phrase|
    problems << "#{audit_path} missing phrase #{phrase.inspect}" unless audit.include?(phrase)
  end
end

if problems.empty?
  puts "Web screenshot audit includes viewport and full-page no-logo botanical evidence."
else
  abort problems.join("\n")
end
RUBY
