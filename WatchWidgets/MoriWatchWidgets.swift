import SwiftUI
import WidgetKit

struct MoriWatchWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: MoriWidgetSnapshot
    let context: MoriWidgetContextSnapshot
}

struct MoriWatchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoriWatchWidgetEntry {
        MoriWatchWidgetEntry(
            date: Date(),
            snapshot: MoriWidgetSnapshot(
                archiveStartDate: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
                archiveSpanYears: 80
            ),
            context: .widgetPreview
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MoriWatchWidgetEntry) -> Void) {
        completion(MoriWatchWidgetEntry(
            date: Date(),
            snapshot: MoriWidgetSnapshot(),
            context: MoriWidgetContextSnapshot.load()
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoriWatchWidgetEntry>) -> Void) {
        let now = Date()
        let entry = MoriWatchWidgetEntry(
            date: now,
            snapshot: MoriWidgetSnapshot(now: now),
            context: MoriWidgetContextSnapshot.load()
        )
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct MoriWatchWidgetsEntryView: View {
    @Environment(\.widgetFamily) private var family
    @AppStorage(MoriLocalePreference.defaultsKey, store: MoriSharedDefaults.shared) private var localePreferenceRaw = MoriLocalePreference.system.rawValue

    let entry: MoriWatchWidgetEntry

    var body: some View {
        content
            .environment(\.locale, localePreference.locale)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:
            MoriWatchCircularComplication(snapshot: entry.snapshot)
        case .accessoryCorner:
            MoriWatchCornerComplication(snapshot: entry.snapshot)
        case .accessoryRectangular:
            MoriWatchRectangularComplication(snapshot: entry.snapshot, context: entry.context)
        case .accessoryInline:
            Text(entry.snapshot.archiveWeekText)
        default:
            MoriWatchCircularComplication(snapshot: entry.snapshot)
        }
    }

    private var localePreference: MoriLocalePreference {
        MoriLocalePreference(rawValue: localePreferenceRaw) ?? .system
    }
}

struct MoriWatchWidgets: Widget {
    let kind = "MoriWatchWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoriWatchWidgetProvider()) { entry in
            MoriWatchWidgetsEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
                .widgetURL(URL(string: "mori://week/archive"))
        }
        .configurationDisplayName("Today")
        .description("Keep today and the week archive on your watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct MoriWatchPulseEntry: TimelineEntry {
    let date: Date
    let context: MoriWidgetContextSnapshot
}

struct MoriWatchPulseProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoriWatchPulseEntry {
        MoriWatchPulseEntry(date: Date(), context: .widgetPreview)
    }

    func getSnapshot(in context: Context, completion: @escaping (MoriWatchPulseEntry) -> Void) {
        completion(MoriWatchPulseEntry(date: Date(), context: MoriWidgetContextSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoriWatchPulseEntry>) -> Void) {
        let now = Date()
        let entry = MoriWatchPulseEntry(date: now, context: MoriWidgetContextSnapshot.load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct MoriWatchPulseEntryView: View {
    @Environment(\.widgetFamily) private var family
    @AppStorage(MoriLocalePreference.defaultsKey, store: MoriSharedDefaults.shared) private var localePreferenceRaw = MoriLocalePreference.system.rawValue

    let entry: MoriWatchPulseEntry

    var body: some View {
        content
            .environment(\.locale, localePreference.locale)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:
            MoriWatchPulseCircularComplication(context: entry.context)
        case .accessoryCorner:
            MoriWatchPulseCornerComplication(context: entry.context)
        case .accessoryRectangular:
            MoriWatchPulseRectangularComplication(context: entry.context)
        case .accessoryInline:
            Text(MoriL10n.string(
                "watch_widget.inline.recovery",
                defaultValue: "Recovery %@",
                arguments: [entry.context.recoveryScoreText]
            ))
        default:
            MoriWatchPulseCircularComplication(context: entry.context)
        }
    }

    private var localePreference: MoriLocalePreference {
        MoriLocalePreference(rawValue: localePreferenceRaw) ?? .system
    }
}

struct MoriWatchPulseWidget: Widget {
    let kind = "MoriWatchPulseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoriWatchPulseProvider()) { entry in
            MoriWatchPulseEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
                .widgetURL(URL(string: "mori://recovery"))
        }
        .configurationDisplayName("Recovery")
        .description("See the recovery signal shared privately from your iPhone.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

@main
struct MoriWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        MoriWatchWidgets()
        MoriWatchPulseWidget()
    }
}

private struct MoriWatchCircularComplication: View {
    let snapshot: MoriWidgetSnapshot

    var body: some View {
        Gauge(value: snapshot.progress) {
            MoriBitmapIconImage(icon: .roots, size: 12)
        } currentValueLabel: {
            Text(compactValue)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel(MoriL10n.string(
            "widget.archive.accessibility_week",
            defaultValue: "Week Archive, current archive week %d",
            arguments: [snapshot.archiveWeekNumber]
        ))
    }

    private var compactValue: String {
        snapshot.archiveWeekCompactText.lowercased()
    }
}

private struct MoriWatchCornerComplication: View {
    let snapshot: MoriWidgetSnapshot

    var body: some View {
        Text(compactValue)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .widgetCurvesContent()
            .widgetLabel {
                ProgressView(value: snapshot.progress)
            }
            .accessibilityLabel(MoriL10n.string(
                "widget.archive.accessibility_week",
                defaultValue: "Week Archive, current archive week %d",
                arguments: [snapshot.archiveWeekNumber]
            ))
    }

    private var compactValue: String {
        snapshot.archiveWeekCompactText.lowercased()
    }
}

private struct MoriWatchRectangularComplication: View {
    let snapshot: MoriWidgetSnapshot
    let context: MoriWidgetContextSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Gauge(value: snapshot.progress) {
                EmptyView()
            } currentValueLabel: {
                MoriBitmapIconImage(icon: .roots, size: 10)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(MoriL10n.display("Today"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(snapshot.archiveWeekCompactText.lowercased())
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)

                    Text(MoriL10n.display("archive"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(MoriL10n.string(
                    "widget.inline.bloom",
                    defaultValue: "Bloom %@",
                    arguments: [context.bloomPercentText]
                ))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MoriL10n.string(
            "widget.archive.accessibility_week",
            defaultValue: "Week Archive, current archive week %d",
            arguments: [snapshot.archiveWeekNumber]
        ))
    }
}

private struct MoriWatchPulseCircularComplication: View {
    let context: MoriWidgetContextSnapshot

    var body: some View {
        Gauge(value: context.hasRecoverySnapshot ? context.recoveryProgress : 0) {
            MoriBitmapIconImage(icon: .heart, size: 12)
        } currentValueLabel: {
            Text(context.hasRecoverySnapshot ? context.recoveryScoreText : "--")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel(MoriL10n.string(
            "recovery.widget.score",
            defaultValue: "Recovery %@",
            arguments: [context.hasRecoverySnapshot ? context.recoveryScoreText : "unavailable"]
        ))
    }
}

private struct MoriWatchPulseCornerComplication: View {
    let context: MoriWidgetContextSnapshot

    var body: some View {
        Text(context.hasRecoverySnapshot ? context.recoveryScoreText : "--")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .widgetCurvesContent()
            .widgetLabel {
                ProgressView(value: context.hasRecoverySnapshot ? context.recoveryProgress : 0)
            }
            .accessibilityLabel(MoriL10n.string(
                "recovery.widget.score",
                defaultValue: "Recovery %@",
                arguments: [context.hasRecoverySnapshot ? context.recoveryScoreText : "unavailable"]
            ))
    }
}

private struct MoriWatchPulseRectangularComplication: View {
    let context: MoriWidgetContextSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Gauge(value: context.hasRecoverySnapshot ? context.recoveryProgress : 0) {
                EmptyView()
            } currentValueLabel: {
                MoriBitmapIconImage(icon: .heart, size: 10)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(context.hasRecoverySnapshot ? context.displayRecoveryState : MoriL10n.display("Recovery"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(context.hasRecoverySnapshot ? context.displayRecoveryDetail : MoriL10n.display("No signal yet"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                HStack(spacing: 5) {
                    Text(context.hasRecoverySnapshot ? MoriL10n.string(
                        "recovery.widget.score",
                        defaultValue: "Recovery %@",
                        arguments: [context.recoveryScoreText]
                    ) : MoriL10n.display("Open Mori on iPhone"))
                }
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MoriL10n.string(
            "recovery.widget.accessibility",
            defaultValue: "Recovery. %@.",
            arguments: [context.hasRecoverySnapshot ? context.displayRecoveryDetail : MoriL10n.display("No signal yet")]
        ))
    }
}

struct MoriWatchWidgets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MoriWatchRectangularComplication(
                snapshot: MoriWidgetSnapshot(),
                context: .widgetPreview
            )
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

            MoriWatchPulseRectangularComplication(context: .widgetPreview)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

            MoriWatchPulseRectangularComplication(context: .widgetStalePreview)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        }
    }
}
