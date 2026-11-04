import Foundation
import Combine
import FamilyControls
#if canImport(ActivityKit) && os(iOS)
import ActivityKit
#endif

@MainActor
final class AttentionShieldManager: ObservableObject {
    static let shared = AttentionShieldManager()

    @Published private var authorizationStatus: AuthorizationStatus
    @Published private var defaultSelectedCount: Int = 0
    @Published private var profileSummaries: [MoriScreenTimeProfileSummary] = []
    @Published private(set) var activeSession: MoriScreenTimeActiveSession?
    @Published private var lastErrorMessage: String?
    @Published private var dailyThresholdMinutes: Int {
        didSet {
            let normalized = thresholdStore.saveDailyThresholdMinutes(dailyThresholdMinutes)
            if normalized != dailyThresholdMinutes {
                dailyThresholdMinutes = normalized
                return
            }
            scheduleDailyThresholdMonitoring()
        }
    }

    private let authorizationCenter = AuthorizationCenter.shared
    private let monitoringCoordinator = AttentionShieldMonitoringCoordinator()
    private let selectionCoordinator = AttentionShieldSelectionCoordinator()
    private let activeSessionStore = AttentionShieldActiveSessionStore()
    private let thresholdStore = AttentionShieldThresholdStore()
    private let shieldApplier = AttentionShieldApplier()
    private let beforeFeedGateStore = BeforeFeedGateStore()
    private let beforeFeedWindowEndNotificationScheduler = BeforeFeedWindowEndNotificationScheduler.shared
    private var cancellable: AnyCancellable?
    private var beforeFeedReapplyTask: Task<Void, Never>?
    private var lastScheduledBeforeFeedGraceUntil: Date?

