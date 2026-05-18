import SwiftUI
import WidgetKit

struct MoriWatchWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: MoriWidgetSnapshot
}

struct MoriWatchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoriWatchWidgetEntry {
        MoriWatchWidgetEntry(
            date: Date(),
            snapshot: MoriWidgetSnapshot(
                birthDate: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
                lifeExpectancy: 80,
                timeUnit: .days
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MoriWatchWidgetEntry) -> Void) {
        completion(MoriWatchWidgetEntry(date: Date(), snapshot: MoriWidgetSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoriWatchWidgetEntry>) -> Void) {
        let now = Date()
        let entry = MoriWatchWidgetEntry(date: now, snapshot: MoriWidgetSnapshot(now: now))
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct MoriWatchWidgetsEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: MoriWatchWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            MoriWatchCircularComplication(snapshot: entry.snapshot)
        case .accessoryCorner:
            MoriWatchCornerComplication(snapshot: entry.snapshot)
        case .accessoryRectangular:
            MoriWatchRectangularComplication(snapshot: entry.snapshot)
        case .accessoryInline:
            Text(entry.snapshot.primaryCompactCountdownText)
        default:
            MoriWatchCircularComplication(snapshot: entry.snapshot)
        }
    }
}

struct MoriWatchWidgets: Widget {
    let kind = "MoriWatchWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoriWatchWidgetProvider()) { entry in
            MoriWatchWidgetsEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
                .widgetURL(URL(string: "mori://watch/countdown"))
        }
        .configurationDisplayName("Mori")
        .description("Keep your Mori countdown on your watch face.")
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
    }
}

private struct MoriWatchCircularComplication: View {
    let snapshot: MoriWidgetSnapshot

    var body: some View {
        Gauge(value: snapshot.progress) {
            Image(systemName: "hourglass")
                .font(.system(size: 10, weight: .semibold))
        } currentValueLabel: {
            Text(compactValue)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel("\(snapshot.primaryCountdownValue) \(snapshot.primaryCountdownLabel) left")
    }

    private var compactValue: String {
        snapshot.primaryCompactCountdownValue.lowercased()
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
            .accessibilityLabel("\(snapshot.primaryCountdownValue) \(snapshot.primaryCountdownLabel) left")
    }

    private var compactValue: String {
        snapshot.primaryCompactCountdownValue.lowercased()
    }
}

private struct MoriWatchRectangularComplication: View {
    let snapshot: MoriWidgetSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Gauge(value: snapshot.progress) {
                EmptyView()
            } currentValueLabel: {
                Image(systemName: "hourglass")
                    .font(.system(size: 9, weight: .semibold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text("Mori")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(snapshot.primaryCompactCountdownValue.lowercased())
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)

                    Text("left")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(snapshot.primaryCountdownLabel)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(snapshot.primaryCountdownValue) \(snapshot.primaryCountdownLabel) left")
    }
}
