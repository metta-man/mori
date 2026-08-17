import Combine
import Foundation
import SwiftUI

enum MoriWatchRoute: Hashable {
    case weekArchive
    case recovery

    init?(url: URL) {
        let target = "\(url.host ?? "") \(url.path)".lowercased()
        if target.contains("recovery") || target.contains("readiness") || target.contains("pulse") {
            self = .recovery
        } else if target.contains("week") || target.contains("archive") || target.contains("grid") {
            self = .weekArchive
        } else {
            return nil
        }
    }
}

@MainActor
final class MoriWatchRouteStore: ObservableObject {
    static let shared = MoriWatchRouteStore()

    @Published private(set) var pendingRoute: MoriWatchRoute?

    func open(_ url: URL) {
        pendingRoute = MoriWatchRoute(url: url)
    }

    func consume() -> MoriWatchRoute? {
        defer { pendingRoute = nil }
        return pendingRoute
    }
}

struct MoriWatchWeekSummaryView: View {
    let snapshot: MoriWidgetSnapshot

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                MoriBitmapIconImage(icon: .roots, size: 22, opacity: 0.88)
                Text(MoriL10n.display("Life Grid"))
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(MoriWatchPalette.ink)
                Text(snapshot.archiveWeekText)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MoriWatchPalette.ink)
                ProgressView(value: snapshot.progress)
                    .tint(MoriWatchPalette.moss)
                Text(snapshot.archiveProgressPercentText)
                    .font(.caption)
                    .foregroundStyle(MoriWatchPalette.muted)
            }
            .padding(12)
            .moriWatchCard(cornerRadius: 16)
        }
        .moriWatchPaperBackground()
        .navigationTitle("")
    }
}

struct MoriWatchRecoverySummaryView: View {
    let context: MoriWidgetContextSnapshot

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                MoriBitmapIconImage(icon: .heart, size: 22, opacity: 0.88)
                Text(MoriL10n.display("Recovery"))
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(MoriWatchPalette.ink)
                Text(context.recoveryScoreText)
                    .font(.system(size: 36, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MoriWatchPalette.ink)
                Text(context.displayRecoveryState)
                    .font(.headline)
                    .foregroundStyle(MoriWatchPalette.moss)
                Text(context.displayRecoveryDetail)
                    .font(.caption)
                    .foregroundStyle(MoriWatchPalette.muted)
                Text(MoriL10n.display("Calculated privately on your iPhone."))
                    .font(.caption2)
                    .foregroundStyle(MoriWatchPalette.muted)
            }
            .padding(12)
            .moriWatchCard(cornerRadius: 16)
        }
        .moriWatchPaperBackground()
        .navigationTitle("")
    }
}
