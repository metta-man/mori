import SwiftUI
import WidgetKit
#if canImport(ActivityKit) && os(iOS)
import ActivityKit
#endif

struct MoriWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: MoriWidgetSnapshot
    let context: MoriWidgetContextSnapshot
}

struct MoriWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoriWidgetEntry {
        MoriWidgetEntry(
            date: Date(),
            snapshot: MoriWidgetSnapshot(
                archiveStartDate: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
                archiveSpanYears: 80
            ),
            context: .widgetPreview
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MoriWidgetEntry) -> Void) {
        completion(MoriWidgetEntry(
            date: Date(),
            snapshot: MoriWidgetSnapshot(),
            context: MoriWidgetContextSnapshot.load()
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoriWidgetEntry>) -> Void) {
        let now = Date()
        let entry = MoriWidgetEntry(
            date: now,
            snapshot: MoriWidgetSnapshot(now: now),
            context: MoriWidgetContextSnapshot.load()
        )
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct MoriWidgetsEntryView: View {
    @Environment(\.widgetFamily) private var family
    @AppStorage(MoriLocalePreference.defaultsKey, store: MoriSharedDefaults.shared) private var localePreferenceRaw = MoriLocalePreference.system.rawValue

    let entry: MoriWidgetEntry

    var body: some View {
        content
            .environment(\.locale, localePreference.locale)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            TodaySmallWidget(snapshot: entry.snapshot, context: entry.context)
        case .systemMedium:
            TodayMediumWidget(snapshot: entry.snapshot, context: entry.context)
        case .systemLarge:
            WeekArchiveLargeWidget(snapshot: entry.snapshot, context: entry.context)
        default:
            TodaySmallWidget(snapshot: entry.snapshot, context: entry.context)
        }
    }

    private var localePreference: MoriLocalePreference {
        MoriLocalePreference(rawValue: localePreferenceRaw) ?? .system
    }
}

struct MoriWidgets: Widget {
    let kind = "MoriWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoriWidgetProvider()) { entry in
            MoriWidgetsEntryView(entry: entry)
                .moriWidgetContainerBackground()
                .widgetURL(URL(string: "mori://week/archive"))
        }
        .configurationDisplayName("Today")
        .description("See today's attention and week archive at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
    }
}

struct MoriJournalQuickStartWidget: Widget {
    let kind = "MoriJournalQuickStartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JournalQuickStartProvider()) { entry in
            JournalQuickStartEntryView(entry: entry)
                .moriWidgetContainerBackground()
                .widgetURL(URL(string: "mori://log"))
        }
        .configurationDisplayName("Start Writing")
        .description("Open straight to your log.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
    }
}

struct MoriPulseWidgetEntry: TimelineEntry {
    let date: Date
    let context: MoriWidgetContextSnapshot
}

struct MoriPulseWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoriPulseWidgetEntry {
        MoriPulseWidgetEntry(date: Date(), context: .widgetPreview)
    }

    func getSnapshot(in context: Context, completion: @escaping (MoriPulseWidgetEntry) -> Void) {
        completion(MoriPulseWidgetEntry(date: Date(), context: MoriWidgetContextSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoriPulseWidgetEntry>) -> Void) {
        let now = Date()
        let entry = MoriPulseWidgetEntry(date: now, context: MoriWidgetContextSnapshot.load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct MoriPulseWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    @AppStorage(MoriLocalePreference.defaultsKey, store: MoriSharedDefaults.shared) private var localePreferenceRaw = MoriLocalePreference.system.rawValue

    let entry: MoriPulseWidgetEntry

    var body: some View {
        content
            .environment(\.locale, localePreference.locale)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            PulseSmallWidget(context: entry.context)
        case .systemMedium:
            PulseMediumWidget(context: entry.context)
        case .systemLarge:
            PulseLargeWidget(context: entry.context)
        default:
            PulseSmallWidget(context: entry.context)
        }
    }

    private var localePreference: MoriLocalePreference {
        MoriLocalePreference(rawValue: localePreferenceRaw) ?? .system
    }
}

struct MoriPulseWidget: Widget {
    let kind = "MoriPulseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoriPulseWidgetProvider()) { entry in
            MoriPulseWidgetEntryView(entry: entry)
                .moriWidgetContainerBackground()
                .widgetURL(URL(string: "mori://pulse/recovery"))
        }
        .configurationDisplayName("Pulse")
        .description("See today's Pulse, Recovery, Bloom, Seeds, and reclaimed time.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
    }
}

