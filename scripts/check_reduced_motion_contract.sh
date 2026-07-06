#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ruby <<'RUBY'
audit_path = "output/accessibility-audit/reduced-motion-2026-06-26/AUDIT.md"
problems = []

unless File.file?(audit_path)
  abort "Missing reduced motion audit: #{audit_path}"
end

audit = File.read(audit_path)
required_phrases = [
  "Mori Reduced Motion Contract Audit - 2026-06-26",
  "continuous motion must stop when Reduce Motion is enabled",
  "moriReduceMotionAnimation",
  "MoriSkeleton",
  "MoriTimerProgressRing",
  "breathing orb",
  "SettleLeafPulse",
  "useReducedMotion",
  "prefers-reduced-motion: reduce",
  "does not prove every live route under an OS Reduce Motion setting"
]

required_phrases.each do |phrase|
  problems << "#{audit_path} missing phrase #{phrase.inspect}" unless audit.include?(phrase)
end

source_contracts = {
  "DesignSystem/MoriViewModifiers.swift" => [
    /func moriReduceMotionAnimation/,
    /@Environment\(\\\.accessibilityReduceMotion\)/,
    /reduceMotion \? nil : animation/
  ],
  "DesignSystem/MoriDesignTokens.swift" => [
    /repeat behavior must be opt-in and Reduce Motion guarded/
  ],
  "DesignSystem/MoriStateComponents.swift" => [
    /@Environment\(\\\.accessibilityReduceMotion\)/,
    /guard !reduceMotion/,
    /moriReduceMotionAnimation/
  ],
  "DesignSystem/MoriSanctuaryMetrics.swift" => [
    /@Environment\(\\\.accessibilityReduceMotion\)/,
    /reduceMotion \? nil : animation/
  ],
  "Features/Settle/MoriBreathingSessionVisuals.swift" => [
    /@Environment\(\\\.accessibilityReduceMotion\)/,
    /private var shouldAnimate/,
    /guard !reduceMotion/,
    /gradientRotation = \.zero/
  ],
  "Features/Settle/SettleTimerCardViews.swift" => [
    /@Environment\(\\\.accessibilityReduceMotion\)/,
    /private var outerSize/,
    /guard !reduceMotion/
  ],
  "www/src/App.tsx" => [
    /useReducedMotion/,
    /shouldReduceMotion/,
    /duration: 0/
  ],
  "www/src/index.css" => [
    /@media \(prefers-reduced-motion: reduce\)/,
    /scroll-behavior: auto/,
    /transition: none/,
    /transform: none/
  ]
}

source_contracts.each do |path, patterns|
  unless File.file?(path)
    problems << "Missing source contract file: #{path}"
    next
  end

  source = File.read(path)
  patterns.each do |pattern|
    problems << "#{path} missing reduced-motion contract #{pattern.inspect}" unless source.match?(pattern)
  end
end

swift_paths = Dir.glob("{App,DesignSystem,Features,Shared,Widgets,WatchApp,WatchWidgets}/**/*.swift").sort
swift_paths.each do |path|
  source = File.read(path)
  next unless source.include?("repeatForever")
  next if source.include?("accessibilityReduceMotion")

  source.each_line.with_index(1) do |line, index|
    next unless line.include?("repeatForever")
    problems << "#{path}:#{index + 1}: repeatForever motion must be guarded by accessibilityReduceMotion"
  end
end

css_paths = Dir.glob("www/src/**/*.css").sort
css_paths.each do |path|
  source = File.read(path)
  next unless source.match?(/\b(?:animation|transition):/)
  next if source.include?("@media (prefers-reduced-motion: reduce)")

  problems << "#{path}: CSS motion declarations must include a prefers-reduced-motion block"
end

if File.read("www/src/App.tsx").include?("<motion.") && !File.read("www/src/App.tsx").include?("useReducedMotion")
  problems << "www/src/App.tsx: Framer Motion surfaces must use useReducedMotion"
end

if File.read("DesignSystem/MoriDesignTokens.swift").include?("repeatForever")
  problems << "DesignSystem/MoriDesignTokens.swift: central MoriAnimation tokens must not define unconditional repeatForever motion"
end

if problems.empty?
  puts "Reduced Motion contract covers native repeating motion and web animation/transition surfaces."
else
  abort problems.join("\n")
end
RUBY