    private init() {
        authorizationStatus = authorizationCenter.authorizationStatus
        dailyThresholdMinutes = thresholdStore.loadDailyThresholdMinutes()
        refreshSelectionState()
        cancellable = authorizationCenter.$authorizationStatus
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleAuthorizationStatusChange(status)
            }
        restoreActiveShieldIfNeeded()
    }

    var settingsSnapshot: AttentionShieldSettingsSnapshot {
        AttentionShieldSettingsSnapshot(
            authorizationStatus: authorizationStatus,
            isAuthorized: isAuthorized,
            defaultSelectedCount: defaultSelectedCount,
            profileSummaries: profileSummaries,
            lastErrorMessage: lastErrorMessage,
            dailyThresholdMinutes: dailyThresholdMinutes
        )
    }

    private var isAuthorized: Bool {
        AttentionShieldAuthorizationPolicy.canApplyShield(for: authorizationStatus)
    }

    @discardableResult
    func perform(_ action: AttentionShieldAction) -> Bool {
        return MoriShieldCoordination.legacy(fallback: false) {

        switch action {
        case .requestAuthorization:
            Task { await requestAuthorization() }
            return false
        case .setDailyThresholdMinutes(let minutes):
            setDailyThresholdMinutes(minutes)
            return false
        case .setFeatureEnabled(let isEnabled, let feature):
            setFeatureEnabled(isEnabled, for: feature)
            return false
        case .setFeatureUsesDefaultSelection(let usesDefaultSelection, let feature):
            setFeatureUsesDefaultSelection(usesDefaultSelection, for: feature)
            return false
        case .reconcileGateProtection(let feature):
            refreshPassiveGates(for: feature)
            return false
        case .reconcileProtectionState:
            reconcileProtectionState()
            return false
        case .commitSelectionDraft(let draft):
            commitSelectionDraft(draft)
            return false
        case .startTimedShieldDuration(let feature, let duration, let now):
            return startTimedShieldIfPossible(feature: feature, duration: duration, now: now)
        case .startTimedShieldSeconds(let feature, let remainingSeconds, let now):
            return startTimedShieldIfPossible(feature: feature, remainingSeconds: remainingSeconds, now: now)
        case .startManualShield(let feature, let now):
            return startManualShieldIfPossible(feature: feature, now: now)
        case .beginResetProtectionRequest(let feature, let remainingSeconds, let usesNativeBeforeFeedGate, let now):
            return beginResetProtection(
                feature: feature,
                remainingSeconds: remainingSeconds,
                usesNativeBeforeFeedGate: usesNativeBeforeFeedGate,
                now: now
            )
        case .endResetProtectionIfNeeded(let feature):
            endResetProtectionIfNeeded(feature: feature)
            return false
        case .endShield(let feature):
            endShield(feature: feature)
            return false
        case .confirmBeforeFeedAllowance(let request):
            guard let confirmation = beforeFeedGateStore.confirmAllowance(request) else { return false }
            if confirmation.isNew {
                activateBeforeFeedAllowance(until: confirmation.endsAt, now: request.now)
            }
            return true
        case .completeMorningGateResetAt(let now):
            completeMorningGateReset(now: now)
            return false
        }

        }
    }

    func confirmJointBeforeFeedAllowance(_ request: MoriBeforeFeedAllowanceRequest, host: ProtectionHost,
                                       ticket: ProtectionBreathTicket, completed: Bool) -> Bool {
        guard MoriProtectionIntegration.isEligible else { return false }
        var openedEnd: Date?
        let opened = (try? MoriShieldCoordination.exclusive {
            try MoriJointAllowanceJournal.recover(host: host, authorized: isAuthorized) { try MoriProtectionIntegration.repairExistingContributionAcknowledged() }
            let journal = try MoriJointAllowanceJournal(request: request)
            var confirmation: MoriBeforeFeedAllowanceConfirmation?
            let partner = MoriJointAllowancePartner(commit: {
                guard let saved = self.beforeFeedGateStore.confirmAllowance(request) else { throw ProtectionHostError.independentRestriction }
                confirmation = saved
                if saved.isNew { self.activateBeforeFeedAllowance(until: saved.endsAt, now: request.now, presentationEffects: false) }
                if self.beforeFeedGateStore.nativeGateEnabled() && self.hasEffectiveSelection(for: .beforeFeed) && self.lastScheduledBeforeFeedGraceUntil != saved.endsAt {
                    throw ProtectionHostError.registrationFailed
                }
            }, open: {
                guard let saved = confirmation else { return false }
                return self.beforeFeedGateStore.jointAllowanceIsCurrent(eventID: request.eventID,
                    historyGeneration: request.historyGeneration, end: saved.endsAt)
            }, compensate: {
                // Use durable ownership even if commit returned no receipt after
                // a partial write; never infer no mutation from confirmation=nil.
                try journal.compensatePartner { try MoriProtectionIntegration.repairExistingContributionAcknowledged() }
            })
            let success = ProtectionJointAllowance.confirm(host: host, ticket: ticket, completed: completed,
                seconds: request.openWindowSeconds, authorized: isAuthorized, partner: partner, journal: journal)
            if success { openedEnd = confirmation?.endsAt }
            return success
        }) ?? false
        if opened, let end = openedEnd, beforeFeedGateStore.graceUntil() == end {
            MoriBeforeFeedWindowLiveActivityController.start(until: end, now: request.now)
            beforeFeedWindowEndNotificationScheduler.scheduleIfPermitted(at: end, now: request.now)
        }
        return opened
    }

    private func requestAuthorization() async {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            lastErrorMessage = nil
            handleAuthorizationStatusChange(authorizationCenter.authorizationStatus)
        } catch {
            lastErrorMessage = "Screen Time permission was not granted."
        }
    }

    func resetAllProtectionData() {
        return MoriShieldCoordination.legacy(fallback: ()) {
        MoriProtectionIntegration.deleteProtectionData()

        beforeFeedReapplyTask?.cancel()
        beforeFeedReapplyTask = nil
        beforeFeedWindowEndNotificationScheduler.cancel()
        monitoringCoordinator.stopAll()
        clearShield()
        activeSession = nil
        activeSessionStore.clear()
        selectionCoordinator.clearAll()
        lastScheduledBeforeFeedGraceUntil = nil
        lastErrorMessage = nil
        refreshSelectionState()

        }
    }

    private func setDailyThresholdMinutes(_ minutes: Int) {
        dailyThresholdMinutes = minutes
    }

    func selectionDraft(for target: AttentionShieldSelectionTarget) -> AttentionShieldSelectionDraft {
        selectionCoordinator.selectionDraft(for: target)
    }

    private func commitSelectionDraft(_ draft: AttentionShieldSelectionDraft) {
        let target = selectionCoordinator.commitSelectionDraft(
            draft,
            authorizationStatus: authorizationStatus
        )
        handleSelectionChange(for: target)
        Task { await refreshDisplayNames(for: target) }
    }

    private func setFeatureEnabled(_ isEnabled: Bool, for feature: MoriScreenTimeFeature) {
        selectionCoordinator.updateProfile(for: feature) { profile in
            profile.isEnabled = isEnabled
        }
        handleFeatureProfileChange(for: feature)
    }

    private func setFeatureUsesDefaultSelection(_ usesDefaultSelection: Bool, for feature: MoriScreenTimeFeature) {
        selectionCoordinator.updateProfile(for: feature) { profile in
            profile.isEnabled = true
            profile.usesDefaultSelection = feature == .walkOfflineReset
                ? false
                : usesDefaultSelection
        }
        handleFeatureProfileChange(for: feature)
    }

    private func hasEffectiveSelection(for feature: MoriScreenTimeFeature) -> Bool {
        isAuthorized && selectionCoordinator.hasEffectiveSelection(for: feature)
    }

    private func startShield(
        feature: MoriScreenTimeFeature,
        endDate: Date,
        endPolicy: MoriScreenTimeSessionEndPolicy = .timed,
        now: Date = Date()
    ) {
        let clearedExpiredSession = clearExpiredActiveSessionIfNeeded(now: now)
        guard endDate > now else {
            if clearedExpiredSession {
                refreshScreenTimeGates()
            }
            return
        }

        guard hasEffectiveSelection(for: feature) else { return }
        if feature == .beforeFeed,
           let activeSession,
           !activeSession.isExpired(at: now),
           activeSession.feature != .beforeFeed {
            return
        }

        if let activeSession, activeSession.feature != feature {
            clearShieldAndActiveSession(clearStoredSession: true)
        }

        let session = activeSessionStore.startSession(
            feature: feature,
            endDate: endDate,
            endPolicy: endPolicy,
            now: now
        )
        activeSession = session
        applyShield(for: session)
        scheduleActiveSessionMonitoring(for: session)
    }

    @discardableResult
    private func startTimedShieldIfPossible(
        feature: MoriScreenTimeFeature,
        remainingSeconds: Int,
        now: Date = Date()
    ) -> Bool {
        startTimedShieldIfPossible(
            feature: feature,
            duration: TimeInterval(max(1, remainingSeconds)),
            now: now
        )
    }

    @discardableResult
    private func startTimedShieldIfPossible(
        feature: MoriScreenTimeFeature,
        duration: TimeInterval,
        now: Date = Date()
    ) -> Bool {
        let endDate = now.addingTimeInterval(max(1, duration))
        startShield(feature: feature, endDate: endDate, now: now)
        return activeSession?.feature == feature && activeSession?.isExpired(at: now) == false
    }

    @discardableResult
    private func startManualShieldIfPossible(
        feature: MoriScreenTimeFeature,
        now: Date = Date()
    ) -> Bool {
        startShield(
            feature: feature,
            endDate: .distantFuture,
            endPolicy: .manual,
            now: now
        )
        return activeSession?.feature == feature && activeSession?.endPolicy == .manual
    }

    @discardableResult
    private func beginResetProtection(
        feature: MoriScreenTimeFeature,
        remainingSeconds: Int,
        usesNativeBeforeFeedGate: Bool = true,
        now: Date = Date()
    ) -> Bool {
        guard hasEffectiveSelection(for: feature) else { return false }

        if feature == .beforeFeed, usesNativeBeforeFeedGate {
            return beginBeforeFeedResetProtection(now: now)
        }

        if feature == .morningGate, MorningGate.shouldApplyShield(now: now) {
            return beginMorningGateResetProtection(now: now)
        }

        return startTimedShieldIfPossible(
            feature: feature,
            remainingSeconds: remainingSeconds,
            now: now
        )
    }

    private func endResetProtectionIfNeeded(feature: MoriScreenTimeFeature) {
        if activeSession?.feature == feature {
            endShield(feature: feature)
            return
        }

        refreshPassiveGates(for: feature)
    }

    private func endShield(feature: MoriScreenTimeFeature? = nil) {
        guard feature == nil || activeSession?.feature == feature else { return }
        clearActiveShieldSession()
    }

    private func reconcileProtectionState() {
        MoriProtectionIntegration.foreground()
        if MoriShieldCoordination.scheduledOwnsMorning, activeSession?.feature == .morningGate {
            activeSession = nil
            if activeSessionStore.load()?.feature == .morningGate { activeSessionStore.clear() }
            stopActiveSessionMonitoring()
        }
        return MoriShieldCoordination.legacy(fallback: ()) {

        restoreActiveShieldIfNeeded()
        scheduleDailyThresholdMonitoring()
        if activeSession != nil {
            refreshScreenTimeGates()
        }

        }
    }

    private func restoreActiveShieldIfNeeded() {
        return MoriShieldCoordination.legacy(fallback: ()) {

        guard let session = activeSessionStore.loadUnexpiredSession() else {
            activeSession = nil
            stopActiveSessionMonitoring()
            reconcilePassiveGatesOnForeground()
            return
        }

        activeSession = session
        if hasEffectiveSelection(for: session.feature) {
            applyShield(for: session)
            scheduleActiveSessionMonitoring(for: session)
        } else {
            clearShieldAndActiveSession(clearStoredSession: true)
        }

        }
    }

    private func refreshScreenTimeGates() {
        return MoriShieldCoordination.legacy(fallback: ()) {

        scheduleBeforeFeedGateReapplyIfNeeded()
        scheduleMorningGateMonitoring()
        refreshPassiveGateShield()

        }
    }

    private func reconcilePassiveGatesOnForeground() {
        return MoriShieldCoordination.legacy(fallback: ()) {

        scheduleBeforeFeedGateReapplyIfNeeded()
        scheduleMorningGateMonitoring()

        let action = passiveGatePolicy.refreshAction
        let desiredStateMatches = selectionCoordinator.passiveGateActionMatchesCurrentState(
            action,
            shieldApplier: shieldApplier,
            authorizationStatus: authorizationStatus
        )
        guard AttentionShieldForegroundReconcilePolicy.shouldRefresh(
            action: action,
            desiredStateMatches: desiredStateMatches
        ) else {
            return
        }

        selectionCoordinator.applyPassiveGateAction(
            action,
            shieldApplier: shieldApplier,
            authorizationStatus: authorizationStatus
        )

        }
    }

    @discardableResult
    private func beginBeforeFeedResetProtection(now: Date = Date()) -> Bool {
        // Reentry is a choice, not permission to revoke a previously granted window.
        guard !beforeFeedGateStore.isInGraceWindow(now: now) else { return false }
        beforeFeedWindowEndNotificationScheduler.cancel()
        beforeFeedGateStore.clearGraceUntil()
        MoriBeforeFeedWindowLiveActivityController.endAll()
        refreshBeforeFeedGateShield()

        if let activeSession, !activeSession.isExpired(at: now) {
            return activeSession.feature == .beforeFeed
        }
        return passiveGatePolicy.shouldApplyBeforeFeedGate
    }

    private func activateBeforeFeedAllowance(until authoritativeUntil: Date, now: Date, presentationEffects: Bool = true) {
        let traceID = beforeFeedGateStore.beginWindowTrace()
        if activeSession?.feature == .beforeFeed {
            clearActiveShieldSession()
        } else {
            refreshBeforeFeedGateShield()
        }
        recordBeforeFeedHealthEvent(
            kind: .beforeFeedGraceSaved,
            action: "completeBeforeFeedReset",
            traceID: traceID,
            graceUntil: authoritativeUntil,
            policy: .clear
        )
        guard presentationEffects else { return }
        MoriBeforeFeedWindowLiveActivityController.start(until: authoritativeUntil, now: now)
        beforeFeedWindowEndNotificationScheduler.scheduleIfPermitted(
            at: authoritativeUntil,
            now: now
        )
    }

    @discardableResult
    private func beginMorningGateResetProtection(now: Date = Date()) -> Bool {
        if MoriShieldCoordination.scheduledOwnsMorning { return MoriProtectionIntegration.breathingHost() != nil }
        guard MorningGate.shouldApplyShield(now: now) else { return false }

        refreshMorningGateShield()
        if let activeSession, !activeSession.isExpired(at: now) {
            return activeSession.feature == .morningGate
        }
        return passiveGatePolicy.shouldApplyMorningGate
    }

    private func completeMorningGateReset(now: Date = Date()) {
        guard !MoriShieldCoordination.scheduledOwnsMorning else { return }
        MorningGate.completeResetForActiveWindow(now: now)
        if activeSession?.feature == .morningGate {
            clearActiveShieldSession()
            return
        }
        refreshMorningGateShield()
    }

    private func refreshBeforeFeedGateShield() {
        refreshPassiveGateShield()
        scheduleBeforeFeedGateReapplyIfNeeded()
    }

    private func refreshMorningGateShield() {
        scheduleMorningGateMonitoring()
        refreshPassiveGateShield()
    }

    private func scheduleMorningGateMonitoring() {
        applyMonitoringOutcome(
            monitoringCoordinator.scheduleMorningGate(
                isAuthorized: isAuthorized,
                isEnabled: MorningGate.isEnabled && !MoriShieldCoordination.scheduledOwnsMorning,
                hasSelection: selectionCoordinator.hasEffectiveSelection(for: .morningGate)
            )
        )
    }

    private func scheduleDailyThresholdMonitoring() {
        applyMonitoringOutcome(
            monitoringCoordinator.scheduleDailyThreshold(
                isAuthorized: isAuthorized,
                hasSelection: selectionCoordinator.hasDefaultSelection,
                thresholdMinutes: dailyThresholdMinutes
            ) {
                selectionCoordinator.defaultSelectionForMonitoring()
            }
        )
    }

    private func applyMonitoringOutcome(_ outcome: AttentionShieldMonitoringOutcome) {
        switch outcome {
        case .noChange:
            break
        case .scheduled:
            lastErrorMessage = nil
        case .failed(let message):
            lastErrorMessage = message
        }
    }

    private func applyShield(for session: MoriScreenTimeActiveSession) {
        applyShield(for: session.feature)
    }

    private func applyShield(for feature: MoriScreenTimeFeature) {
        if feature == .morningGate && MoriShieldCoordination.scheduledOwnsMorning {
            if activeSession?.feature == .morningGate { activeSession = nil }
            if activeSessionStore.load()?.feature == .morningGate { activeSessionStore.clear() }
            refreshPassiveGateShield()
            return
        }
        let payload = selectionCoordinator.shieldPayload(
            for: feature,
            authorizationStatus: authorizationStatus
        )
        let desiredStateMatches = shieldApplier.matchesAppliedState(
            selection: payload.selection,
            currentFeature: feature,
            restrictionPolicy: payload.restrictionPolicy
        )
        AttentionShieldStateReconcilePolicy.applyIfNeeded(
            desiredStateMatches: desiredStateMatches
        ) {
            shieldApplier.apply(
                selection: payload.selection,
                currentFeature: feature,
                displayNames: payload.displayNames,
                restrictionPolicy: payload.restrictionPolicy
            )
        }
    }

    private var passiveGatePolicy: AttentionShieldPassiveGatePolicy {
        AttentionShieldPassiveGatePolicy(
            morningGateShouldApply: MorningGate.shouldApplyShield(),
            morningGateHasSelection: hasEffectiveSelection(for: .morningGate),
            beforeFeedGateEnabled: BeforeFeedGate.isNativeGateEnabled,
            beforeFeedInGraceWindow: BeforeFeedGate.isInGraceWindow,
            beforeFeedHasSelection: hasEffectiveSelection(for: .beforeFeed)
        )
    }

    private func refreshPassiveGateShield() {
        return MoriShieldCoordination.legacy(fallback: ()) {

        let now = Date()
        let action = passiveGatePolicy.refreshAction(activeSession: activeSession, now: now)
        if activeSession?.isExpired(at: now) == true {
            clearExpiredActiveSessionIfNeeded(now: now)
        }
        selectionCoordinator.applyPassiveGateAction(
            action,
            shieldApplier: shieldApplier,
            authorizationStatus: authorizationStatus
        )

        }
    }

    private func scheduleBeforeFeedGateReapplyIfNeeded() {
        beforeFeedReapplyTask?.cancel()
        beforeFeedReapplyTask = nil

        let now = Date()
        if reconcileExpiredBeforeFeedGraceIfNeeded(now: now) {
            return
        }

        guard beforeFeedGateStore.nativeGateEnabled() else {
            MoriBeforeFeedWindowLiveActivityController.endAll()
            stopBeforeFeedGraceMonitoring(action: "nativeGateDisabled")
            return
        }

        guard let expectedGraceUntil = beforeFeedGateStore.graceUntil(now: now) else {
            MoriBeforeFeedWindowLiveActivityController.endAll()
            monitoringCoordinator.stopBeforeFeedGrace()
            lastScheduledBeforeFeedGraceUntil = nil
            return
        }

        let delay = expectedGraceUntil.timeIntervalSince(now)
        guard delay > 1 else {
            beforeFeedGateStore.clearGraceUntil()
            MoriBeforeFeedWindowLiveActivityController.endAll()
            stopBeforeFeedGraceMonitoring(action: "nearExpiredGrace")
            recordBeforeFeedHealthEvent(
                kind: .beforeFeedGraceExpired,
                action: "nearExpiredGraceReconcile",
                policy: MoriScreenTimeMonitorHealthPolicy.none
            )
            return
        }

        scheduleBeforeFeedReapplyMonitoring()

        beforeFeedReapplyTask = Task { [weak self] in
            let nanoseconds = UInt64(min(delay, TimeInterval(Int.max)) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            // This Task inherits the manager's MainActor isolation. Check and
            // act together after suspension; never end a replacement window.
            guard !Task.isCancelled, let self,
                  self.beforeFeedGateStore.shouldReapplyExpiredAllowance(endsAt: expectedGraceUntil)
            else { return }
            MoriBeforeFeedWindowLiveActivityController.endAll()
            self.refreshBeforeFeedGateShield()
        }
    }

    @discardableResult
    private func scheduleBeforeFeedReapplyMonitoring() -> AttentionShieldMonitoringOutcome {
        let graceUntil = beforeFeedGateStore.graceUntil()
        // Idempotent: avoid tearing down and re-registering an already-valid
        // `.moriBeforeFeedGrace` schedule. Repeated stop/start cycles (triggered by
        // every refreshScreenTimeGates() call during the grace window) cause iOS to
        // drop the terminal intervalDidEnd callback, so the re-lock never fires.
        if let graceUntil, graceUntil == lastScheduledBeforeFeedGraceUntil {
            return .noChange
        }

        let outcome = monitoringCoordinator.scheduleBeforeFeedGrace(
            isAuthorized: isAuthorized,
            graceUntil: graceUntil
        )
        applyMonitoringOutcome(outcome)
        if case .scheduled = outcome {
            lastScheduledBeforeFeedGraceUntil = graceUntil
        } else {
            lastScheduledBeforeFeedGraceUntil = nil
        }
        return outcome
    }

    @discardableResult
    private func reconcileExpiredBeforeFeedGraceIfNeeded(now: Date = Date()) -> Bool {
        guard beforeFeedGateStore.clearExpiredGraceIfNeeded(now: now) else {
            return false
        }

        MoriBeforeFeedWindowLiveActivityController.endAll()
        stopBeforeFeedGraceMonitoring(action: "foregroundExpiredGrace")
        recordBeforeFeedHealthEvent(
            kind: .beforeFeedForegroundReconcile,
            action: "foregroundExpiredGraceReconcile",
            policy: MoriScreenTimeMonitorHealthPolicy.none
        )
        recordBeforeFeedHealthEvent(
            kind: .beforeFeedGraceExpired,
            action: "foregroundExpiredGraceReconcile",
            policy: MoriScreenTimeMonitorHealthPolicy.none
        )
        return true
    }

    private func recordBeforeFeedHealthEvent(
        kind: MoriScreenTimeMonitorHealthEventKind,
        action: String,
        traceID: String? = nil,
        graceUntil: Date? = nil,
        policy: MoriScreenTimeMonitorHealthPolicy? = nil,
        message: String? = nil
    ) {
        let payload = selectionCoordinator.shieldPayload(
            for: .beforeFeed,
            authorizationStatus: authorizationStatus
        )
        MoriScreenTimeMonitorHealthStore.record(
            MoriScreenTimeMonitorHealthEvent(
                traceID: traceID ?? beforeFeedGateStore.currentWindowTraceID(),
                kind: kind,
                featureRawValue: MoriScreenTimeFeature.beforeFeed.rawValue,
                activeSessionFeatureRawValue: activeSession?.feature.rawValue,
                action: action,
                policy: policy,
                message: message,
                graceUntil: graceUntil ?? beforeFeedGateStore.graceUntil(),
                beforeFeedNativeGateEnabled: beforeFeedGateStore.nativeGateEnabled(),
                beforeFeedInGraceWindow: beforeFeedGateStore.isInGraceWindow(),
                beforeFeedHasSelection: hasEffectiveSelection(for: .beforeFeed),
                applicationTokenCount: payload.selection.applicationTokens.count,
                webDomainTokenCount: payload.selection.webDomainTokens.count,
                displayNameCount: payload.displayNames.count,
                displayNames: payload.displayNames
            )
        )
    }

    private func scheduleActiveSessionMonitoring(for session: MoriScreenTimeActiveSession) {
        guard session.endPolicy == .timed else {
            stopActiveSessionMonitoring()
            return
        }
        applyMonitoringOutcome(
            monitoringCoordinator.scheduleActiveSession(
                isAuthorized: isAuthorized,
                endDate: session.endDate
            )
        )
    }

    private func stopActiveSessionMonitoring() {
        monitoringCoordinator.stopActiveSession()
    }

    private func stopBeforeFeedGraceMonitoring(action: String = "stop") {
        monitoringCoordinator.stopBeforeFeedGrace()
        recordBeforeFeedHealthEvent(
            kind: .beforeFeedGraceScheduleStopped,
            action: action,
            policy: MoriScreenTimeMonitorHealthPolicy.none
        )
        lastScheduledBeforeFeedGraceUntil = nil
    }

    private func clearShield() {
        shieldApplier.clear()
    }

    private func clearActiveShieldSession() {
        clearShieldAndActiveSession(clearStoredSession: true)
    }

    private func clearShieldAndActiveSession(clearStoredSession: Bool) {
        return MoriShieldCoordination.legacy(fallback: ()) {

        clearShield()
        clearActiveSessionState(clearStoredSession: clearStoredSession, refreshGates: true)

        }
    }

    @discardableResult
    private func clearExpiredActiveSessionIfNeeded(now: Date = Date()) -> Bool {
        guard let activeSession,
              activeSession.isExpired(at: now)
        else {
            return false
        }

        clearShield()
        clearActiveSessionState(clearStoredSession: true, refreshGates: false)
        return true
    }

    private func clearActiveSessionState(clearStoredSession: Bool, refreshGates: Bool) {
        return MoriShieldCoordination.legacy(fallback: ()) {

        activeSession = nil
        if clearStoredSession {
            activeSessionStore.clear()
        }
        stopActiveSessionMonitoring()
        if refreshGates {
            refreshScreenTimeGates()
        }

        }
    }

    private func currentActiveSession(for feature: MoriScreenTimeFeature) -> MoriScreenTimeActiveSession? {
        guard let activeSession,
              activeSession.feature == feature,
              !activeSession.isExpired
        else {
            return nil
        }
        return activeSession
    }

    private func handleSelectionChange(for target: AttentionShieldSelectionTarget) {
        switch target {
        case .defaultList:
            handleDefaultSelectionChange()
        case .feature(let feature):
            handleFeatureProfileChange(for: feature)
        }
    }

    private func handleDefaultSelectionChange() {
        refreshSelectionState()
        scheduleDailyThresholdMonitoring()
        reapplyActiveShieldIfNeeded()
        refreshScreenTimeGates()
    }

    private func handleFeatureProfileChange(for feature: MoriScreenTimeFeature) {
        refreshSelectionState()
        reapplyOrEndActiveShieldIfNeeded(for: feature)
        refreshPassiveGates(for: feature)
    }

    private func handleAuthorizationStatusChange(_ status: AuthorizationStatus) {
        return MoriShieldCoordination.legacy(fallback: ()) {

        authorizationStatus = status
        refreshSelectionState()
        reconcileProtectionState()

        }
    }

    private func reapplyActiveShieldIfNeeded() {
        guard let activeSession, !activeSession.isExpired else { return }
        applyShield(for: activeSession)
    }

    private func reapplyOrEndActiveShieldIfNeeded(for feature: MoriScreenTimeFeature) {
        guard let session = currentActiveSession(for: feature) else { return }
        if hasEffectiveSelection(for: feature) {
            applyShield(for: session)
        } else {
            endShield(feature: feature)
        }
    }

    private func refreshPassiveGates(for feature: MoriScreenTimeFeature) {
        if feature == .beforeFeed {
            refreshBeforeFeedGateShield()
        }

        if feature == .morningGate {
            refreshMorningGateShield()
        }
    }

    private func refreshSelectionState() {
        defaultSelectedCount = selectionCoordinator.defaultSelectedCount
        profileSummaries = selectionCoordinator.profileSummaries(authorizationStatus: authorizationStatus)
    }

    private func refreshDisplayNames(for target: AttentionShieldSelectionTarget) async {
        await selectionCoordinator.refreshDisplayNames(
            for: target,
            authorizationStatus: authorizationStatus
        )
        refreshSelectionState()
    }
}

