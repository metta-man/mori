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
        Self.previewEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (MoriWidgetEntry) -> Void) {
        let now = Date()
        guard !context.isPreview else {
            completion(Self.previewEntry(now: now))
            return
        }

        completion(MoriWidgetEntry(
            date: now,
            snapshot: MoriWidgetSnapshot(now: now),
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

    private static func previewEntry(now: Date = Date()) -> MoriWidgetEntry {
        MoriWidgetEntry(
            date: now,
            snapshot: MoriWidgetSnapshot(
                archiveStartDate: Calendar.current.date(byAdding: .year, value: -30, to: now) ?? now,
                archiveSpanYears: 80,
                now: now
            ),
            context: .widgetPreview
        )
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
        .description("See today's attention and Life Grid at a glance.")
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
        Self.previewEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (MoriPulseWidgetEntry) -> Void) {
        let now = Date()
        completion(
            context.isPreview
                ? Self.previewEntry(now: now)
                : MoriPulseWidgetEntry(date: now, context: MoriWidgetContextSnapshot.load())
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoriPulseWidgetEntry>) -> Void) {
        let now = Date()
        let entry = MoriPulseWidgetEntry(date: now, context: MoriWidgetContextSnapshot.load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private static func previewEntry(now: Date = Date()) -> MoriPulseWidgetEntry {
        MoriPulseWidgetEntry(date: now, context: .widgetPreview)
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
        case .accessoryCircular:
            PulseAccessoryCircularWidget(context: entry.context)
        case .accessoryRectangular:
            PulseAccessoryRectangularWidget(context: entry.context)
        case .accessoryInline:
            Text(MoriL10n.string(
                "recovery.widget.score",
                defaultValue: "Recovery %@",
                arguments: [entry.context.recoveryScoreText]
            ))
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
                .widgetURL(URL(string: "mori://recovery"))
        }
        .configurationDisplayName("Recovery")
        .description("See a private recovery signal calculated on your iPhone.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
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
            let isClosed = context.moriIsStale
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    MoriBeforeFeedLiveActivityStatus(isClosed: isClosed)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if isClosed {
                        MoriBeforeFeedLiveActivityClosedLabel()
                    } else {
                        MoriBeforeFeedLiveActivityCountdown(
                            state: context.state,
                            alignment: .trailing,
                            titleFont: .system(size: 18, weight: .semibold, design: .rounded),
                            labelFont: .caption2,
                            titleColor: MoriWidgetColors.paper,
                            labelColor: MoriWidgetColors.paper.opacity(0.72)
                        )
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if isClosed {
                        Text(MoriBeforeFeedLiveActivityCopy.closedMessage)
                            .font(.caption2)
                            .foregroundStyle(MoriWidgetColors.paper.opacity(0.82))
                    } else {
                        MoriBeforeFeedLiveActivityProgress(state: context.state)
                    }
                }
            } compactLeading: {
                MoriBeforeFeedLiveActivityIslandIcon(
                    icon: isClosed ? .appLimit : .pause,
                    iconSize: 12
                )
            } compactTrailing: {
                if isClosed {
                    MoriBeforeFeedLiveActivityClosedLabel()
                } else {
                    MoriBeforeFeedLiveActivityTimerText(state: context.state)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(MoriWidgetColors.paper)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: 42)
                }
            } minimal: {
                MoriBeforeFeedLiveActivityIslandIcon(
                    icon: isClosed ? .appLimit : .pause,
                    iconSize: 11
                )
            }
            .widgetURL(URL(string: "mori://before-feed?source=live-activity"))
            .keylineTint(MoriWidgetColors.leafAccent)
        }
    }
}

@available(iOS 16.1, *)
private struct MoriBeforeFeedWindowLiveActivityView: View {
    let context: ActivityViewContext<MoriBeforeFeedWindowAttributes>

    private var isClosed: Bool {
        context.moriIsStale
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MoriWidgetColors.surfaceRaised)
                MoriBitmapIconImage(icon: isClosed ? .appLimit : .pause, size: 24, opacity: 0.94)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 6) {
                Text(isClosed ? MoriBeforeFeedLiveActivityCopy.closedTitle : MoriL10n.display("Open window"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MoriWidgetColors.ink)
                Text(isClosed ? MoriBeforeFeedLiveActivityCopy.closedMessage : MoriBeforeFeedLiveActivityCopy.activeMessage)
                    .font(.caption)
                    .foregroundStyle(MoriWidgetColors.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                if !isClosed {
                    MoriBeforeFeedLiveActivityProgress(state: context.state)
                }
            }

            Spacer(minLength: 8)

            if !isClosed {
                MoriBeforeFeedLiveActivityCountdown(
                    state: context.state,
                    alignment: .trailing,
                    titleFont: .system(size: 22, weight: .semibold, design: .rounded),
                    labelFont: .caption2,
                    titleColor: MoriWidgetColors.ink,
                    labelColor: MoriWidgetColors.mutedInk
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isClosed
                ? MoriBeforeFeedLiveActivityCopy.closedAccessibilityLabel
                : MoriBeforeFeedLiveActivityCopy.activeAccessibilityLabel
        )
        .accessibilityValue(
            isClosed
                ? Text("")
                : MoriBeforeFeedLiveActivityAccessibility.timerValue(state: context.state)
        )
    }
}

@available(iOS 16.1, *)
private struct MoriBeforeFeedLiveActivityStatus: View {
    let isClosed: Bool

    var body: some View {
        HStack(spacing: 6) {
            MoriBeforeFeedLiveActivityIslandIcon(
                icon: isClosed ? .appLimit : .pause,
                iconSize: 11
            )
            Text(isClosed ? MoriBeforeFeedLiveActivityCopy.closedTitle : MoriL10n.display("Open window"))
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(MoriWidgetColors.paper)
    }
}

@available(iOS 16.1, *)
private struct MoriBeforeFeedLiveActivityCountdown: View {
    let state: MoriBeforeFeedWindowAttributes.ContentState
    let alignment: HorizontalAlignment
    let titleFont: Font
    let labelFont: Font
    let titleColor: Color
    let labelColor: Color

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            MoriBeforeFeedLiveActivityTimerText(state: state)
                .font(titleFont.monospacedDigit())
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text("left")
                .font(labelFont.weight(.medium))
                .foregroundStyle(labelColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MoriBeforeFeedLiveActivityCopy.activeAccessibilityLabel)
        .accessibilityValue(MoriBeforeFeedLiveActivityAccessibility.timerValue(state: state))
    }
}

@available(iOS 16.1, *)
private struct MoriBeforeFeedLiveActivityIslandIcon: View {
    let icon: MoriBitmapIcon
    let iconSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(MoriWidgetColors.paper.opacity(0.96))
            MoriBitmapIconImage(icon: icon, size: iconSize, opacity: 0.94)
        }
        .frame(width: iconSize + 8, height: iconSize + 8)
    }
}

