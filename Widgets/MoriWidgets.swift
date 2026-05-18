import SwiftUI
import WidgetKit

struct MoriWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: MoriWidgetSnapshot
}

struct MoriWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoriWidgetEntry {
        MoriWidgetEntry(
            date: Date(),
            snapshot: MoriWidgetSnapshot(
                birthDate: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
                lifeExpectancy: 80,
                timeUnit: .days
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MoriWidgetEntry) -> Void) {
        completion(MoriWidgetEntry(date: Date(), snapshot: MoriWidgetSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoriWidgetEntry>) -> Void) {
        let now = Date()
        let entry = MoriWidgetEntry(date: now, snapshot: MoriWidgetSnapshot(now: now))
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct MoriWidgetsEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: MoriWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            CountdownSmallWidget(snapshot: entry.snapshot)
        case .systemMedium:
            CountdownMediumWidget(snapshot: entry.snapshot)
        case .systemLarge:
            LifeGridLargeWidget(snapshot: entry.snapshot)
        case .accessoryCircular:
            AccessoryCircularWidget(snapshot: entry.snapshot)
        case .accessoryRectangular:
            AccessoryRectangularWidget(snapshot: entry.snapshot)
        case .accessoryInline:
            Text(entry.snapshot.primaryCompactCountdownText)
        default:
            CountdownSmallWidget(snapshot: entry.snapshot)
        }
    }
}

struct MoriWidgets: Widget {
    let kind = "MoriWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoriWidgetProvider()) { entry in
            MoriWidgetsEntryView(entry: entry)
                .moriWidgetContainerBackground()
        }
        .configurationDisplayName("Mori")
        .description("See your countdown or life grid at a glance.")
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

struct MoriJournalQuickStartWidget: Widget {
    let kind = "MoriJournalQuickStartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JournalQuickStartProvider()) { entry in
            JournalQuickStartEntryView(entry: entry)
                .moriWidgetContainerBackground()
                .widgetURL(URL(string: "mori://journal"))
        }
        .configurationDisplayName("Start Writing")
        .description("Open Mori straight to your journal.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
    }
}

@main
struct MoriWidgetBundle: WidgetBundle {
    var body: some Widget {
        MoriWidgets()
        MoriJournalQuickStartWidget()
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

private struct JournalQuickStartEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

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
        .accessibilityLabel("Start writing in your Mori journal")
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            MoriWidgetHeader(title: "Journal", symbol: "heart.text.square.fill")

            Spacer(minLength: 0)

            Text("Write one line")
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .foregroundStyle(MoriWidgetColors.cream)
                .minimumScaleFactor(0.78)
                .lineLimit(2)

            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.system(size: 11, weight: .bold))
                Text(entry.hasReminderEnabled ? "\(entry.reminderTimeText) reminder" : "Start writing")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(renderingMode == .accented ? MoriWidgetColors.cream : MoriWidgetColors.gold)
            .widgetAccentable()
        }
    }

    private var mediumLayout: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                MoriWidgetHeader(title: "Journal", symbol: "heart.text.square.fill")

                Text("Capture one thing worth remembering from today.")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWidgetColors.cream)
                    .minimumScaleFactor(0.82)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)

            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(MoriWidgetColors.gold)
                    .widgetAccentable()

                Text(entry.hasReminderEnabled ? entry.reminderTimeText : "Open")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(renderingMode == .accented ? MoriWidgetColors.cream : MoriWidgetColors.creamMuted)
                    .lineLimit(1)
            }
            .frame(width: 82, height: 82)
            .background(renderingMode == .accented ? MoriWidgetColors.cream.opacity(0.12) : MoriWidgetColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(MoriWidgetColors.gold.opacity(0.18), lineWidth: 1)
            )
        }
    }
}

private struct CountdownSmallWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let snapshot: MoriWidgetSnapshot

    var body: some View {
        MoriWidgetShell {
            VStack(alignment: .leading, spacing: 10) {
                MoriWidgetHeader(title: "Mori", symbol: "hourglass")

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.primaryCountdownValue.formatted())
                        .font(.system(size: 42, weight: .light, design: .monospaced))
                        .foregroundStyle(MoriWidgetColors.gold)
                        .widgetAccentable()
                        .minimumScaleFactor(0.58)
                        .lineLimit(1)

                    Text(snapshot.primaryCountdownLabel)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(MoriWidgetColors.cream)
                }

                Text("Make today count")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(renderingMode == .accented ? MoriWidgetColors.cream : MoriWidgetColors.creamMuted)
                    .lineLimit(1)
            }
        }
    }
}

private struct CountdownMediumWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let snapshot: MoriWidgetSnapshot

    var body: some View {
        MoriWidgetShell {
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    MoriWidgetHeader(title: "Countdown", symbol: "hourglass")

                    Spacer(minLength: 0)

                    Text(snapshot.primaryCountdownValue.formatted())
                        .font(.system(size: 46, weight: .light, design: .monospaced))
                        .foregroundStyle(MoriWidgetColors.gold)
                        .widgetAccentable()
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)

                    Text("\(snapshot.primaryCountdownLabel) remaining")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(MoriWidgetColors.cream)
                        .lineLimit(1)
                }

                VStack(alignment: .leading, spacing: 10) {
                    MiniLifeGrid(snapshot: snapshot, columns: 13, rows: 8, dotSize: 5, spacing: 3)

                    VStack(alignment: .leading, spacing: 5) {
                        ProgressView(value: snapshot.progress)
                            .tint(MoriWidgetColors.gold)
                            .background(MoriWidgetColors.cream.opacity(0.12))
                            .clipShape(Capsule())
                            .widgetAccentable()

                        Text("\(snapshot.weeksRemaining.formatted()) weeks left")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(renderingMode == .accented ? MoriWidgetColors.cream : MoriWidgetColors.creamMuted)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: 126)
            }
        }
    }
}