typealias AppLimitManager = AttentionShieldManager

#if canImport(ActivityKit) && os(iOS)
@MainActor
private enum MoriBeforeFeedWindowLiveActivityController {
    private static var generation = UUID()
    private static var expiryTask: Task<Void, Never>?
    private static var endingIDs = Set<String>()

    static func start(until endsAt: Date, now: Date = Date()) {
        guard #available(iOS 16.2, *),
              ActivityAuthorizationInfo().areActivitiesEnabled,
              endsAt > now else { return }
        generation = UUID()
        let requestGeneration = generation
        expiryTask?.cancel()
        // Capture before suspension: an old request must never end a new session.
        let previousActivities = Activity<MoriBeforeFeedWindowAttributes>.activities
        Task {
            for activity in previousActivities {
                await end(activity, now: Date(), immediately: true)
            }
            guard generation == requestGeneration, endsAt > Date() else { return }
            let state = MoriBeforeFeedWindowAttributes.ContentState(
                startedAt: now,
                endsAt: endsAt,
                durationSeconds: max(1, Int(ceil(endsAt.timeIntervalSince(now))))
            )
            guard let activity = try? Activity.request(
                attributes: MoriBeforeFeedWindowAttributes(title: "Feed window"),
                content: ActivityContent(state: state, staleDate: endsAt, relevanceScore: 1),
                pushType: nil
            ) else { return }
            expiryTask = Task {
                let delay = max(0, endsAt.timeIntervalSince(Date()))
                do {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } catch { return }
                guard !Task.isCancelled, generation == requestGeneration else { return }
                await end(activity, now: Date())
            }
        }
    }

