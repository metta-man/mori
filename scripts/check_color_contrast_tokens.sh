#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ruby <<'RUBY'
TokenColor = Struct.new(:r, :g, :b) do
  def to_s
    format("#%02X%02X%02X", r, g, b)
  end
end

def hex_color(hex)
  value = hex.delete("#")
  raise "Invalid hex color #{hex.inspect}" unless value.match?(/\A[0-9a-fA-F]{6}\z/)

  TokenColor.new(
    value[0, 2].to_i(16),
    value[2, 2].to_i(16),
    value[4, 2].to_i(16)
  )
end

def rgba_over(hex, alpha, background_hex)
  foreground = hex_color(hex)
  background = hex_color(background_hex)

  TokenColor.new(
    (foreground.r * alpha + background.r * (1.0 - alpha)).round,
    (foreground.g * alpha + background.g * (1.0 - alpha)).round,
    (foreground.b * alpha + background.b * (1.0 - alpha)).round
  )
end

def linear_channel(channel)
  value = channel / 255.0
  value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4
end

def relative_luminance(color)
  0.2126 * linear_channel(color.r) +
    0.7152 * linear_channel(color.g) +
    0.0722 * linear_channel(color.b)
end

def contrast_ratio(foreground, background)
  lighter, darker = [relative_luminance(foreground), relative_luminance(background)].sort.reverse
  (lighter + 0.05) / (darker + 0.05)
end

def assert_source_contains(path, pattern, problems)
  source = File.read(path)
  problems << "#{path} missing #{pattern.inspect}" unless source.match?(pattern)
end

problems = []

assert_source_contains(
  "DesignSystem/MoriDesignTokens.swift",
  /static let sanctuaryPaper = Color\(hex: "#FBF7EF"\)/,
  problems
)
assert_source_contains(
  "DesignSystem/MoriDesignTokens.swift",
  /static let sanctuarySurface = Color\(hex: "#FFFDF8"\)/,
  problems
)
assert_source_contains(
  "DesignSystem/MoriDesignTokens.swift",
  /static let sanctuaryInk = Color\(hex: "#14392F"\)/,
  problems
)
assert_source_contains(
  "DesignSystem/MoriDesignTokens.swift",
  /static let sanctuaryInkSoft = Color\(hex: "#31584B"\)/,
  problems
)
assert_source_contains(
  "DesignSystem/MoriDesignTokens.swift",
  /static let sanctuaryMuted = Color\(hex: "#5F6D64"\)/,
  problems
)
assert_source_contains(
  "www/src/styles/variables.css",
  /--text-secondary: rgba\(59, 52, 47, 0\.72\);/,
  problems
)
assert_source_contains(
  "www/src/styles/variables.css",
  /--text-muted: rgba\(59, 52, 47, 0\.70\);/,
  problems
)

checks = [
  {
    name: "native primary ink on watercolor paper",
    foreground: hex_color("#14392F"),
    background: hex_color("#FBF7EF"),
    minimum: 4.5
  },
  {
    name: "native primary ink on card paper",
    foreground: hex_color("#14392F"),
    background: hex_color("#FFFDF8"),
    minimum: 4.5
  },
  {
    name: "native soft ink on watercolor paper",
    foreground: hex_color("#31584B"),
    background: hex_color("#FBF7EF"),
    minimum: 4.5
  },
  {
    name: "native muted ink on watercolor paper",
    foreground: hex_color("#5F6D64"),
    background: hex_color("#FBF7EF"),
    minimum: 4.5
  },
  {
    name: "native muted ink on card paper",
    foreground: hex_color("#5F6D64"),
    background: hex_color("#FFFDF8"),
    minimum: 4.5
  },
  {
    name: "native primary button text",
    foreground: hex_color("#FFFFFF"),
    background: hex_color("#31584B"),
    minimum: 4.5
  },
  {
    name: "native dark mode primary text",
    foreground: hex_color("#E8E4DB"),
    background: hex_color("#1A1F2E"),
    minimum: 4.5
  },
  {
    name: "native dark mode secondary text",
    foreground: hex_color("#9CA3AF"),
    background: hex_color("#1A1F2E"),
    minimum: 4.5
  },
  {
    name: "web primary text on paper",
    foreground: hex_color("#243833"),
    background: hex_color("#F7F1E7"),
    minimum: 4.5
  },
  {
    name: "web secondary text on paper",
    foreground: rgba_over("#3B342F", 0.72, "#F7F1E7"),
    background: hex_color("#F7F1E7"),
    minimum: 4.5
  },
  {
    name: "web muted text on paper",
    foreground: rgba_over("#3B342F", 0.70, "#F7F1E7"),
    background: hex_color("#F7F1E7"),
    minimum: 4.5
  },
  {
    name: "web leaf metric text on paper",
    foreground: hex_color("#5F745C"),
    background: hex_color("#F7F1E7"),
    minimum: 4.5
  },
  {
    name: "web inactive tab text on paper",
    foreground: rgba_over("#243833", 0.70, "#F7F1E7"),
    background: hex_color("#F7F1E7"),
    minimum: 4.5
  },
  {
    name: "web primary button text",
    foreground: hex_color("#FFFAF0"),
    background: hex_color("#243833"),
    minimum: 4.5
  },
  {
    name: "web root accent large text",
    foreground: hex_color("#9F5F45"),
    background: hex_color("#F7F1E7"),
    minimum: 3.0
  },
  {
    name: "web seed accent large text",
    foreground: hex_color("#A87B31"),
    background: hex_color("#F7F1E7"),
    minimum: 3.0
  }
]

report = []
checks.each do |check|
  ratio = contrast_ratio(check[:foreground], check[:background])
  report << format(
    "%s: %.2f:1 >= %.1f:1",
    check[:name],
    ratio,
    check[:minimum]
  )
  if ratio + 0.0001 < check[:minimum]
    problems << format(
      "%s contrast %.2f:1 is below %.1f:1 (%s on %s)",
      check[:name],
      ratio,
      check[:minimum],
      check[:foreground],
      check[:background]
    )
  end
end

low_alpha_text = []
Dir.glob("www/src/**/*.{css,tsx}").sort.each do |path|
  File.readlines(path, encoding: "UTF-8", invalid: :replace, undef: :replace).each_with_index do |line, index|
    stripped = line.strip
    next unless stripped.start_with?("color:")

    if stripped.match?(/rgba\(59,\s*52,\s*47,\s*0\.(?:[0-6][0-9])\)/)
      low_alpha_text << "#{path}:#{index + 1}: #{stripped}"
    end

    if stripped.match?(/rgba\(36,\s*56,\s*51,\s*0\.(?:[0-5][0-9]|6[0-7])\)/)
      low_alpha_text << "#{path}:#{index + 1}: #{stripped}"
    end
  end
end

unless low_alpha_text.empty?
  problems << "Web CSS text colors use low alpha values that fall below the contrast gate:\n#{low_alpha_text.join("\n")}"
end

if problems.empty?
  puts "Color contrast token checks passed."
  puts report.join("\n")
else
  abort problems.join("\n")
end
RUBY
