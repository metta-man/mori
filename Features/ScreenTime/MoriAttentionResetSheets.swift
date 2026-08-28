import SwiftUI

struct MoriBeforeFeedResetSheet: View {
    let durationSeconds: Int
    let routeSource: MoriAppRouteSource?

    init(durationSeconds: Int, routeSource: MoriAppRouteSource? = nil) {
        self.durationSeconds = durationSeconds
        self.routeSource = routeSource
    }

    var body: some View {
        MoriAttentionResetSheet(
            context: .beforeFeed,
            durationSeconds: durationSeconds,
            routeSource: routeSource
        )
    }
}

struct MoriMorningResetSheet: View {
    let durationSeconds: Int
    let routeSource: MoriAppRouteSource?

    init(durationSeconds: Int, routeSource: MoriAppRouteSource? = nil) {
        self.durationSeconds = durationSeconds
        self.routeSource = routeSource
    }

    var body: some View {
        MoriAttentionResetSheet(
            context: .morningGate,
            durationSeconds: durationSeconds,
            routeSource: routeSource
        )
    }
}

private struct MoriAttentionResetSheet: View {
    let context: MoriAttentionResetContext
    let durationSeconds: Int
    let routeSource: MoriAppRouteSource?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var clarityStore = MoriClarityStore.shared
    @StateObject private var appLimitManager = AppLimitManager.shared
    @AppStorage(
        MoriScreenTimeShared.beforeFeedNativeGateEnabledKey,
        store: MoriAppGroup.defaults
    ) private var nativeGateEnabled: Bool = MoriScreenTimeShared.defaultBeforeFeedNativeGateEnabled
    @AppStorage(
        MoriScreenTimeShared.morningGateBreathingTechniqueIDKey,
        store: MoriAppGroup.defaults
    ) private var morningGateBreathingTechniqueID: String = MoriScreenTimeShared.defaultMorningGateBreathingTechniqueID
    @AppStorage("mori_settle_sound_enabled") private var soundEnabled: Bool = true
    @AppStorage("mori_settle_breathing_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("mori_settle_breathing_custom_inhale") private var customInhaleSeconds: Double = 4
    @AppStorage("mori_settle_breathing_custom_hold") private var customHoldSeconds: Double = 0
    @AppStorage("mori_settle_breathing_custom_exhale") private var customExhaleSeconds: Double = 6
    @AppStorage("mori_settle_breathing_custom_uses_hold") private var customUsesHold: Bool = false
    @State private var secondsRemaining = 0
    @State private var activeElapsed: TimeInterval = 0
    @State private var resetStartDate: Date?
    @State private var pausedAt: Date?
    @State private var totalPausedDuration: TimeInterval = 0
    @State private var isRunning = false
    @State private var appLimitWasActive = false
    @State private var currentPhaseIndex = 0
    @State private var cueCoordinator = MoriAttentionResetCueCoordinator()
    @State private var beforeFeedFlow = MoriBeforeFeedFlowState()
    @State private var beforeFeedPauseStyle: MoriBeforeFeedPauseStyle = .guidedBreathing
    @State private var beforeFeedGuidedCycleCount = MoriBeforeFeedPausePreferences.defaultGuidedCycleCount
    @State private var beforeFeedTechniqueIDSnapshot = MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
    @State private var beforeFeedPatternSnapshot: MoriBreathPattern?
    @State private var beforeFeedPauseDurationSnapshot = 30
    @State private var beforeFeedPauseTargetDurationSnapshot: TimeInterval = 30
    @State private var forceReturnAnchorsForUITest = false
    @State private var beforeFeedIntentEventID = UUID()
    @State private var didConfirmBeforeFeedIntent = false

    private let beforeFeedGateStore = BeforeFeedGateStore()
    private let beforeFeedPausePreferences = MoriBeforeFeedPausePreferences()

    private var totalSeconds: Int {
        switch context {
        case .beforeFeed:
            return max(1, beforeFeedPauseDurationSnapshot)
        case .morningGate:
            return max(5 * 60, durationSeconds)
        }
    }

    private var targetDuration: TimeInterval {
        switch context {
        case .beforeFeed:
            return max(1, beforeFeedPauseTargetDurationSnapshot)
        case .morningGate:
            return TimeInterval(totalSeconds)
        }
    }

    private var sessionRemaining: TimeInterval {
        max(0, targetDuration - activeElapsed)
    }

    private var progress: CGFloat {
        CGFloat(min(1, max(0, activeElapsed / TimeInterval(max(1, totalSeconds)))))
    }

    private var elapsedTime: TimeInterval {
        min(TimeInterval(totalSeconds), max(0, activeElapsed))
    }

    private var breathingState: MoriAttentionResetBreathingState {
        MoriAttentionResetBreathingState(
            context: context,
            beforeFeedTechniqueID: beforeFeedTechniqueIDSnapshot,
            morningGateTechniqueID: morningGateBreathingTechniqueID,
            customInhaleSeconds: customInhaleSeconds,
            customHoldSeconds: customHoldSeconds,
            customExhaleSeconds: customExhaleSeconds,
            customUsesHold: customUsesHold,
            isRunning: isRunning,
            isComplete: secondsRemaining == 0,
            elapsedTime: elapsedTime
        )
    }

    private var activeBreathingSegments: [MoriBreathingCycleSegment] {
        if context == .beforeFeed {
            return beforeFeedPauseStyle == .guidedBreathing
                ? (beforeFeedPatternSnapshot?.segments ?? [])
                : []
        }
        return breathingState.segments
    }

    private var activeBreathingVisualState: MoriBreathingCycleVisualState {
        guard isRunning, !activeBreathingSegments.isEmpty else { return .idle }
        return MoriBreathingCycle.visualState(
            for: activeBreathingSegments,
            elapsedTime: elapsedTime
        )
    }

    private var activeBreathingPhaseRemaining: TimeInterval {
        MoriBreathingCycle.phaseRemaining(
            for: activeBreathingSegments,
            elapsedTime: elapsedTime
        )
    }

    private var resetDurationText: String {
        switch context {
        case .beforeFeed:
            return BeforeFeedGate.formattedDuration(totalSeconds)
        case .morningGate:
            return MorningGate.formattedDuration(totalSeconds)
        }
    }

    private var timeText: String {
        let minutes = max(0, secondsRemaining) / 60
        let seconds = max(0, secondsRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var limitText: String {
        switch context {
        case .beforeFeed:
            switch routeSource {
            case .screenTimeGate?:
                return MoriL10n.display("Screen Time prepared this reset from the blocked feed app.")
            case .shortcut?:
                return MoriL10n.display("Shortcut opened Mori; iOS will not return to the feed automatically.")
            default:
                return nativeGateEnabled
                    ? MoriL10n.display("Selected feed apps stay limited until this completes.")
                    : MoriL10n.display("Selected apps stay limited during this reset.")
            }
        case .morningGate:
            return MoriL10n.display("Selected morning apps stay limited until this reset completes or the window ends.")
        }
    }

    private var openWindowText: String {
        switch context {
        case .beforeFeed:
            return MoriL10n.display("Choose the feed window each time you pause.")
        case .morningGate:
            return MoriL10n.display("Completion opens selected apps for today's morning window.")
        }
    }

    private var beforeFeedSecondaryContext: String? {
        switch routeSource {
        case .screenTimeGate?:
            return MoriL10n.display("Screen Time opened this pause. Return to the feed yourself after continuing.")
        case .shortcut?:
            return MoriL10n.display("A shortcut opened Mori. Return to the feed yourself after continuing.")
        default:
            return nil
        }
    }

    private var beforeFeedEnoughChoices: [MoriBeforeFeedEnoughChoice] {
        guard let reason = beforeFeedFlow.reason else { return [] }
        return MoriBeforeFeedEnoughChoice.choices(for: reason)
    }

    private var shouldShowReturnAnchors: Bool {
        guard let reason = beforeFeedFlow.reason else { return false }
        return forceReturnAnchorsForUITest || MoriBeforeFeedAdaptivePolicy.shouldShowReturnAnchors(
            reason: reason,
            recentIntentEvents: beforeFeedGateStore.intentEvents()
        )
    }

    private var beforeFeedBeginTitle: String {
        switch beforeFeedPauseStyle {
        case .guidedBreathing:
            return MoriL10n.string(
                "before_feed.plan.begin_breaths",
                defaultValue: "Begin %d breaths",
                arguments: [beforeFeedGuidedCycleCount]
            )
        case .quietPause:
            return MoriL10n.string(
                "before_feed.plan.begin_quiet_seconds",
                defaultValue: "Begin %d-second pause",
                arguments: [beforeFeedPauseDurationSnapshot]
            )
        }
    }

    private var beforeFeedConfiguredPauseText: String {
        switch beforeFeedPauseStyle {
        case .guidedBreathing:
            let techniqueName = MoriBreathingTechniqueRepository.getTechnique(
                id: beforeFeedTechniqueIDSnapshot
            )?.name ?? MoriL10n.display("Guided breathing")
            return MoriL10n.string(
                "before_feed.pause.guided_summary",
                defaultValue: "%@ · %d breaths",
                arguments: [techniqueName, beforeFeedGuidedCycleCount]
            )
        case .quietPause:
            return MoriL10n.string(
                "before_feed.pause.quiet_summary",
                defaultValue: "%d-second quiet pause",
                arguments: [beforeFeedPauseDurationSnapshot]
            )
        }
    }

    private var beforeFeedGuidedProgressText: String {
        guard beforeFeedPauseStyle == .guidedBreathing,
              let pattern = beforeFeedPatternSnapshot,
              pattern.totalCycleDuration > 0
        else {
            return MoriL10n.display("Guided breathing")
        }

        let completedCycles = Int(floor(activeElapsed / pattern.totalCycleDuration))
        let currentCycle = min(beforeFeedGuidedCycleCount, max(1, completedCycles + 1))
        return MoriL10n.string(
            "before_feed.pause.round_progress",
            defaultValue: "Round %d of %d",
            arguments: [currentCycle, beforeFeedGuidedCycleCount]
        )
    }

    private var beforeFeedOpenActionTitle: String {
        let seconds = beforeFeedFlow.confirmedOpenWindowSeconds
            ?? beforeFeedFlow.enoughChoice?.openWindowSeconds
            ?? (5 * 60)
        if seconds.isMultiple(of: 60) {
            return MoriL10n.string(
                "before_feed.completion.open_minutes",
                defaultValue: "Open a %d-minute window",
                arguments: [seconds / 60]
            )
        }
        return MoriL10n.string(
            "before_feed.completion.open_window",
            defaultValue: "Open a %@ window",
            arguments: [BeforeFeedGate.formattedDuration(seconds)]
        )
    }

    private var beforeFeedLeaveActionTitle: String {
        guard let anchor = beforeFeedFlow.returnAnchor else {
            return MoriL10n.display("Leave feed closed")
        }
        return MoriL10n.string(
            "before_feed.completion.return_now",
            defaultValue: "Return to %@ now",
            arguments: [anchor.displayTitle.lowercased()]
        )
    }

    private var beforeFeedBreathingCueText: String {
        if secondsRemaining == 0 {
            return MoriL10n.display("Pause complete")
        }
        if isRunning, !activeBreathingSegments.isEmpty {
            return activeBreathingVisualState.label
        }
        if beforeFeedFlow.stage == .pause, activeElapsed > 0 {
            return MoriL10n.display("Paused")
        }
        return MoriL10n.display("Breathe at your own pace")
    }

    private var morningResetBreathingCueText: String {
        if !isRunning, activeElapsed > 0, secondsRemaining > 0 {
            return MoriL10n.display("Paused")
        }

        return breathingState.cueText
    }

    private var backgroundVariant: MoriBotanicalScreenBackdrop.Variant {
        switch context {
        case .beforeFeed:
            return beforeFeedFlow.stage == .pause ? .breath : .appLimit
        case .morningGate:
            return (isRunning || activeElapsed > 0) && secondsRemaining > 0
                ? .breath
                : .appLimit
        }
    }

    var body: some View {
        Color.clear
            .background {
                MoriAttentionResetSheetBackground(variant: backgroundVariant)
                    .ignoresSafeArea(edges: [.top, .bottom])
            }
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    MoriAttentionResetSheetHeader(
                        title: context.navigationTitle,
                        actionTitle: context == .beforeFeed
                            ? MoriL10n.display("Close")
                            : MoriL10n.display("Done"),
                        onDone: resetAndDismiss
                    )

                    resetContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .ignoresSafeArea(edges: .top)
            .moriAttentionResetLifecycle(
                soundEnabled: soundEnabled,
                onPrepare: prepareReset,
                onCleanup: cleanupReset,
                onTick: tick,
                onSoundEnabledChange: handleSoundEnabledChange
            )
            .moriOnChange(of: scenePhase) { newPhase in
                guard context == .beforeFeed,
                      beforeFeedFlow.stage == .pause,
                      isRunning,
                      newPhase != .active
                else {
                    return
                }
                pauseReset()
            }
    }

    @ViewBuilder
    private var resetContent: some View {
        switch context {
        case .beforeFeed:
            switch beforeFeedFlow.stage {
            case .reason:
                MoriBeforeFeedReasonContent(
                    selectedReason: beforeFeedFlow.reason,
                    secondaryContext: beforeFeedSecondaryContext,
                    onSelectReason: selectBeforeFeedReason,
                    onContinue: continueFromBeforeFeedReason
                )
            case .plan:
                if let reason = beforeFeedFlow.reason {
                    MoriBeforeFeedPlanContent(
                    selectedReason: reason,
                    enoughChoices: beforeFeedEnoughChoices,
                    selectedEnoughChoice: beforeFeedFlow.enoughChoice,
                    selectedReturnAnchor: beforeFeedFlow.returnAnchor,
                    showsReturnAnchors: shouldShowReturnAnchors,
                    beginTitle: beforeFeedBeginTitle,
                    secondaryContext: beforeFeedSecondaryContext,
                    onSelectEnoughChoice: selectBeforeFeedEnoughChoice,
                    onSelectReturnAnchor: selectBeforeFeedReturnAnchor,
                    onBeginPause: beginBeforeFeedPause,
                    onBack: returnToBeforeFeedReasons
                )
                }
            case .pause:
                MoriBeforeFeedPauseContent(
                    pauseStyle: beforeFeedPauseStyle,
                    breathingVisualState: activeBreathingVisualState,
                    isRunning: isRunning,
                    timeText: timeText,
                    cueText: beforeFeedBreathingCueText,
                    guidedProgressText: beforeFeedGuidedProgressText,
                    configuredPauseText: beforeFeedConfiguredPauseText,
                    secondaryContext: beforeFeedSecondaryContext,
                    onTogglePause: toggleResetRunning,
                    onBack: returnToBeforeFeedPlan
                )
            case .completion:
                if let reason = beforeFeedFlow.reason,
                   let enoughChoice = beforeFeedFlow.enoughChoice {
                    MoriBeforeFeedCompletionContent(
                        selectedReason: reason,
                        selectedEnoughChoice: enoughChoice,
                        selectedReturnAnchor: beforeFeedFlow.returnAnchor,
                        openActionTitle: beforeFeedOpenActionTitle,
                        leaveActionTitle: beforeFeedLeaveActionTitle,
                        secondaryContext: beforeFeedSecondaryContext,
                        onOpen: confirmBeforeFeedIntent,
                        onLeaveClosed: leaveFeedClosed,
                        onBack: returnToBeforeFeedPlan
                    )
                }
            }
        case .morningGate:
            MoriMorningResetContent(
                context: context,
                resetDurationText: resetDurationText,
                headerSubtitle: breathingState.headerSubtitle,
                showsBreathingOrb: breathingState.hasTechnique,
                breathingVisualState: activeBreathingVisualState,
                isRunning: isRunning,
                hasStarted: activeElapsed > 0,
                secondsRemaining: secondsRemaining,
                timeText: timeText,
                cueText: morningResetBreathingCueText,
                limitText: limitText,
                openWindowText: openWindowText,
                onPrimaryAction: toggleResetRunning,
                onReset: reset
            )
        }
    }

    private func prepareReset() {
        let arguments = ProcessInfo.processInfo.arguments
        prepareBeforeFeedPauseSnapshot(arguments: arguments)
        activeElapsed = 0
        secondsRemaining = totalSeconds
        resetStartDate = nil
        pausedAt = nil
        totalPausedDuration = 0

        guard context == .beforeFeed else { return }

        if arguments.contains("-MoriShowBeforeFeedCompletionForUITest") {
            beforeFeedFlow.selectReason(.learn)
            _ = beforeFeedFlow.proceedToPlan()
            _ = beforeFeedFlow.selectEnoughChoice(.fiveMinutes)
            beforeFeedFlow.selectReturnAnchor(.work)
            _ = beforeFeedFlow.beginPause()
            _ = beforeFeedFlow.completePause()
            activeElapsed = TimeInterval(totalSeconds)
            secondsRemaining = 0
            forceReturnAnchorsForUITest = true
        } else if arguments.contains("-MoriShowBeforeFeedPlanWithAnchorForUITest") {
            beforeFeedFlow.selectReason(.habit)
            _ = beforeFeedFlow.proceedToPlan()
            _ = beforeFeedFlow.selectEnoughChoice(.fiveMinutes)
            beforeFeedFlow.selectReturnAnchor(.work)
            forceReturnAnchorsForUITest = true
        } else if arguments.contains("-MoriShowBeforeFeedPlanForUITest") ||
                    arguments.contains("-MoriShowBeforeFeedOfferForUITest") {
            beforeFeedFlow.selectReason(.habit)
            _ = beforeFeedFlow.proceedToPlan()
        } else if arguments.contains("-MoriShowBeforeFeedQuietPauseForUITest") {
            beforeFeedFlow.selectReason(.relax)
            _ = beforeFeedFlow.proceedToPlan()
            _ = beforeFeedFlow.selectEnoughChoice(.twoMinutes)
            _ = beforeFeedFlow.beginPause()
            startOrResumeReset()
        } else if arguments.contains("-MoriShowBeforeFeedGuidedPauseForUITest") ||
                    arguments.contains("-MoriShowHabitBreathingForUITest") {
            beforeFeedFlow.selectReason(.habit)
            _ = beforeFeedFlow.proceedToPlan()
            _ = beforeFeedFlow.selectEnoughChoice(.twoMinutes)
            _ = beforeFeedFlow.beginPause()
            startOrResumeReset()
        }
    }

    private func prepareBeforeFeedPauseSnapshot(arguments: [String]) {
        guard context == .beforeFeed else { return }

        beforeFeedPausePreferences.migrateLegacyPausePreferencesIfNeeded()
        beforeFeedPausePreferences.normalizePersistedSettings()

        let forcesQuietPause = arguments.contains("-MoriShowBeforeFeedQuietPauseForUITest")
        let forcesGuidedPause = arguments.contains("-MoriShowBeforeFeedGuidedPauseForUITest") ||
            arguments.contains("-MoriShowHabitBreathingForUITest")
        let usesDefaultGuidedFixture = arguments.contains("-MoriUseDefaultBeforeFeedPauseForUITest")

        beforeFeedPauseStyle = forcesQuietPause
            ? .quietPause
            : ((forcesGuidedPause || usesDefaultGuidedFixture)
                ? .guidedBreathing
                : beforeFeedPausePreferences.pauseStyle())
        beforeFeedGuidedCycleCount = usesDefaultGuidedFixture
            ? MoriBeforeFeedPausePreferences.defaultGuidedCycleCount
            : beforeFeedPausePreferences.guidedCycleCount()
        beforeFeedTechniqueIDSnapshot = usesDefaultGuidedFixture
            ? MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
            : beforeFeedPausePreferences.techniqueID()
        beforeFeedPatternSnapshot = beforeFeedPauseStyle == .guidedBreathing
            ? resolvedBeforeFeedPattern(techniqueID: beforeFeedTechniqueIDSnapshot)
            : nil

        if beforeFeedPauseStyle == .guidedBreathing,
           let pattern = beforeFeedPatternSnapshot {
            beforeFeedPauseTargetDurationSnapshot = max(
                1,
                pattern.totalCycleDuration * Double(beforeFeedGuidedCycleCount)
            )
            beforeFeedPauseDurationSnapshot = max(
                1,
                Int(ceil(beforeFeedPauseTargetDurationSnapshot))
            )
        } else {
            beforeFeedPauseDurationSnapshot = forcesQuietPause
                ? 20
                : beforeFeedPausePreferences.quietDurationSeconds()
            beforeFeedPauseTargetDurationSnapshot = TimeInterval(beforeFeedPauseDurationSnapshot)
        }
    }

    private func resolvedBeforeFeedPattern(techniqueID: String) -> MoriBreathPattern? {
        guard let technique = MoriBreathingTechniqueRepository.getTechnique(id: techniqueID)
            ?? MoriBreathingTechniqueRepository.getTechnique(
                id: MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
            )
        else {
            return nil
        }

        guard technique.id == MoriBreathingTechniqueID.custom.rawValue else {
            return technique.breathPattern
        }

        return MoriBreathPattern(
            inhale: MoriBeforeFeedPausePreferences.normalizedCustomPhase(
                customInhaleSeconds,
                fallback: 4
            ),
            inhaleHold: customUsesHold
                ? MoriBeforeFeedPausePreferences.normalizedCustomPhase(
                    customHoldSeconds,
                    fallback: 1
                )
                : nil,
            exhale: MoriBeforeFeedPausePreferences.normalizedCustomPhase(
                customExhaleSeconds,
                fallback: 6
            ),
            exhaleHold: nil
        )
    }

    private func cleanupReset() {
        cueCoordinator.stopResetCues()
        endAppLimitIfNeeded()
    }

    private func handleSoundEnabledChange(_ enabled: Bool) {
        if enabled, isRunning {
            cueCoordinator.playCurrentBreathingSound(
                segments: activeBreathingSegments,
                currentPhaseIndex: currentPhaseIndex,
                canPlay: { soundEnabled && isRunning }
            )
            cueCoordinator.scheduleSoundForNextPhase(
                segments: activeBreathingSegments,
                currentPhaseIndex: currentPhaseIndex,
                phaseRemaining: activeBreathingPhaseRemaining,
                sessionRemaining: sessionRemaining,
                canPlay: { soundEnabled && isRunning }
            )
        } else {
            cueCoordinator.stopResetCues()
        }
    }

    private func resetAndDismiss() {
        reset()
        dismiss()
    }

    private func tick(now: Date = Date()) {
        guard isRunning else { return }

        syncResetClock(now: now)

        guard activeElapsed < targetDuration else {
            complete()
            return
        }

        syncBreathingCueTiming()
    }

    private func complete() {
        isRunning = false
        activeElapsed = targetDuration
        secondsRemaining = 0
        resetStartDate = nil
        pausedAt = nil
        totalPausedDuration = 0
        cueCoordinator.stopResetCues()
        cueCoordinator.playCompletionCues(
            context: context,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled
        )
        guard context == .morningGate else {
            _ = beforeFeedFlow.completePause()
            return
        }

        appLimitManager.perform(.completeMorningGateReset())
        let action = clarityStore.record(
            kind: .quietTimer,
            title: context.completionTitle,
            seeds: max(1, totalSeconds / 300),
            minutes: max(1, totalSeconds / 60),
            note: context.completedNote
        )
        if appLimitWasActive {
            clarityStore.record(
                kind: .screenTimeLimitKept,
                title: context.appLimitTitle,
                seeds: 1,
                minutes: max(1, totalSeconds / 60),
                note: context.appLimitNote
            )
        }
        appLimitWasActive = false
        _ = action
    }

    private func selectBeforeFeedReason(_ reason: MoriBeforeFeedIntentReason) {
        beforeFeedFlow.selectReason(reason)
    }

    private func continueFromBeforeFeedReason() {
        _ = beforeFeedFlow.proceedToPlan()
    }

    private func selectBeforeFeedEnoughChoice(_ choice: MoriBeforeFeedEnoughChoice) {
        _ = beforeFeedFlow.selectEnoughChoice(choice)
    }

    private func selectBeforeFeedReturnAnchor(_ anchor: MoriBeforeFeedReturnAnchor) {
        beforeFeedFlow.selectReturnAnchor(
            beforeFeedFlow.returnAnchor == anchor ? nil : anchor
        )
    }

    private func beginBeforeFeedPause() {
        guard beforeFeedFlow.beginPause() else { return }

        activeElapsed = 0
        secondsRemaining = totalSeconds
        resetStartDate = nil
        pausedAt = nil
        totalPausedDuration = 0
        currentPhaseIndex = 0
        startOrResumeReset()
    }

    private func returnToBeforeFeedReasons() {
        reset()
        beforeFeedFlow.reset()
    }

    private func returnToBeforeFeedPlan() {
        let reason = beforeFeedFlow.reason
        let enoughChoice = beforeFeedFlow.enoughChoice
        let returnAnchor = beforeFeedFlow.returnAnchor
        reset()
        beforeFeedFlow.reset()
        guard let reason else { return }
        beforeFeedFlow.selectReason(reason)
        _ = beforeFeedFlow.proceedToPlan()
        if let enoughChoice {
            _ = beforeFeedFlow.selectEnoughChoice(enoughChoice)
        }
        beforeFeedFlow.selectReturnAnchor(returnAnchor)
    }

    private func confirmBeforeFeedIntent() {
        finishBeforeFeedIntent()
    }

    private func finishBeforeFeedIntent() {
        guard context == .beforeFeed,
              let selectedBeforeFeedReason = beforeFeedFlow.reason,
              let enoughChoice = beforeFeedFlow.enoughChoice,
              let openWindowSeconds = beforeFeedFlow.confirmedOpenWindowSeconds,
              !didConfirmBeforeFeedIntent,
              beforeFeedFlow.canOpenFeed,
              secondsRemaining == 0
        else {
            return
        }

        didConfirmBeforeFeedIntent = true
        isRunning = false
        cueCoordinator.stopResetCues()
        appLimitManager.perform(
            .completeBeforeFeedReset(openWindowSeconds: openWindowSeconds)
        )
        beforeFeedGateStore.recordIntent(
            reason: selectedBeforeFeedReason,
            routeSource: routeSource?.rawValue,
            enoughChoiceID: enoughChoice.rawValue,
            openWindowSeconds: openWindowSeconds,
            returnAnchorID: beforeFeedFlow.returnAnchor?.rawValue,
            eventID: beforeFeedIntentEventID
        )
        appLimitWasActive = false
        dismiss()
    }

    private func leaveFeedClosed() {
        guard context == .beforeFeed else { return }
        reset()
        dismiss()
    }

    private func reset() {
        isRunning = false
        activeElapsed = 0
        secondsRemaining = totalSeconds
        resetStartDate = nil
        pausedAt = nil
        totalPausedDuration = 0
        appLimitWasActive = false
        currentPhaseIndex = 0
        cueCoordinator.stopResetCues()
        endAppLimitIfNeeded()
    }

    private func toggleResetRunning() {
        if isRunning {
            pauseReset()
        } else {
            startOrResumeReset()
        }
    }

    private func startOrResumeReset() {
        if secondsRemaining == 0 {
            activeElapsed = 0
            secondsRemaining = totalSeconds
            resetStartDate = nil
            totalPausedDuration = 0
            pausedAt = nil
        }

        if let pausedAt {
            totalPausedDuration += Date().timeIntervalSince(pausedAt)
        }
        pausedAt = nil

        if resetStartDate == nil {
            resetStartDate = Date().addingTimeInterval(-activeElapsed)
        }

        startAppLimitIfPossible()
        cueCoordinator.playStartCues(
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            hasBreathingTechnique: !activeBreathingSegments.isEmpty
        )
        isRunning = true
        beginBreathingCueTiming()
    }

    private func pauseReset() {
        syncResetClock()
        isRunning = false
        pausedAt = Date()
        cueCoordinator.stopResetCues()

        if context == .beforeFeed, !nativeGateEnabled, appLimitWasActive {
            appLimitWasActive = appLimitManager.perform(
                .startManualAppLimit(feature: .beforeFeed)
            )
        }
    }

    private func syncResetClock(now: Date = Date()) {
        guard let resetStartDate else { return }

        activeElapsed = min(
            targetDuration,
            max(0, now.timeIntervalSince(resetStartDate) - totalPausedDuration)
        )
        secondsRemaining = max(0, Int(ceil(targetDuration - activeElapsed)))
    }

    private func startAppLimitIfPossible() {
        appLimitWasActive = appLimitManager.perform(
            .beginResetAppLimit(
                feature: context.feature,
                remainingSeconds: secondsRemaining,
                usesNativeBeforeFeedGate: context == .beforeFeed && nativeGateEnabled
            )
        )
    }

    private func endAppLimitIfNeeded() {
        appLimitManager.perform(.endResetAppLimitIfNeeded(feature: context.feature))
    }

    private func beginBreathingCueTiming() {
        guard !activeBreathingSegments.isEmpty else { return }
        currentPhaseIndex = cueCoordinator.beginBreathingCueTiming(
            segments: activeBreathingSegments,
            elapsedTime: elapsedTime,
            phaseRemaining: activeBreathingPhaseRemaining,
            sessionRemaining: sessionRemaining,
            hapticsEnabled: hapticsEnabled,
            canPlaySound: { soundEnabled && isRunning }
        )
    }

    private func syncBreathingCueTiming() {
        guard !activeBreathingSegments.isEmpty else { return }
        currentPhaseIndex = cueCoordinator.syncBreathingCueTiming(
            segments: activeBreathingSegments,
            currentPhaseIndex: currentPhaseIndex,
            elapsedTime: elapsedTime,
            phaseRemaining: activeBreathingPhaseRemaining,
            sessionRemaining: sessionRemaining,
            hapticsEnabled: hapticsEnabled,
            canPlaySound: { soundEnabled && isRunning }
        )
    }
}

private struct MoriAttentionResetSheetHeader: View {
    let title: String
    let actionTitle: String
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(MoriColors.botanicalInk)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 68)

            HStack {
                Spacer()

                Button(actionTitle) {
                    onDone()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(MoriColors.botanicalMuted)
                .frame(minWidth: 56, minHeight: 44)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 64)
    }
}

private struct MoriAttentionResetSheetBackground: View {
    let variant: MoriBotanicalScreenBackdrop.Variant

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                MoriPaperBackground(variant: variant) {
                    Color.clear
                }

                MoriGeneratedArtImage(art: .breathLandscapeWash, contentMode: .fill)
                    .frame(
                        width: proxy.size.width,
                        height: max(420, proxy.size.height * 0.58),
                        alignment: .bottom
                    )
                    .clipped()
                    .opacity(0.50)
                    .blendMode(.multiply)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