private struct LifeGridLargeWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let snapshot: MoriWidgetSnapshot

    var body: some View {
        MoriWidgetShell {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        MoriWidgetHeader(title: "Life Grid", symbol: "circle.grid.3x3.fill")

                        Text("\(snapshot.weeksRemaining.formatted()) weeks remaining")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(MoriWidgetColors.gold)
                            .widgetAccentable()
                    }

                    Spacer()

                    Text("\(Int(snapshot.progress * 100))%")
                        .font(.system(size: 24, weight: .light, design: .monospaced))
                        .foregroundStyle(MoriWidgetColors.cream)
                }

                LifeGridPreview(snapshot: snapshot)

                ProgressView(value: snapshot.progress)
                    .tint(MoriWidgetColors.gold)
                    .background(MoriWidgetColors.cream.opacity(0.12))
                    .clipShape(Capsule())
                    .widgetAccentable()

                Text("Each dot is one week. Gold marks this week.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(renderingMode == .accented ? MoriWidgetColors.cream : MoriWidgetColors.creamMuted)
                    .lineLimit(1)
            }
        }
    }
}

private struct AccessoryCircularWidget: View {
    let snapshot: MoriWidgetSnapshot

    var body: some View {
        Gauge(value: snapshot.progress) {
            Image(systemName: "hourglass")
        } currentValueLabel: {
            Text(snapshot.primaryCompactCountdownValue)
                .minimumScaleFactor(0.55)
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}

private struct AccessoryRectangularWidget: View {
    let snapshot: MoriWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Mori")
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(snapshot.primaryCompactCountdownValue)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                Text(snapshot.primaryCountdownUnitSymbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: snapshot.progress)
        }
    }
}

private struct MoriWidgetShell<Content: View>: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            if renderingMode == .fullColor {
                MoriWidgetColors.dark

                RadialGradient(
                    colors: [
                        MoriWidgetColors.gold.opacity(0.16),
                        .clear
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 190
                )
            }

            content
                .padding(16)
        }
    }
}

private struct MoriWidgetHeader: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MoriWidgetColors.gold)
                .widgetAccentable()

            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(renderingMode == .accented ? MoriWidgetColors.cream : MoriWidgetColors.creamMuted)
                .lineLimit(1)
        }
    }
}

private struct MiniLifeGrid: View {
    let snapshot: MoriWidgetSnapshot
    let columns: Int
    let rows: Int
    let dotSize: CGFloat
    let spacing: CGFloat

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { column in
                        let index = row * columns + column
                        Circle()
                            .fill(color(for: index, visibleCount: rows * columns))
                            .frame(width: dotSize, height: dotSize)
                            .widgetAccentable(isCurrentWeek(index: index, visibleCount: rows * columns))
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func color(for index: Int, visibleCount: Int) -> Color {
        let mappedIndex = mappedWeekIndex(for: index, visibleCount: visibleCount)

        if mappedIndex == snapshot.currentWeekIndex {
            return MoriWidgetColors.gold
        } else if mappedIndex < snapshot.weeksLived {
            return MoriWidgetColors.cream.opacity(0.72)
        } else {
            return MoriWidgetColors.cream.opacity(0.14)
        }
    }

    private func isCurrentWeek(index: Int, visibleCount: Int) -> Bool {
        mappedWeekIndex(for: index, visibleCount: visibleCount) == snapshot.currentWeekIndex
    }

    private func mappedWeekIndex(for index: Int, visibleCount: Int) -> Int {
        Int((Double(index) / Double(max(visibleCount - 1, 1))) * Double(max(snapshot.totalWeeks - 1, 1)))
    }
}

private struct LifeGridPreview: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let snapshot: MoriWidgetSnapshot

    private let columns = 26

    var body: some View {
        GeometryReader { proxy in
            let rows = min(max(snapshot.lifeExpectancy, 1), 90)
            let spacing: CGFloat = 2
            let dotSize = max(2.2, min(4.4, (proxy.size.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)))

            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { column in
                            let firstWeek = row * 52 + column * 2
                            Capsule()
                                .fill(color(for: firstWeek))
                                .frame(width: dotSize, height: dotSize)
                                .widgetAccentable(firstWeek <= snapshot.currentWeekIndex && snapshot.currentWeekIndex < firstWeek + 2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
        .padding(10)
        .background(renderingMode == .accented ? MoriWidgetColors.cream.opacity(0.12) : MoriWidgetColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriWidgetColors.gold.opacity(0.18), lineWidth: 1)
        )
        .accessibilityLabel("Life grid with \(snapshot.weeksLived) weeks lived and \(snapshot.weeksRemaining) weeks remaining")
    }

    private func color(for weekIndex: Int) -> Color {
        if weekIndex <= snapshot.currentWeekIndex && snapshot.currentWeekIndex < weekIndex + 2 {
            return MoriWidgetColors.gold
        } else if weekIndex < snapshot.weeksLived {
            return MoriWidgetColors.cream.opacity(0.72)
        } else {
            return MoriWidgetColors.cream.opacity(0.13)
        }
    }
}

private enum MoriWidgetColors {
    static let dark = Color(hex: "#0A0A0A")
    static let surface = Color(hex: "#171717")
    static let gold = Color(hex: "#D4AF37")
    static let cream = Color(hex: "#FDF5E6")
    static let creamMuted = Color(hex: "#A9A39A")
}

private extension View {
    @ViewBuilder
    func moriWidgetContainerBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(MoriWidgetColors.dark, for: .widget)
        } else {
            background(MoriWidgetColors.dark)
        }
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64

        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