#if canImport(ActivityKit) && os(iOS)
@available(iOS 16.1, *)
struct MoriBeforeFeedWindowLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MoriBeforeFeedWindowAttributes.self) { context in
            MoriBeforeFeedWindowLiveActivityView(context: context)
                .activityBackgroundTint(MoriWidgetColors.paper)
                .activitySystemActionForegroundColor(MoriWidgetColors.leafAccent)
                .widgetURL(URL(string: "mori://before-feed?source=live-activity"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    MoriBeforeFeedLiveActivityStatus()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    MoriBeforeFeedLiveActivityCountdown(
                        endsAt: context.state.endsAt,
                        alignment: .trailing,
                        titleFont: .system(size: 18, weight: .semibold, design: .rounded),
                        labelFont: .caption2
                    )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    MoriBeforeFeedLiveActivityProgress(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "pause.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MoriWidgetColors.leafAccent)
            } compactTrailing: {
                Text(context.state.endsAt, style: .timer)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(MoriWidgetColors.paper)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: 42)
            } minimal: {
                Image(systemName: "pause.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(MoriWidgetColors.leafAccent)
            }
            .widgetURL(URL(string: "mori://before-feed?source=live-activity"))
            .keylineTint(MoriWidgetColors.leafAccent)
        }
    }
}

@available(iOS 16.1, *)
private struct MoriBeforeFeedWindowLiveActivityView: View {
    let context: ActivityViewContext<MoriBeforeFeedWindowAttributes>

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MoriWidgetColors.surfaceRaised)
                Image(systemName: "pause.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(MoriWidgetColors.leafAccent)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 6) {
                Text("Open window")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MoriWidgetColors.ink)
                Text("Feed access closes when the timer ends.")
                    .font(.caption)
                    .foregroundStyle(MoriWidgetColors.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                MoriBeforeFeedLiveActivityProgress(state: context.state)
            }

            Spacer(minLength: 8)

            MoriBeforeFeedLiveActivityCountdown(
                endsAt: context.state.endsAt,
                alignment: .trailing,
                titleFont: .system(size: 22, weight: .semibold, design: .rounded),
                labelFont: .caption2
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

@available(iOS 16.1, *)
private struct MoriBeforeFeedLiveActivityStatus: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "pause.fill")
                .font(.caption.weight(.bold))
            Text("Open window")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(MoriWidgetColors.paper)
    }
}

@available(iOS 16.1, *)
private struct MoriBeforeFeedLiveActivityCountdown: View {
    let endsAt: Date
    let alignment: HorizontalAlignment
    let titleFont: Font
    let labelFont: Font

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(endsAt, style: .timer)
                .font(titleFont.monospacedDigit())
                .foregroundStyle(MoriWidgetColors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text("left")
                .font(labelFont.weight(.medium))
                .foregroundStyle(MoriWidgetColors.mutedInk)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Open window time remaining")
    }
}

@available(iOS 16.1, *)
private struct MoriBeforeFeedLiveActivityProgress: View {
    let state: MoriBeforeFeedWindowAttributes.ContentState

    var body: some View {
        ProgressView(value: state.progress())
            .progressViewStyle(.linear)
            .tint(MoriWidgetColors.leafAccent)
            .background(MoriWidgetColors.ink.opacity(0.12))
            .clipShape(Capsule())
    }
}
#endif

@main
struct MoriWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        MoriWidgets()
        MoriPulseWidget()
        MoriJournalQuickStartWidget()
#if canImport(ActivityKit) && os(iOS)
        if #available(iOS 16.1, *) {
            MoriBeforeFeedWindowLiveActivityWidget()
        }
#endif
    }
}

struct JournalQuickStartEntry: TimelineEntry {
    let date: Date
    let hasReminderEnabled: Bool
    let reminderTimeText: String
}

struct JournalQuickStartProvider: TimelineProvider {
    func placeholder(in context: Context) -> JournalQuickStartEntry {
        JournalQuickStartEntry(date: Date(), hasReminderEnabled: true, reminderTimeText: "9:00 PM")
    }

    func getSnapshot(in context: Context, completion: @escaping (JournalQuickStartEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JournalQuickStartEntry>) -> Void) {
        let now = Date()
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now.addingTimeInterval(21600)
        completion(Timeline(entries: [entry(now: now)], policy: .after(nextRefresh)))
    }

    private func entry(now: Date = Date()) -> JournalQuickStartEntry {
        let defaults = MoriSharedDefaults.shared

        return JournalQuickStartEntry(
            date: now,
            hasReminderEnabled: defaults.bool(forKey: "journalReminderEnabled"),
            reminderTimeText: Self.formattedReminderTime(defaults: defaults, now: now)
        )
    }

    private static func formattedReminderTime(defaults: UserDefaults, now: Date) -> String {
        let hour = defaults.object(forKey: "journalReminderHour") as? Int ?? 21
        let minute = defaults.object(forKey: "journalReminderMinute") as? Int ?? 0
        var components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Calendar.current.date(from: components) ?? now)
    }
}
