#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ruby <<'RUBY'
require "open3"

audit_dir = "outputs/design-audit/widget-runtime-20260626"
audit_path = File.join(audit_dir, "AUDIT.md")
gallery_path = File.join(audit_dir, "ios-widget-gallery-today-small.jpg")
before_path = File.join(audit_dir, "ios-home-mori-today-small-widget-rendered.jpg")
early_home_path = File.join(audit_dir, "ios-home-mori-today-small-widget.jpg")
fixed_path = File.join(audit_dir, "ios-home-mori-today-small-widget-fixed.jpg")
medium_path = File.join(audit_dir, "ios-home-mori-today-medium-widget-fixed.jpg")
large_path = File.join(audit_dir, "ios-home-mori-today-large-widget-fixed.jpg")
pulse_small_path = File.join(audit_dir, "ios-home-mori-pulse-small-widget-fixed.jpg")
pulse_medium_path = File.join(audit_dir, "ios-home-mori-pulse-medium-widget-fixed.jpg")
pulse_large_path = File.join(audit_dir, "ios-home-mori-pulse-large-widget-fixed.jpg")
journal_pulse_small_path = File.join(audit_dir, "ios-home-mori-journal-pulse-small-widgets-fixed.jpg")
journal_medium_path = File.join(audit_dir, "ios-home-mori-journal-medium-widget-fixed.jpg")
lockscreen_pulse_editor_path = File.join(audit_dir, "ios-lockscreen-editor-mori-pulse-accessory-widgets.jpg")
log_path = File.join(audit_dir, "widgetkit-log-after-fix.txt")
families_log_path = File.join(audit_dir, "widgetkit-log-after-medium-large.txt")
accessory_log_path = File.join(audit_dir, "widgetkit-log-lockscreen-accessory-attempt.txt")
journal_pulse_log_path = File.join(audit_dir, "widgetkit-log-journal-pulse-widgets.txt")

widget_paper_contents = "Shared/MoriGeneratedArt.xcassets/moriWidgetPaperWash.imageset/Contents.json"
widget_botanical_contents = "Shared/MoriGeneratedArt.xcassets/moriWidgetBotanicalWash.imageset/Contents.json"
widget_paper_png = "Shared/MoriGeneratedArt.xcassets/moriWidgetPaperWash.imageset/moriWidgetPaperWash@3x.png"
widget_botanical_png = "Shared/MoriGeneratedArt.xcassets/moriWidgetBotanicalWash.imageset/moriWidgetBotanicalWash@3x.png"
widget_components = "Widgets/MoriWidgetComponents.swift"

problems = []

def require_file(path, problems)
  problems << "Missing required file: #{path}" unless File.file?(path)
end

def require_image_dimensions(path, min_width, min_height, problems)
  require_file(path, problems)
  return unless File.file?(path)

  stdout, stderr, status = Open3.capture3("sips", "-g", "pixelWidth", "-g", "pixelHeight", path)
  unless status.success?
    problems << "Could not inspect #{path}: #{stderr.strip}"
    return
  end

  width = stdout[/pixelWidth:\s*(\d+)/, 1].to_i
  height = stdout[/pixelHeight:\s*(\d+)/, 1].to_i
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

def require_exclude(path, phrases, problems)
  require_file(path, problems)
  return unless File.file?(path)

  body = File.read(path, encoding: "UTF-8", invalid: :replace, undef: :replace)
  phrases.each do |phrase|
    problems << "#{path} must not contain #{phrase.inspect}" if body.include?(phrase)
  end
end

[audit_path, gallery_path, before_path, early_home_path, fixed_path, medium_path,
 large_path, pulse_small_path, pulse_medium_path, pulse_large_path,
 journal_pulse_small_path, journal_medium_path, lockscreen_pulse_editor_path, log_path,
 families_log_path, accessory_log_path, journal_pulse_log_path,
 widget_paper_contents, widget_botanical_contents, widget_paper_png,
 widget_botanical_png, widget_components].each do |path|
  require_file(path, problems)
end

[gallery_path, before_path, early_home_path, fixed_path, medium_path, large_path,
 pulse_small_path, pulse_medium_path, pulse_large_path, journal_pulse_small_path,
 journal_medium_path, lockscreen_pulse_editor_path].each do |path|
  require_image_dimensions(path, 300, 700, problems)