    static func endAll() {
        guard #available(iOS 16.2, *) else { return }
        generation = UUID()
        expiryTask?.cancel()
        expiryTask = nil
        let activities = Activity<MoriBeforeFeedWindowAttributes>.activities
        let endedAt = Date()
        Task {
            for activity in activities {
                await end(activity, now: endedAt)
            }
        }
    }

    @available(iOS 16.2, *)
    private static func end(
        _ activity: Activity<MoriBeforeFeedWindowAttributes>,
        now: Date,
        immediately: Bool = false
    ) async {
        guard activity.activityState == .active || activity.activityState == .stale,
              endingIDs.insert(activity.id).inserted else { return }
        defer { endingIDs.remove(activity.id) }
        let previousState = activity.content.state
        let state = previousState.completed(at: now)
        // ActivityKit owns dismissal after end, even if Mori is subsequently suspended.
        // staleDate / the countdown alone cannot end a still-running activity.
        await activity.end(
            ActivityContent(state: state, staleDate: nil, relevanceScore: 0),
            dismissalPolicy: immediately ? .immediate : .after(MoriBeforeFeedWindowAttributes.ContentState.dismissalDate(endedAt: now))
        )
    }
}
#else
@MainActor
private enum MoriBeforeFeedWindowLiveActivityController {
    static func start(until endsAt: Date, now: Date = Date()) {}
    static func endAll() {}
}
#endif
