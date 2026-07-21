import Foundation
import FamilyControls

enum AttentionShieldMonitoringOutcome {
    case noChange
    case scheduled
    case failed(String)
}

@MainActor
struct AttentionShieldMonitoringCoordinator {
    private let activityScheduler: AttentionShieldActivityScheduler
    private let beforeFeedGateStore = BeforeFeedGateStore()
    private let selectionStore = ScreenTimeSelectionStore()

    init(activityScheduler: AttentionShieldActivityScheduler? = nil) {
        self.activityScheduler = activityScheduler ?? AttentionShieldActivityScheduler()
    }

    func scheduleMorningGate(
        isAuthorized: Bool,
        isEnabled: Bool,
        hasSelection: Bool
    ) -> AttentionShieldMonitoringOutcome {
        guard isAuthorized else {
            activityScheduler.stopMorningGate()
            return .noChange
        }
        guard isEnabled, hasSelection else {
            activityScheduler.stopMorningGate()
            return .noChange
        }

        do {
            try activityScheduler.scheduleMorningGate()
            return .scheduled
        } catch {
            return .failed("Could not schedule Morning Gate.")
        }
    }

    func scheduleDailyThreshold(
        isAuthorized: Bool,
        hasSelection: Bool,
        thresholdMinutes: Int,
        selection: () -> FamilyActivitySelection
    ) -> AttentionShieldMonitoringOutcome {
        guard isAuthorized else {
            activityScheduler.stopDailyThreshold()
            return .noChange
        }
        guard hasSelection else {
            activityScheduler.stopDailyThreshold()
            return .noChange
        }

        do {
            try activityScheduler.scheduleDailyThreshold(
                selection: selection(),
                thresholdMinutes: thresholdMinutes
            )
            return .scheduled
        } catch {
            return .failed("Could not start Screen Time monitoring.")
        }
    }

    func scheduleBeforeFeedGrace(
        isAuthorized: Bool,
        graceUntil: Date?
    ) -> AttentionShieldMonitoringOutcome {
        guard isAuthorized else {
            MoriScreenTimeMonitorHealthStore.record(
                beforeFeedHealthEvent(
                    kind: .beforeFeedGraceScheduleSkipped,
                    action: "skip",
                    message: "Screen Time authorization is not available.",
                    graceUntil: graceUntil
                )
            )
            activityScheduler.stopBeforeFeedGrace()
            return .noChange
        }
        guard let graceUntil else {
            MoriScreenTimeMonitorHealthStore.record(
                beforeFeedHealthEvent(
                    kind: .beforeFeedGraceScheduleSkipped,
                    action: "skip",
                    message: "No active Before Feed open window.",
                    graceUntil: nil
                )
            )
            activityScheduler.stopBeforeFeedGrace()
            return .noChange
        }

        do {
            try activityScheduler.scheduleBeforeFeedGrace(graceUntil: graceUntil)
            MoriScreenTimeMonitorHealthStore.record(
                beforeFeedHealthEvent(
                    kind: .beforeFeedGraceScheduled,
                    action: "schedule",
                    graceUntil: graceUntil
                )
            )
            return .scheduled
        } catch {
            MoriScreenTimeMonitorHealthStore.record(
                beforeFeedHealthEvent(
                    kind: .beforeFeedGraceScheduleFailed,
                    action: "fail",
                    message: error.localizedDescription,
                    graceUntil: graceUntil
                )
            )
            return .failed("Could not schedule Before Feed gate.")
        }
    }

    func scheduleActiveSession(
        isAuthorized: Bool,
        endDate: Date
    ) -> AttentionShieldMonitoringOutcome {
        guard isAuthorized else {
            activityScheduler.stopActiveSession()
            return .noChange
        }

        do {
            if try activityScheduler.scheduleActiveSession(endDate: endDate) {
                return .scheduled
            }
            return .noChange
        } catch {
            return .failed("Could not schedule app-limited session.")
        }
    }

    func stopActiveSession() {
        activityScheduler.stopActiveSession()
    }

    func stopBeforeFeedGrace() {
        activityScheduler.stopBeforeFeedGrace()
    }

    private func beforeFeedHealthEvent(
        kind: MoriScreenTimeMonitorHealthEventKind,
        action: String,
        message: String? = nil,
        graceUntil: Date? = nil
    ) -> MoriScreenTimeMonitorHealthEvent {
        let selection = selectionStore.effectiveSelection(for: .beforeFeed)
        let displayNames = selectionStore.summary(for: .beforeFeed).displayNames
        return MoriScreenTimeMonitorHealthEvent(
            traceID: beforeFeedGateStore.currentWindowTraceID(),
            kind: kind,
            activityName: "mori.before-feed.grace",
            featureRawValue: MoriScreenTimeFeature.beforeFeed.rawValue,
            action: action,
            policy: MoriScreenTimeMonitorHealthPolicy.none,
            message: message,
            graceUntil: graceUntil,
            beforeFeedNativeGateEnabled: beforeFeedGateStore.nativeGateEnabled(),
            beforeFeedInGraceWindow: beforeFeedGateStore.isInGraceWindow(),
            beforeFeedHasSelection: selectionStore.hasEffectiveSelection(for: .beforeFeed),
            applicationTokenCount: selection.applicationTokens.count,
            webDomainTokenCount: selection.webDomainTokens.count,
            displayNameCount: displayNames.count,
            displayNames: displayNames
        )
    }
}
