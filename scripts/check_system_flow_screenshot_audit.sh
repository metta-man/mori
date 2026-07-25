#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/lib/evidence_paths.sh
audit_dir="$(mori_evidence_path "output/screenshot-audit/system-flows-2026-06-26" "${1:-}")"
export MORI_AUDIT_DIR="$audit_dir"

ruby <<'RUBY'
audit_dir = ENV.fetch("MORI_AUDIT_DIR")
audit_path = File.join(audit_dir, "AUDIT.md")

required_screenshots = {
  "settings.jpg" => "Settings",
  "first-app-limit-setup.jpg" => "First App Limit setup",
  "advanced-app-limits-lock.jpg" => "Advanced App Limits lock",
  "advanced-app-limits-incorrect-pin.jpg" => "Advanced App Limits incorrect PIN",
  "advanced-app-limits-cooldown.jpg" => "Advanced App Limits cooldown",
  "advanced-app-limits-unlocked.jpg" => "Advanced App Limits unlocked",
  "advanced-app-limits-lock-removed.jpg" => "Advanced App Limits lock removed"
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
  abort "Missing system-flow screenshot audit directory: #{audit_dir}"
end

unless File.file?(audit_path)
  problems << "Missing system-flow screenshot audit note: #{audit_path}"
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
    "mori://settings?source=deep_link",
    "mori://app-limit?source=deep_link",
    "mori://app-limit-settings?source=deep_link",
    "settings.jpg",
    "first-app-limit-setup.jpg",
    "advanced-app-limits-lock.jpg",
    "advanced-app-limits-incorrect-pin.jpg",
    "advanced-app-limits-cooldown.jpg",
    "advanced-app-limits-unlocked.jpg",
    "advanced-app-limits-lock-removed.jpg",
    "All captures are 369 x 800 runtime screenshots",
    "exposed a tappable `Allow Screen Time` button",
    "matched `App Limits are locked`, `Self PIN`, and `Accountability PIN`",
    "proving the new `mori://app-limit-settings` route opens the locked management surface",
    "Incorrect PIN runtime sequence entered `000000`, tapped `Unlock App Limits`, and matched `Incorrect PIN.`",
    "Cooldown runtime sequence reached the fifth failed attempt, matched `Try again in 59s.`, and removed `Unlock App Limits` from tappable targets",
    "PIN verification runtime sequence created a Self PIN",
    "matched `Unlock App Limits`, entered the PIN, tapped `Unlock App Limits`",
    "landed on the `App Limits` management surface with `Control Status`, `Self PIN`, `Default App List`, and `Remove PIN Lock` visible",
    "PIN removal runtime sequence entered the current PIN",
    "`PIN` is `Not configured` and the only PIN setup action is `Lock App Limits`",
    "Latest XcodeBuildMCP build/run succeeded with 0 warnings and 0 errors.",
    "no logo, wordmark, app-icon, funnel, hourglass, or old Life Grid positioning",
    "Advanced App Limits keeps the utilitarian PIN setup in native paper form styling",
    "Advanced App Limits management keeps the same paper form styling after PIN verification",
    "After PIN removal, the setup section no longer shows stale change/remove actions",
    "The direct setup bottom action no longer uses a floating sticky overlay",
    "does not prove the Family Activity picker"
  ]

  required_phrases.each do |phrase|
    problems << "#{audit_path} missing phrase #{phrase.inspect}" unless audit.include?(phrase)
  end
end

if problems.empty?
  puts "System-flow screenshot audit includes Settings, First App Limit, Advanced App Limits lock, incorrect PIN, cooldown, PIN unlock, and PIN removal runtime evidence."
else
  abort problems.join("\n")
end
RUBY
