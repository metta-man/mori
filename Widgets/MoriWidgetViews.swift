import SwiftUI
import WidgetKit

struct JournalQuickStartEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    @AppStorage(MoriLocalePreference.defaultsKey, store: MoriSharedDefaults.shared) private var localePreferenceRaw = MoriLocalePreference.system.rawValue

    let entry: JournalQuickStartEntry

    var body: some View {
        MoriWidgetShell {
            switch family {
            case .systemMedium:
                mediumLayout
            default:
                smallLayout
            }
        }
        .environment(\.locale, localePreference.locale)
        .accessibilityLabel(MoriL10n.string("widget.journal.accessibility", defaultValue: "Start writing one line"))
    }

    private var localePreference: MoriLocalePreference {
        MoriLocalePreference(rawValue: localePreferenceRaw) ?? .system
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            MoriWidgetHeader(title: "Log", icon: .journal)

            Spacer(minLength: 0)

            Text(MoriL10n.display("One line worth keeping"))
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .foregroundStyle(MoriWidgetPalette.ink(for: renderingMode))
                .minimumScaleFactor(0.66)
                .lineLimit(2)

            HStack(spacing: 6) {
                MoriWidgetIconImage(icon: .journal, size: 11, opacity: 0.86)
                Text(entry.hasReminderEnabled ? MoriL10n.string(
                    "widget.journal.reminder_compact",
                    defaultValue: "%@ reminder",
                    arguments: [entry.reminderTimeText]
                ) : MoriL10n.display("Start writing"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(MoriWidgetPalette.accent(for: renderingMode))
            .widgetAccentable()
        }
    }

    private var mediumLayout: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                MoriWidgetHeader(title: "Log", icon: .journal)

                Text(MoriL10n.display("Capture one thing worth remembering from today."))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWidgetPalette.ink(for: renderingMode))
                    .minimumScaleFactor(0.82)
                    .lineLimit(3)

                Text(entry.hasReminderEnabled ? MoriL10n.string(
                    "widget.journal.reminder_at",
                    defaultValue: "Reminder at %@",
                    arguments: [entry.reminderTimeText]
                ) : MoriL10n.display("No reminder set"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(MoriWidgetPalette.moss(for: renderingMode))
                    .lineLimit(1)
                    .widgetAccentable()
            }

            Spacer(minLength: 0)

            VStack(alignment: .center, spacing: 8) {
                MoriWidgetIconImage(icon: .journal, size: 28, opacity: 0.90)
                    .widgetAccentable()

                Text(entry.hasReminderEnabled ? entry.reminderTimeText : MoriL10n.display("Open"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWidgetPalette.mutedInk(for: renderingMode))
                    .lineLimit(1)
            }
            .frame(width: 82, height: 82)
            .background(MoriWidgetCardWash(cornerRadius: 14))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(MoriWidgetPalette.outline(for: renderingMode), lineWidth: 1)
            )
        }
    }
}

struct TodaySmallWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let snapshot: MoriWidgetSnapshot
    let context: MoriWidgetContextSnapshot

    var body: some View {
        MoriWidgetShell {
            VStack(alignment: .leading, spacing: 10) {
                MoriWidgetHeader(title: "Today", icon: .appLimit)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.reclaimedMinutesText)
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(MoriWidgetPalette.accent(for: renderingMode))
                        .widgetAccentable()
                        .minimumScaleFactor(0.58)
                        .lineLimit(1)

                    Text(MoriL10n.display("reclaimed today"))
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(MoriWidgetPalette.ink(for: renderingMode))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Text(MoriL10n.display("Limit one app before feeds"))
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(MoriWidgetPalette.mutedInk(for: renderingMode))
                    .lineLimit(1)

                MoriWidgetMiniMetric(
                    title: "Bloom",
                    value: context.bloomPercentText,
                    icon: .leaf
                )
            }
        }
    }
}