end

require_image_dimensions(widget_paper_png, 1024, 1024, problems)
require_image_dimensions(widget_botanical_png, 1024, 1024, problems)

require_include(audit_path, [
  "WidgetKit Runtime Audit - 2026-06-26",
  "iPhone 15 Pro Max Mori QA",
  "35FCA784-6B78-43A1-8BE6-B35CBAE64A0B",
  "com.mettalabs.mori.widgets",
  "MoriWidgets",
  "MoriPulseWidget",
  "MoriJournalQuickStartWidget",
  "systemSmall",
  "systemMedium",
  "systemLarge",
  "accessoryCircular",
  "accessoryRectangular",
  "Families with accessoryInline placeholder archive/reload proof: Today `accessoryInline`; Pulse `accessoryInline`",
  "ios-widget-gallery-today-small.jpg",
  "ios-home-mori-today-small-widget-rendered.jpg",
  "ios-home-mori-today-small-widget-fixed.jpg",
  "ios-home-mori-today-medium-widget-fixed.jpg",
  "ios-home-mori-today-large-widget-fixed.jpg",
  "ios-home-mori-pulse-small-widget-fixed.jpg",
  "ios-home-mori-pulse-medium-widget-fixed.jpg",
  "ios-home-mori-pulse-large-widget-fixed.jpg",
  "ios-home-mori-journal-pulse-small-widgets-fixed.jpg",
  "ios-home-mori-journal-medium-widget-fixed.jpg",
  "ios-lockscreen-editor-mori-pulse-accessory-widgets.jpg",
  "Mori, Pulse",
  "Mori, Start Writing",
  "Widget, Medium",
  "Widget, Large",
  "Today",
  "0 min",
  "reclaimed today",
  "0%",
  "Week Archive",
  "Week 1,566",
  "38%",
  "Open Pulse for today's signal",
  "Bloom fallback",
  "Suggested: Quiet Mode",
  "Capture one thing worth remembering",
  "No reminder set",
  "Open",
  "Lock Screen editor screenshot proof covers Pulse accessoryCircular and accessoryRectangular placement",
  "Bloom 0%",
  "0 Seeds",
  "moriWidgetPaperWash",
  "moriWidgetBotanicalWash",
  "1024 x 1024",
  "Content state did change to ready",
  "Content load successful",
  "reload: succeeded with 1 entries",
  "Transitioning from snapshot to live content",
  "Request ended for MoriPulseWidget:accessoryInline - success.",
  "Reload com.mettalabs.mori.widgets:MoriPulseWidget:accessoryInline: succeeded with 1 entries",
  "Request ended for MoriWidgets:accessoryInline - success.",
  "Reload com.mettalabs.mori.widgets:MoriWidgets:accessoryInline: succeeded with 1 entries",
  "This proves accessoryInline descriptor, placeholder archive, and reload success for Pulse and Today only",
  "Request ended for MoriWidgets:accessoryCircular:(noIntent) - success",
  "Request ended for MoriWidgets:accessoryRectangular:(noIntent) - success",
  "Request ended for MoriPulseWidget:accessoryCircular:(noIntent) - success",
  "Request ended for MoriPulseWidget:accessoryRectangular:(noIntent) - success",
  "Request ended for MoriPulseWidget:systemSmall:(noIntent) - success",
  "Request ended for MoriPulseWidget:systemMedium:(noIntent) - success",
  "Request ended for MoriPulseWidget:systemLarge:(noIntent) - success",
  "Request ended for MoriJournalQuickStartWidget:systemSmall:(noIntent) - success",
  "Request ended for MoriJournalQuickStartWidget:systemMedium:(noIntent) - success",
  "Entry content type did change from Placeholder to Live",
  "Saved snapshot",
  "imageTooLarge",
  "ArchivingError",
  "timelineReloadFailed",
  "Home Screen screenshot proof covers Today systemSmall, systemMedium, systemLarge, Pulse systemSmall, systemMedium, systemLarge, and Journal systemSmall, systemMedium",
  "Lock Screen editor screenshot proof covers Pulse accessoryCircular and accessoryRectangular placement, not a final saved Lock Screen screenshot",
  "WidgetKit log proof covers Pulse systemSmall, systemMedium, systemLarge and Journal systemSmall, systemMedium",
  "Lock Screen accessoryCircular and accessoryRectangular have WidgetKit log proof for Today and Pulse",
  "does not prove accessoryInline rendered live; the after-fix log proves descriptor, placeholder archive, and reload success only",
  "does not prove Watch complications",
  "does not prove Widget gallery localization"
], problems)

