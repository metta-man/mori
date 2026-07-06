import DeviceActivity
import Foundation
import FamilyControls

final class MoriScreenTimeMonitorExtension: DeviceActivityMonitor {
    private let selectionStore = ScreenTimeSelectionStore()
    private let activeSessionStore = AttentionShieldActiveSessionStore()
    private let shieldApplier = AttentionShieldApplier()
    private let beforeFeedGateStore = BeforeFeedGateStore()

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        guard activity == .moriDailySelectedApps,
              event == .moriSelectedAppsThreshold
        else {
            return
        }

        MoriScreenTimeSignalStore.append(
            MoriScreenTimeSignal(
                thresholdID: "mori.daily.selected-apps.mori.selected-apps.threshold",
                mode: .dailyThreshold
            )
        )
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        switch activity {
        case .moriBeforeFeedGrace:
            refreshAfterBeforeFeedGraceExpired()
        case .moriMorningGate:
            applyPassiveGateShieldIfNeeded()
        default:
            return
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        switch activity {
        case .moriActiveSession:
            refreshAfterActiveSessionEnded()
        case .moriBeforeFeedGrace:
            refreshAfterBeforeFeedGraceExpired()
        case .moriMorningGate:
            refreshAfterMorningGateEnded()
        default:
            return
        }
    }

    private func applyPassiveGateShieldIfNeeded() {
        passiveGateApplier.apply(
            passiveGatePolicy.refreshAction(activeSession: unexpiredActiveSession)
        )
    }

    private func refreshAfterBeforeFeedGraceExpired() {
        beforeFeedGateStore.clearGraceUntil()
        applyPassiveGateShieldIfNeeded()
    }

    private func refreshAfterMorningGateEnded() {
        passiveGateApplier.apply(
            passiveGatePolicy.morningGateEndedAction(activeSession: unexpiredActiveSession)
        )
    }

    private func refreshAfterActiveSessionEnded() {
        guard let session = activeSession else {
            applyPassiveGateShieldIfNeeded()
            return
        }

        guard session.isExpired else {
            passiveGateApplier.apply(features: [session.feature])
            return
        }

        activeSessionStore.clear()
        passiveGateApplier.apply(passiveGatePolicy.refreshAction)
    }

    private var passiveGateApplier: AttentionShieldPassiveGateApplier {
        AttentionShieldPassiveGateApplier(
            selectionStore: selectionStore,
            shieldApplier: shieldApplier
        )
    }

    private var passiveGatePolicy: AttentionShieldPassiveGatePolicy {
        AttentionShieldPassiveGatePolicy(
            morningGateShouldApply: MorningGate.shouldApplyShield(),
            morningGateHasSelection: selectionStore.hasEffectiveSelection(for: .morningGate),
            beforeFeedGateEnabled: beforeFeedGateStore.nativeGateEnabled(),
            beforeFeedInGraceWindow: beforeFeedGateStore.isInGraceWindow(),
            beforeFeedHasSelection: selectionStore.hasEffectiveSelection(for: .beforeFeed)
        )
    }

    private var unexpiredActiveSession: MoriScreenTimeActiveSession? {
        activeSessionStore.loadUnexpiredSession()
    }

    private var activeSession: MoriScreenTimeActiveSession? {
        activeSessionStore.load()
    }
}
