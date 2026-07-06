import SwiftUI
import WidgetKit

struct JournalQuickStartEntryView: View {
    @Environment(\.widgetFamily) private var family
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
                .foregroundStyle(MoriWidgetColors.ink)
                .minimumScaleFactor(0.66)
                .lineLimit(2)

            HStack(spacing: 6) {
                MoriBitmapIconImage(icon: .journal, size: 11, opacity: 0.86)
                Text(entry.hasReminderEnabled ? MoriL10n.string(
                    "widget.journal.reminder_compact",
                    defaultValue: "%@ reminder",
                    arguments: [entry.reminderTimeText]
                ) : MoriL10n.display("Start writing"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(MoriWidgetColors.leafAccent)
            .widgetAccentable()
        }
    }

    private var mediumLayout: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                MoriWidgetHeader(title: "Log", icon: .journal)

                Text(MoriL10n.display("Capture one thing worth remembering from today."))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWidgetColors.ink)
                    .minimumScaleFactor(0.82)
                    .lineLimit(3)

                Text(entry.hasReminderEnabled ? MoriL10n.string(
                    "widget.journal.reminder_at",
                    defaultValue: "Reminder at %@",
                    arguments: [entry.reminderTimeText]
                ) : MoriL10n.display("No reminder set"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(MoriWidgetColors.moss)
                    .lineLimit(1)
                    .widgetAccentable()
            }

            Spacer(minLength: 0)

            VStack(alignment: .center, spacing: 8) {
                MoriBitmapIconImage(icon: .journal, size: 28, opacity: 0.90)
                    .widgetAccentable()

                Text(entry.hasReminderEnabled ? entry.reminderTimeText : MoriL10n.display("Open"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWidgetColors.mutedInk)
                    .lineLimit(1)
            }
            .frame(width: 82, height: 82)
            .background(MoriWidgetColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(MoriWidgetColors.leafAccent.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct TodaySmallWidget: View {
    let snapshot: MoriWidgetSnapshot
    let context: MoriWidgetContextSnapshot

    var body: some View {
        MoriWidgetShell {
            VStack(alignment: .leading, spacing: 10) {
                MoriWidgetHeader(title: "Today", icon: .lockShield)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.reclaimedMinutesText)
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(MoriWidgetColors.leafAccent)
                        .widgetAccentable()
                        .minimumScaleFactor(0.58)
                        .lineLimit(1)

                    Text(MoriL10n.display("reclaimed today"))
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(MoriWidgetColors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Text(MoriL10n.display("Limit one app before feeds"))
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(MoriWidgetColors.mutedInk)
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
    let snapshot: MoriWidgetSnapshot
    let context: MoriWidgetContextSnapshot

    var body: some View {
        MoriWidgetShell {
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    MoriWidgetHeader(title: "App Limit", icon: .lockShield)

                    Spacer(minLength: 0)

                    Text(context.reclaimedMinutesText)
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                        .foregroundStyle(MoriWidgetColors.leafAccent)
                        .widgetAccentable()
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)

                    Text(MoriL10n.display("reclaimed before feeds"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(MoriWidgetColors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                VStack(alignment: .leading, spacing: 10) {
                    MiniWeekArchiveGrid(snapshot: snapshot, columns: 13, rows: 8, dotSize: 5, spacing: 3)

                    HStack(spacing: 6) {
                        MoriWidgetCompactStat(title: "Bloom", value: context.bloomPercentText)
                        MoriWidgetCompactStat(title: "Seeds", value: "\(context.seedsToday)")
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        ProgressView(value: snapshot.progress)
                            .tint(MoriWidgetColors.leafAccent)
                            .background(MoriWidgetColors.ink.opacity(0.12))
                            .clipShape(Capsule())
                            .widgetAccentable()

                        Text(snapshot.archiveWeekText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(MoriWidgetColors.mutedInk)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: 126)
            }
        }
    }
}

struct WeekArchiveLargeWidget: View {
    let snapshot: MoriWidgetSnapshot
    let context: MoriWidgetContextSnapshot

    var body: some View {
        MoriWidgetShell {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        MoriWidgetHeader(title: "Week Archive", icon: .roots)

                        Text(snapshot.archiveWeekText)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(MoriWidgetColors.leafAccent)
                            .widgetAccentable()
                    }

                    Spacer()

                    Text(snapshot.archiveProgressPercentText)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(MoriWidgetColors.ink)
                }

                WeekArchivePreview(snapshot: snapshot)

                ProgressView(value: snapshot.progress)
                    .tint(MoriWidgetColors.leafAccent)
                    .background(MoriWidgetColors.ink.opacity(0.12))
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
            MoriBitmapIconImage(icon: .roots, size: 12)
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

                Text(MoriL10n.display("archive"))
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
            TodaySmallWidget(
                snapshot: MoriWidgetSnapshot(),
                context: .widgetPreview
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            PulseMediumWidget(context: .widgetPreview)
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            PulseLargeWidget(context: .widgetStalePreview)
                .previewContext(WidgetPreviewContext(family: .systemLarge))

            PulseAccessoryRectangularWidget(context: .widgetEmptyPreview)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        }
    }
}