struct TodayMediumWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let snapshot: MoriWidgetSnapshot
    let context: MoriWidgetContextSnapshot

    var body: some View {
        MoriWidgetShell {
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    MoriWidgetHeader(title: "App Limit", icon: .appLimit)

                    Spacer(minLength: 0)

                    Text(context.reclaimedMinutesText)
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                        .foregroundStyle(MoriWidgetPalette.accent(for: renderingMode))
                        .widgetAccentable()
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)

                    Text(MoriL10n.display("reclaimed before feeds"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(MoriWidgetPalette.ink(for: renderingMode))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                VStack(alignment: .leading, spacing: 7) {
                    MiniWeekArchiveGrid(snapshot: snapshot, columns: 13, rows: 8, dotSize: 4.5, spacing: 2.5)

                    HStack(spacing: 6) {
                        MoriWidgetCompactStat(title: "Bloom", value: context.bloomPercentText)
                        MoriWidgetCompactStat(title: "Seeds", value: "\(context.seedsToday)")
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        ProgressView(value: snapshot.progress)
                            .tint(MoriWidgetPalette.accent(for: renderingMode))
                            .background(MoriWidgetPalette.track(for: renderingMode))
                            .clipShape(Capsule())
                            .widgetAccentable()

                        Text(snapshot.archiveWeekText)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(MoriWidgetPalette.mutedInk(for: renderingMode))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: 126)
            }
        }
    }
}

struct WeekArchiveLargeWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let snapshot: MoriWidgetSnapshot
    let context: MoriWidgetContextSnapshot

    var body: some View {
        MoriWidgetShell {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        MoriWidgetHeader(title: "Life Grid", icon: .roots)

                        Text(snapshot.archiveWeekText)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(MoriWidgetPalette.accent(for: renderingMode))
                            .widgetAccentable()
                    }

                    Spacer()

                    Text(snapshot.archiveProgressPercentText)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(MoriWidgetPalette.ink(for: renderingMode))
                }

                WeekArchivePreview(snapshot: snapshot)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)

                ProgressView(value: snapshot.progress)
                    .tint(MoriWidgetPalette.accent(for: renderingMode))
                    .background(MoriWidgetPalette.track(for: renderingMode))
                    .clipShape(Capsule())
                    .widgetAccentable()

                HStack(spacing: 8) {
                    MoriWidgetCompactStat(title: "Bloom", value: context.bloomPercentText)
                    MoriWidgetCompactStat(title: "Seeds", value: "\(context.seedsToday)")
                    MoriWidgetCompactStat(title: "Reclaimed", value: context.reclaimedMinutesText)
                }
            }
        }
    }
}

struct AccessoryCircularWidget: View {
    let snapshot: MoriWidgetSnapshot

