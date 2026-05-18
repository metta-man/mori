import SwiftUI

@main
struct MoriWatchApp: App {
    init() {
        MoriWatchSettingsReceiver.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            MoriWatchSummaryView(snapshot: MoriWidgetSnapshot())
                .onOpenURL { _ in
                    MoriWatchSettingsReceiver.shared.activate()
                }
        }
    }
}

private struct MoriWatchSummaryView: View {
    let snapshot: MoriWidgetSnapshot

    var body: some View {
        VStack(spacing: 8) {
            Gauge(value: snapshot.progress) {
                Image(systemName: "hourglass")
            } currentValueLabel: {
                Text("\(Int(snapshot.progress * 100))%")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(.yellow)

            Text("\(snapshot.primaryCountdownValue.formatted())")
                .font(.system(.title2, design: .monospaced).weight(.light))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(snapshot.primaryCountdownLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.black, for: .navigation)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(snapshot.primaryCountdownValue) \(snapshot.primaryCountdownLabel) left")
    }
}