@available(iOS 16.1, *)
private struct MoriBeforeFeedLiveActivityTimerText: View {
    let state: MoriBeforeFeedWindowAttributes.ContentState

    var body: some View {
        Text(
            timerInterval: state.timerInterval,
            countsDown: true,
            showsHours: state.durationSeconds >= 60 * 60
        )
    }
}

@available(iOS 16.1, *)
private enum MoriBeforeFeedLiveActivityAccessibility {
    static func timerValue(state: MoriBeforeFeedWindowAttributes.ContentState) -> Text {
        Text(
            timerInterval: state.timerInterval,
            countsDown: true,
            showsHours: state.durationSeconds >= 60 * 60
        )
    }
}

@available(iOS 16.1, *)
private struct MoriBeforeFeedLiveActivityClosedLabel: View {
    var body: some View {
        Text(MoriBeforeFeedLiveActivityCopy.closedShortLabel)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(MoriWidgetColors.paper)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .accessibilityLabel(MoriBeforeFeedLiveActivityCopy.closedAccessibilityLabel)
    }
}

@available(iOS 16.1, *)
private struct MoriBeforeFeedLiveActivityProgress: View {
    let state: MoriBeforeFeedWindowAttributes.ContentState

    var body: some View {
        ProgressView(timerInterval: state.timerInterval, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
            .progressViewStyle(.linear)
            .tint(MoriWidgetColors.leafAccent)
            .background(MoriWidgetColors.ink.opacity(0.12))
            .clipShape(Capsule())
    }
}

@available(iOS 16.1, *)
private extension ActivityViewContext where Attributes == MoriBeforeFeedWindowAttributes {
    var moriIsStale: Bool {
        if #available(iOS 16.2, *) {
            return isStale
        }
        return false
    }
}

private enum MoriBeforeFeedLiveActivityCopy {
    static var activeMessage: String {
        MoriL10n.string(
            "before_feed.live_activity.active_message",
            defaultValue: "Feed access closes when the timer ends."
        )
    }

    static var activeAccessibilityLabel: String {
        MoriL10n.string(
            "before_feed.live_activity.active_accessibility",
            defaultValue: "Open window, time remaining"
        )
    }

    static var closedTitle: String {
        MoriL10n.string(
            "before_feed.live_activity.closed_title",
            defaultValue: "Window closed"
        )
    }

    static var closedShortLabel: String {
        MoriL10n.string(
            "before_feed.live_activity.closed_short",
            defaultValue: "Closed"
        )
    }

    static var closedMessage: String {
        MoriL10n.string(
            "before_feed.live_activity.closed_message",
            defaultValue: "The feed access window has ended."
        )
    }

    static var closedAccessibilityLabel: String {
        MoriL10n.string(
            "before_feed.live_activity.closed_accessibility",
            defaultValue: "Feed access window closed"
        )
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
        Self.previewEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (JournalQuickStartEntry) -> Void) {
        let now = Date()
        completion(context.isPreview ? Self.previewEntry(now: now) : entry(now: now))
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

    private static func previewEntry(now: Date = Date()) -> JournalQuickStartEntry {
        JournalQuickStartEntry(
            date: now,
            hasReminderEnabled: true,
            reminderTimeText: formattedReminderTime(hour: 21, minute: 0, now: now)
        )
    }

    private static func formattedReminderTime(defaults: UserDefaults, now: Date) -> String {
        let hour = defaults.object(forKey: "journalReminderHour") as? Int ?? 21
        let minute = defaults.object(forKey: "journalReminderMinute") as? Int ?? 0

        return formattedReminderTime(hour: hour, minute: minute, now: now)
    }

    private static func formattedReminderTime(hour: Int, minute: Int, now: Date) -> String {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Calendar.current.date(from: components) ?? now)
    }
}
