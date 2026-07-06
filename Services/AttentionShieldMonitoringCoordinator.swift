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
            activityScheduler.stopBeforeFeedGrace()
            return .noChange
        }
        guard let graceUntil else {
            activityScheduler.stopBeforeFeedGrace()
            return .noChange
        }

        do {
            try activityScheduler.scheduleBeforeFeedGrace(graceUntil: graceUntil)
            return .scheduled
        } catch {
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
}