require_include(log_path, [
  "MoriWidgets",
  "systemSmall",
  "Saved snapshot",
  "Content state did change to ready",
  "Request ended for MoriPulseWidget:accessoryInline - success.",
  "Reload com.mettalabs.mori.widgets:MoriPulseWidget:accessoryInline: succeeded with 1 entries",
  "Request ended for MoriWidgets:accessoryInline - success.",
  "Reload com.mettalabs.mori.widgets:MoriWidgets:accessoryInline: succeeded with 1 entries"
], problems)

require_include(families_log_path, [
  "MoriWidgets",
  "systemSmall",
  "systemMedium",
  "systemLarge",
  "Content state did change to ready",
  "Content load successful",
  "reload: succeeded with 1 entries",
  "Transitioning from snapshot to live content"
], problems)

require_include(accessory_log_path, [
  "MoriWidgets:accessoryCircular",
  "MoriWidgets:accessoryRectangular",
  "MoriPulseWidget:accessoryCircular",
  "MoriPulseWidget:accessoryRectangular",
  "Request ended for MoriWidgets:accessoryCircular:(noIntent) - success",
  "Request ended for MoriWidgets:accessoryRectangular:(noIntent) - success",
  "Request ended for MoriPulseWidget:accessoryCircular:(noIntent) - success",
  "Request ended for MoriPulseWidget:accessoryRectangular:(noIntent) - success",
  "reload: succeeded with 1 entries",
  "Content load successful",
  "Content state did change to ready",
  "Entry content type did change from Placeholder to Live",
  "Transitioning from snapshot to live content"
], problems)

require_include(journal_pulse_log_path, [
  "MoriPulseWidget:systemSmall",
  "MoriPulseWidget:systemMedium",
  "MoriPulseWidget:systemLarge",
  "MoriJournalQuickStartWidget:systemSmall",
  "MoriJournalQuickStartWidget:systemMedium",
  "Request ended for MoriPulseWidget:systemSmall:(noIntent) - success",
  "Request ended for MoriPulseWidget:systemMedium:(noIntent) - success",
  "Request ended for MoriPulseWidget:systemLarge:(noIntent) - success",
  "Request ended for MoriJournalQuickStartWidget:systemSmall:(noIntent) - success",
  "Request ended for MoriJournalQuickStartWidget:systemMedium:(noIntent) - success",
  "Content state did change to ready",
  "reload: succeeded with 1 entries",
  "Transitioning from snapshot to live content"
], problems)

require_exclude(log_path, [
  "imageTooLarge",
  "ArchivingError",
  "timelineReloadFailed"
], problems)

require_exclude(families_log_path, [
  "imageTooLarge",
  "ArchivingError",
  "timelineReloadFailed"
], problems)

require_exclude(accessory_log_path, [
  "imageTooLarge",
  "ArchivingError",
  "timelineReloadFailed"
], problems)

require_exclude(journal_pulse_log_path, [
  "imageTooLarge",
  "ArchivingError",
  "timelineReloadFailed"
], problems)

require_include(widget_components, [
  ".widgetPaperWash",
  ".widgetBotanicalWash",
  "GeometryReader",
  "contentPadding",
  "moriWidgetContainerBackground"
], problems)

require_include(widget_paper_contents, [
  "moriWidgetPaperWash@1x.png",
  "moriWidgetPaperWash@2x.png",
  "moriWidgetPaperWash@3x.png"
], problems)

require_include(widget_botanical_contents, [
  "moriWidgetBotanicalWash@1x.png",
  "moriWidgetBotanicalWash@2x.png",
  "moriWidgetBotanicalWash@3x.png"
], problems)

if problems.empty?
  puts "WidgetKit runtime audit includes fixed rendered Today system widgets, Journal/Pulse Home Screen widgets through inspected system families, Journal/Pulse WidgetKit log proof, Today/Pulse Lock Screen accessoryCircular/accessoryRectangular proof, and bounded accessoryInline placeholder archive/reload proof."
else
  abort problems.join("\n")
end
RUBY