    var body: some View {
        Gauge(value: snapshot.progress) {
            MoriWidgetIconImage(icon: .roots, size: 12)
        } currentValueLabel: {
            Text(snapshot.archiveWeekCompactText)
                .minimumScaleFactor(0.55)
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}

struct AccessoryRectangularWidget: View {
    let snapshot: MoriWidgetSnapshot
    let context: MoriWidgetContextSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(MoriL10n.display("Today"))
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(snapshot.archiveWeekCompactText)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                Text(MoriL10n.display("Life Grid"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            ProgressView(value: snapshot.progress)

            Text(MoriL10n.string(
                "widget.inline.bloom",
                defaultValue: "Bloom %@",
                arguments: [context.bloomPercentText]
            ))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

struct MoriWidgets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Group {
                TodaySmallWidget(snapshot: previewSnapshot, context: .widgetPreview)
                    .moriWidgetPreview(family: .systemSmall, mode: .fullColor, name: "Today · Small · Full Color")
                TodaySmallWidget(snapshot: previewSnapshot, context: .widgetPreview)
                    .moriWidgetPreview(family: .systemSmall, mode: .accented, name: "Today · Small · Accented")
                TodayMediumWidget(snapshot: previewSnapshot, context: .widgetPreview)
                    .moriWidgetPreview(family: .systemMedium, mode: .fullColor, name: "Today · Medium · Full Color")
                TodayMediumWidget(snapshot: previewSnapshot, context: .widgetPreview)
                    .moriWidgetPreview(family: .systemMedium, mode: .accented, name: "Today · Medium · Accented")
                WeekArchiveLargeWidget(snapshot: previewSnapshot, context: .widgetPreview)
                    .moriWidgetPreview(family: .systemLarge, mode: .fullColor, name: "Today · Large · Full Color")
                WeekArchiveLargeWidget(snapshot: previewSnapshot, context: .widgetPreview)
                    .moriWidgetPreview(family: .systemLarge, mode: .accented, name: "Today · Large · Accented")
            }

            Group {
                PulseSmallWidget(context: .widgetPreview)
                    .moriWidgetPreview(family: .systemSmall, mode: .fullColor, name: "Recovery · Small · Full Color")
                PulseSmallWidget(context: .widgetPreview)
                    .moriWidgetPreview(family: .systemSmall, mode: .accented, name: "Recovery · Small · Accented")
                PulseMediumWidget(context: .widgetPreview)
                    .moriWidgetPreview(family: .systemMedium, mode: .fullColor, name: "Recovery · Medium · Full Color")
                PulseMediumWidget(context: .widgetPreview)
                    .moriWidgetPreview(family: .systemMedium, mode: .accented, name: "Recovery · Medium · Accented")
                PulseLargeWidget(context: .widgetPreview)
                    .moriWidgetPreview(family: .systemLarge, mode: .fullColor, name: "Recovery · Large · Full Color")
                PulseLargeWidget(context: .widgetStalePreview)
                    .moriWidgetPreview(family: .systemLarge, mode: .accented, name: "Recovery · Large · Accented")
            }

            Group {
                JournalQuickStartEntryView(entry: previewJournalEntry)
                    .moriWidgetPreview(family: .systemSmall, mode: .fullColor, name: "Log · Small · Full Color")
                JournalQuickStartEntryView(entry: previewJournalEntry)
                    .moriWidgetPreview(family: .systemSmall, mode: .accented, name: "Log · Small · Accented")
                JournalQuickStartEntryView(entry: previewJournalEntry)
                    .moriWidgetPreview(family: .systemMedium, mode: .fullColor, name: "Log · Medium · Full Color")
                JournalQuickStartEntryView(entry: previewJournalEntry)
                    .moriWidgetPreview(family: .systemMedium, mode: .accented, name: "Log · Medium · Accented")
                PulseAccessoryCircularWidget(context: .widgetPreview)
                    .moriWidgetPreview(family: .accessoryCircular, mode: .vibrant, name: "Recovery · Circular · Vibrant")
                PulseAccessoryRectangularWidget(context: .widgetPreview)
                    .moriWidgetPreview(family: .accessoryRectangular, mode: .vibrant, name: "Recovery · Rectangular · Vibrant")
            }
        }
    }

    private static let previewNow = Date(timeIntervalSince1970: 1_777_507_200)

    private static let previewSnapshot = MoriWidgetSnapshot(
        archiveStartDate: Date(timeIntervalSince1970: 830_908_800),
        archiveSpanYears: 80,
        now: previewNow
    )

    private static let previewJournalEntry = JournalQuickStartEntry(
        date: previewNow,
        hasReminderEnabled: true,
        reminderTimeText: "9:00 PM"
    )
}

private extension View {
    func moriWidgetPreview(
        family: WidgetFamily,
        mode: WidgetRenderingMode,
        name: String
    ) -> some View {
        moriWidgetContainerBackground()
            .environment(\.widgetRenderingMode, mode)
            .previewContext(WidgetPreviewContext(family: family))
            .previewDisplayName(name)
    }
}
