import SwiftUI

enum MoriPracticeSheet: Identifiable {
    case selection
    case pulse
    case verification(MoriPractice)
    case completion(MoriPractice, Int)
    case beforeFeed
    case morningGate
    case breathingLibrary
    case settleTimer
    case focusCycle
    case quietMode
    case journal
    case dailyCheckIn

    var id: String {
        switch self {
        case .selection:
            return "selection"
        case .pulse:
            return "pulse"
        case .verification(let practice):
            return "verification-\(practice.id)"
        case .completion(let practice, let seeds):
            return "completion-\(practice.id)-\(seeds)"
        case .beforeFeed:
            return "before-feed"
        case .morningGate:
            return "morning-gate"
        case .breathingLibrary:
            return "breathing-library"
        case .settleTimer:
            return "settle-timer"
        case .focusCycle:
            return "focus-cycle"
        case .quietMode:
            return "quiet-mode"
        case .journal:
            return "journal"
        case .dailyCheckIn:
            return "daily-check-in"
        }
    }

    static func destination(for practice: MoriPractice) -> MoriPracticeSheet {
        switch practice.route {
        case .quickComplete:
            return .verification(practice)
        case .breathing:
            return .breathingLibrary
        case .settle:
            return .settleTimer
        case .focusCycle:
            return .focusCycle
        case .quietMode:
            return .quietMode
        case .journal:
            return .journal
        case .dailyCheckIn:
            return .dailyCheckIn
        }
    }
}

struct MoriPracticeSheetContent: View {
    let sheet: MoriPracticeSheet
    let routeSource: MoriAppRouteSource?
    let selectionTitle: String
    let selectionSubtitle: String
    let beforeFeedDurationSeconds: Int
    var morningGateDurationSeconds = MoriScreenTimeShared.defaultMorningGateDurationSeconds
    var onStartPractice: (MoriPractice) -> Void = { _ in }
    var onCompletePractice: (MoriPractice) -> Void = { _ in }
    var pulseShowsDismissButton = false

    var body: some View {
        switch sheet {
        case .selection:
            MoriPracticeSelectionSheet(
                title: selectionTitle,
                subtitle: selectionSubtitle,
                practices: MoriPractice.plantSeedChoices,
                onStartPractice: onStartPractice
            )
        case .pulse:
            ClarityPulseView(
                showsDismissButton: pulseShowsDismissButton
            )
        case .verification(let practice):
            MoriPracticeVerificationSheet(
                practice: practice,
                onComplete: onCompletePractice
            )
        case .completion(let practice, let seeds):
            MoriPracticeCompletionSheet(practice: practice, seeds: seeds)
        case .beforeFeed:
            MoriBeforeFeedResetSheet(
                durationSeconds: beforeFeedDurationSeconds,
                routeSource: routeSource
            )
        case .morningGate:
            MoriMorningResetSheet(
                durationSeconds: morningGateDurationSeconds,
                routeSource: routeSource
            )
        case .breathingLibrary:
            NavigationStack {
                MoriBreathingLibraryView()
            }
        case .settleTimer:
            NavigationStack {
                SettleTimerDetailView()
            }
        case .focusCycle:
            NavigationStack {
                PomodoroPracticeDetailView()
            }
        case .quietMode:
            QuietModeView(showsDismissButton: true)
        case .journal:
            GratitudeJournalScreen(showsDismissButton: true)
        case .dailyCheckIn:
            GratitudeJournalScreen(showsDismissButton: true, appLimitFeature: .dailyCheckIn)
        }
    }
}
