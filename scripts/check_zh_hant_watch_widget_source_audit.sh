#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

source scripts/lib/evidence_paths.sh
audit_dir="$(mori_evidence_path "output/localization-audit/zh-hant-watch-widget-source-2026-06-26" "${1:-}")"
export MORI_AUDIT_DIR="$audit_dir"

ruby <<'RUBY'
audit_dir = ENV.fetch("MORI_AUDIT_DIR")
audit_path = File.join(audit_dir, "AUDIT.md")

problems = []

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

def reject_match(path, pattern, message, problems)
  require_file(path, problems)
  return unless File.file?(path)

  File.readlines(path, encoding: "UTF-8", invalid: :replace, undef: :replace).each_with_index do |line, index|
    problems << "#{path}:#{index + 1}: #{message}: #{line.strip}" if line.match?(pattern)
  end
end

def localizable_keys(path)
  return [] unless File.file?(path)

  File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
      .scan(/^\s*"((?:\\"|[^"])*)"\s*=/)
      .flatten
      .uniq
end

def widget_configuration_literals(paths, problems)
  literals = []
  paths.each do |path|
    require_file(path, problems)
    next unless File.file?(path)

    source = File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
    literals.concat(source.scan(/\.(?:configurationDisplayName|description)\("([^"]+)"\)/).flatten)
  end
  literals.uniq
end

def require_localized_widget_configuration_literals(paths, locale_paths, problems)
  literals = widget_configuration_literals(paths, problems)
  locale_paths.each do |locale_path|
    keys = localizable_keys(locale_path)
    missing = literals - keys
    next if missing.empty?

    problems << "#{locale_path} missing WidgetKit configuration metadata keys: #{missing.join(", ")}"
  end
end

require_include(audit_path, [
  "zh-Hant Watch / Widget Source Localization Audit - 2026-06-26",
  "source-level localization coverage",
  "Watch Bell settings now routes visible headings through `MoriL10n.display`",
  "watch.bell.active_start",
  "watch.bell.message.*",
  "Widget headers, compact stats, mini metrics, and action links already route title strings through localized component helpers",
  "WidgetKit gallery metadata now has exact localization keys for every `.configurationDisplayName` and `.description` literal in `Widgets/MoriWidgets.swift` and `WatchWidgets/MoriWatchWidgets.swift`",
  "source-level localization contract, not runtime screenshot evidence"
], problems)

require_include("Localization/zh-Hant.lproj/Localizable.strings", [
  "\"Shield\" = \"Shield\";",
  "\"Fresh Pulse\" = \"今日 Pulse\";",
  "\"Limit one app before feeds\" = \"資訊流前限制一個 App\";",
  "\"reclaimed today\" = \"今天收回\";",
  "\"reclaimed before feeds\" = \"資訊流前收回\";",
  "\"archive\" = \"歸檔\";",
  "\"Quick\" = \"快速\";",
  "\"Classic\" = \"經典\";",
  "\"Breath\" = \"呼吸\";",
  "\"Break Breath\" = \"休息呼吸\";",
  "\"watch.bell.active_start\" = \"開始 %@\";",
  "\"watch.bell.active_end\" = \"結束 %@\";",
  "\"watch.bell.message.mindfulness.title\" = \"正念鈴聲\";",
  "\"watch.bell.message.mindfulness.body\" = \"暫停一下。在下一件事前，完整呼吸一次。\";",
  "\"watch.bell.message.now.title\" = \"此刻的鈴聲\";",
  "\"watch.bell.message.now.body\" = \"讓手腕提示就夠了。吸氣，呼氣。\";",
  "\"watch.bell.message.return.title\" = \"回到今天\";",
  "\"watch.bell.message.return.body\" = \"放鬆肩膀，回到這一刻。\";",
  "\"watch.bell.message.small_pause.title\" = \"小停頓\";",
  "\"watch.bell.message.small_pause.body\" = \"一次呼吸。一個清楚下一步。\";",
  "\"watch.archive.current_week\" = \"歸檔週\";",
  "\"watch.archive.accessibility\" = \"歸檔第 %d 週。%@\";",
  "\"See today's attention and week archive at a glance.\" = \"查看今天的注意力狀態和週歸檔。\";",
  "\"Open straight to your log.\" = \"直接打開你的記錄。\";",
  "\"See today's Pulse, Recovery, Bloom, Seeds, and reclaimed time.\" = \"查看今天的 Pulse、恢復、成長、種子和收回時間。\";",
  "\"Keep today and the week archive on your watch face.\" = \"在錶面保留今天狀態和週歸檔。\";",
  "\"Track Pulse, Recovery, Bloom, Seeds, and reclaimed time.\" = \"追蹤 Pulse、恢復、成長、種子和收回時間。\";"
], problems)

require_include("Localization/zh-Hans.lproj/Localizable.strings", [
  "\"Shield\" = \"屏蔽\";",
  "\"Fresh Pulse\" = \"今日 Pulse\";",
  "\"Limit one app before feeds\" = \"信息流前限制一个 App\";",
  "\"reclaimed today\" = \"今天收回\";",
  "\"reclaimed before feeds\" = \"信息流前收回\";",
  "\"archive\" = \"归档\";",
  "\"Quick\" = \"快速\";",
  "\"Classic\" = \"经典\";",
  "\"Breath\" = \"呼吸\";",
  "\"Break Breath\" = \"休息呼吸\";",
  "\"watch.bell.active_start\" = \"开始 %@\";",
  "\"watch.bell.active_end\" = \"结束 %@\";",
  "\"watch.bell.message.mindfulness.title\" = \"正念铃声\";",
  "\"watch.bell.message.mindfulness.body\" = \"暂停一下。在下一件事前，完整呼吸一次。\";",
  "\"watch.bell.message.now.title\" = \"此刻的铃声\";",
  "\"watch.bell.message.now.body\" = \"让手腕提示就够了。吸气，呼气。\";",
  "\"watch.bell.message.return.title\" = \"回到今天\";",
  "\"watch.bell.message.return.body\" = \"放松肩膀，回到这一刻。\";",
  "\"watch.bell.message.small_pause.title\" = \"小停顿\";",
  "\"watch.bell.message.small_pause.body\" = \"一次呼吸。一个清楚下一步。\";",
  "\"watch.archive.current_week\" = \"归档周\";",
  "\"watch.archive.accessibility\" = \"归档第 %d 周。%@\";",
  "\"See today's attention and week archive at a glance.\" = \"查看今天的注意力状态和周归档。\";",
  "\"Open straight to your log.\" = \"直接打开你的记录。\";",
  "\"See today's Pulse, Recovery, Bloom, Seeds, and reclaimed time.\" = \"查看今天的 Pulse、恢复、成长、种子和收回时间。\";",
  "\"Keep today and the week archive on your watch face.\" = \"在表盘保留今天状态和周归档。\";",
  "\"Track Pulse, Recovery, Bloom, Seeds, and reclaimed time.\" = \"追踪 Pulse、恢复、成长、种子和收回时间。\";"
], problems)

require_include("Localization/en.lproj/Localizable.strings", [
  "\"Shield\" = \"Shield\";",
  "\"Fresh Pulse\" = \"Fresh Pulse\";",
  "\"Limit one app before feeds\" = \"Limit one app before feeds\";",
  "\"reclaimed today\" = \"reclaimed today\";",
  "\"reclaimed before feeds\" = \"reclaimed before feeds\";",
  "\"archive\" = \"archive\";",
  "\"Quick\" = \"Quick\";",
  "\"Classic\" = \"Classic\";",
  "\"Breath\" = \"Breath\";",
  "\"Break Breath\" = \"Break Breath\";",
  "\"watch.bell.active_start\" = \"Start %@\";",
  "\"watch.bell.active_end\" = \"End %@\";",
  "\"watch.bell.message.mindfulness.title\" = \"Mindfulness Bell\";",
  "\"watch.bell.message.small_pause.body\" = \"One breath. One clear next step.\";",
  "\"watch.archive.current_week\" = \"archive week\";",
  "\"watch.archive.accessibility\" = \"Archive week %d. %@\";",
  "\"See today's attention and week archive at a glance.\" = \"See today's attention and week archive at a glance.\";",
  "\"Open straight to your log.\" = \"Open straight to your log.\";",
  "\"See today's Pulse, Recovery, Bloom, Seeds, and reclaimed time.\" = \"See today's Pulse, Recovery, Bloom, Seeds, and reclaimed time.\";",
  "\"Keep today and the week archive on your watch face.\" = \"Keep today and the week archive on your watch face.\";",
  "\"Track Pulse, Recovery, Bloom, Seeds, and reclaimed time.\" = \"Track Pulse, Recovery, Bloom, Seeds, and reclaimed time.\";"
], problems)

require_localized_widget_configuration_literals(
  [
    "Widgets/MoriWidgets.swift",
    "WatchWidgets/MoriWatchWidgets.swift"
  ],
  [
    "Localization/en.lproj/Localizable.strings",
    "Localization/zh-Hant.lproj/Localizable.strings",
    "Localization/zh-Hans.lproj/Localizable.strings"
  ],
  problems
)

require_include("WatchApp/MoriWatchBellSettingsView.swift", [
  "Text(MoriL10n.display(\"Tap a bell to breathe\"))",
  "Text(MoriL10n.display(\"Interval\"))",
  "Text(MoriL10n.display(\"Active Hours\"))",
  "\"watch.bell.active_start\"",
  "\"watch.bell.active_end\"",
  "localizedMinuteTitle(minutes)",
  "MoriL10n.string(\"status.allowed\"",
  "MoriL10n.string(\"status.denied\""
], problems)

require_include("WatchApp/MoriWatchPracticeViews.swift", [
  "\"watch.archive.current_week\"",
  "\"watch.archive.accessibility\"",
  "localizedMinuteTitle(minutes)",
  "setupSectionTitle(\"Break Breath\")",
  "MoriL10n.display(title)",
  "MoriL10n.display(subtitle)"
], problems)

require_include("WatchApp/MoriWatchSupport.swift", [
  "titleKey: \"watch.bell.message.mindfulness.title\"",
  "bodyKey: \"watch.bell.message.mindfulness.body\"",
  "titleKey: \"watch.bell.message.now.title\"",
  "titleKey: \"watch.bell.message.return.title\"",
  "titleKey: \"watch.bell.message.small_pause.title\"",
  "MoriL10n.string(message.titleKey",
  "MoriL10n.string(message.bodyKey"
], problems)

require_include("Widgets/MoriWidgetComponents.swift", [
  "Text(MoriL10n.display(title))",
  ".accessibilityLabel(MoriL10n.display(title))",
  ".accessibilityLabel(\"\\(MoriL10n.display(title)) \\(value)\")"
], problems)

require_include("Widgets/MoriPulseWidgetViews.swift", [
  "Text(MoriL10n.display(context.hasRecoverySnapshot ? \"Recovery\" : \"Bloom\"))"
], problems)

reject_match("WatchApp/MoriWatchBellSettingsView.swift", /Text\("Tap a bell to breathe"\)/, "watch bell header must be localized", problems)
reject_match("WatchApp/MoriWatchBellSettingsView.swift", /Text\("Interval"\)/, "watch bell interval label must be localized", problems)
reject_match("WatchApp/MoriWatchBellSettingsView.swift", /Text\("Active Hours"\)/, "watch bell active-hours label must be localized", problems)
reject_match("WatchApp/MoriWatchBellSettingsView.swift", /title:\s*"Start\s+\\\(/, "watch active start label must use watch.bell.active_start", problems)
reject_match("WatchApp/MoriWatchBellSettingsView.swift", /title:\s*"End\s+\\\(/, "watch active end label must use watch.bell.active_end", problems)
reject_match("WatchApp/MoriWatchBellSettingsView.swift", /title:\s*"\\\(minutes\)m"/, "watch minute options must use duration.minutes_short", problems)
reject_match("WatchApp/MoriWatchBellSettingsView.swift", /authorizationStatus = granted \? "Allowed" : "Denied"/, "watch authorization status must be localized", problems)
reject_match("WatchApp/MoriWatchPracticeViews.swift", /title:\s*"\\\(minutes\)m"/, "watch timer minute options must use duration.minutes_short", problems)
reject_match("WatchApp/MoriWatchSupport.swift", /^\s*\("Mindfulness Bell",/, "watch notification messages must use localization keys", problems)
reject_match("Widgets/MoriPulseWidgetViews.swift", /Text\(context\.hasRecoverySnapshot \? "Recovery" : "Bloom"\)/, "Pulse medium recovery/bloom status must be localized", problems)

if problems.empty?
  puts "zh-Hant Watch / Widget source audit covers localized watch controls, notification copy, widget component title paths, and WidgetKit metadata."
else
  abort problems.join("\n")
end
RUBY
