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
    @State private var beforeFeedPauseSnapshot = MoriBeforeFeedPauseSessionSnapshot.defaultValue
    @State private var didHandleOwnBreathOpeningCue = false
    @State private var beforeFeedIntentEventID = UUID()
    @State private var didResolveBeforeFeedOutcome = false

    private let beforeFeedGateStore = BeforeFeedGateStore()
    private let beforeFeedPausePreferences = MoriBeforeFeedPausePreferences()

    private var totalSeconds: Int {
        switch context {
        case .beforeFeed:
            return max(1, beforeFeedPauseSnapshot.displayedDurationSeconds)
        case .morningGate:
            return max(5 * 60, durationSeconds)
        }
    }

    private var targetDuration: TimeInterval {
        switch context {
        case .beforeFeed:
            return max(0.1, beforeFeedPauseSnapshot.targetDuration)
        case .morningGate:
            return TimeInterval(totalSeconds)
        }
    }

    private var sessionRemaining: TimeInterval {
        max(0, targetDuration - activeElapsed)
    }

    private var elapsedTime: TimeInterval {
        min(targetDuration, max(0, activeElapsed))
    }

    private var breathingState: MoriAttentionResetBreathingState {
        MoriAttentionResetBreathingState(
            context: context,
            beforeFeedTechniqueID: beforeFeedPauseSnapshot.techniqueID,
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
            return beforeFeedPauseSnapshot.style == .guidedBreathing
                ? (beforeFeedPauseSnapshot.pattern?.segments ?? [])
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
            return MoriL10n.display("Screen Time opened this pause. After the breath, choose whether to return to the feed yourself.")
        case .shortcut?:
            return MoriL10n.display("A shortcut opened Mori. After the breath, choose whether to return to the feed yourself.")
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
        return MoriBeforeFeedReturnAnchorPolicy.shouldShow(for: reason)
    }

    private var beforeFeedOpenActionTitle: String {
        guard let seconds = beforeFeedFlow.confirmedOpenWindowSeconds
            ?? beforeFeedFlow.enoughChoice?.openWindowSeconds
        else {
            return MoriL10n.display("Choose a time to open")
        }
        if seconds.isMultiple(of: 60) {
            return MoriL10n.string(
                "before_feed.intent.open_minutes",
                defaultValue: "Open for %d minutes",
                arguments: [seconds / 60]
            )
        }
        return MoriL10n.string(
            "before_feed.completion.open_window",
            defaultValue: "Open a %@ window",
            arguments: [BeforeFeedGate.formattedDuration(seconds)]
        )
    }

    private var beforeFeedPauseTitle: String {
        MoriL10n.display("Begin with the breath")
    }

    private var beforeFeedConfiguredPauseText: String {
        switch beforeFeedPauseSnapshot.style {
        case .guidedBreathing:
            let techniqueName = MoriBreathingTechniqueRepository.getTechnique(
                id: beforeFeedPauseSnapshot.techniqueID
            )?.name ?? MoriL10n.display("Guided breathing")
            let key = beforeFeedPauseSnapshot.guidedCycleCount == 1
                ? "before_feed.runtime.guided_summary_one"
                : "before_feed.runtime.guided_summary"
            let defaultValue = beforeFeedPauseSnapshot.guidedCycleCount == 1
                ? "%@ · 1 cycle · about %@"
                : "%@ · %d cycles · about %@"
            let arguments: [CVarArg] = beforeFeedPauseSnapshot.guidedCycleCount == 1
                ? [techniqueName, BeforeFeedGate.formattedDuration(totalSeconds)]
                : [
                    techniqueName,
                    beforeFeedPauseSnapshot.guidedCycleCount,
                    BeforeFeedGate.formattedDuration(totalSeconds)
                ]
            return MoriL10n.string(key, defaultValue: defaultValue, arguments: arguments)

        case .quietPause:
            return MoriL10n.string(
                "before_feed.runtime.own_breath_summary",
                defaultValue: "Follow your own breath · %@",
                arguments: [BeforeFeedGate.formattedDuration(totalSeconds)]
            )
        }
    }

    private var beforeFeedPauseGuidanceText: String {
        switch beforeFeedPauseSnapshot.style {
        case .guidedBreathing:
            if beforeFeedPauseSnapshot.techniqueID == MoriBreathingTechniqueID.longExhale.rawValue,
               beforeFeedPauseSnapshot.pattern == MoriBeforeFeedBreathKey.pattern {
                return MoriL10n.display("Breathe in for 4. Breathe out for 6.")
            }
            guard let pattern = beforeFeedPauseSnapshot.pattern else {
                return MoriL10n.display("Follow the breathing cues at a comfortable pace.")
            }
            return MoriBreathingTechnique.patternDisplay(for: pattern)

        case .quietPause:
            return MoriL10n.display("One long singing bowl marks the start. Breathe naturally until the timer ends.")
        }
    }

    private var beforeFeedGuidedProgressText: String? {
        guard beforeFeedPauseSnapshot.style == .guidedBreathing,
              let pattern = beforeFeedPauseSnapshot.pattern,
              pattern.totalCycleDuration > 0
        else {
            return nil
        }

        let completedCycles = Int(floor(activeElapsed / pattern.totalCycleDuration))
        let currentCycle = min(
            beforeFeedPauseSnapshot.guidedCycleCount,
            max(1, completedCycles + 1)
        )
        return MoriL10n.string(
            "before_feed.pause.round_progress",
            defaultValue: "Cycle %d of %d",
            arguments: [currentCycle, beforeFeedPauseSnapshot.guidedCycleCount]
        )
    }

    private var beforeFeedBreathingCueText: String {
        if secondsRemaining == 0 {
            return MoriL10n.display("Pause complete")
        }
        if beforeFeedPauseSnapshot.style == .quietPause {
            return isRunning
                ? MoriL10n.display("Breathe at your own pace")
                : (activeElapsed > 0 ? MoriL10n.display("Paused") : MoriL10n.display("Begin when ready"))
        }
        if isRunning, !activeBreathingSegments.isEmpty {
            return activeBreathingVisualState.label
        }
        if beforeFeedFlow.stage == .breathKey, activeElapsed > 0 {
            return MoriL10n.display("Paused")
        }
        return MoriL10n.display("Breathe in when ready")
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
            return beforeFeedFlow.stage == .breathKey ? .breath : .appLimit
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
                      beforeFeedFlow.stage == .breathKey,
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
            case .breathKey:
                MoriBeforeFeedBreathKeyContent(
                    pauseStyle: beforeFeedPauseSnapshot.style,
                    title: beforeFeedPauseTitle,
                    configuredPauseText: beforeFeedConfiguredPauseText,
                    guidanceText: beforeFeedPauseGuidanceText,
                    breathingVisualState: activeBreathingVisualState,
                    isRunning: isRunning,
                    hasStarted: activeElapsed > 0,
                    timeText: timeText,
                    cueText: beforeFeedBreathingCueText,
                    guidedProgressText: beforeFeedGuidedProgressText,
                    secondaryContext: beforeFeedSecondaryContext,
                    onTogglePause: toggleResetRunning
                )
            case .intent:
                MoriBeforeFeedIntentContent(
                    selectedReason: beforeFeedFlow.reason,
                    enoughChoices: beforeFeedEnoughChoices,
                    selectedEnoughChoice: beforeFeedFlow.enoughChoice,
                    selectedReturnAnchor: beforeFeedFlow.returnAnchor,
                    showsReturnAnchors: shouldShowReturnAnchors,
                    openActionTitle: beforeFeedOpenActionTitle,
                    secondaryContext: beforeFeedSecondaryContext,
                    onSelectReason: selectBeforeFeedReason,
                    onSelectEnoughChoice: selectBeforeFeedEnoughChoice,
                    onSelectReturnAnchor: selectBeforeFeedReturnAnchor,
                    onOpen: confirmBeforeFeedIntent,
                    onLeaveClosed: leaveFeedClosed
                )
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

        if arguments.contains("-MoriClearBeforeFeedHistoryForUITest") {
            beforeFeedGateStore.clearIntentHistory()
        }

        beforeFeedFlow.reset()
        didResolveBeforeFeedOutcome = false
        didHandleOwnBreathOpeningCue = false

        if arguments.contains("-MoriShowBeforeFeedCompletionForUITest") {
            _ = beforeFeedFlow.completeBreath()
            beforeFeedFlow.selectReason(.learn)
            _ = beforeFeedFlow.selectEnoughChoice(.fiveMinutes)
            beforeFeedFlow.selectReturnAnchor(.work)
            activeElapsed = targetDuration
            secondsRemaining = 0
        } else if arguments.contains("-MoriShowBeforeFeedPlanWithAnchorForUITest") {
            _ = beforeFeedFlow.completeBreath()
            beforeFeedFlow.selectReason(.habit)
            _ = beforeFeedFlow.selectEnoughChoice(.fiveMinutes)
            beforeFeedFlow.selectReturnAnchor(.work)
            activeElapsed = targetDuration
            secondsRemaining = 0
        } else if arguments.contains("-MoriShowBeforeFeedPlanForUITest") ||
                    arguments.contains("-MoriShowBeforeFeedOfferForUITest") {
            _ = beforeFeedFlow.completeBreath()
            beforeFeedFlow.selectReason(.habit)
            activeElapsed = targetDuration
            secondsRemaining = 0
        } else if arguments.contains("-MoriShowBeforeFeedIntentForUITest") ||
                    arguments.contains("-MoriCompleteBeforeFeedBreathForUITest") {
            _ = beforeFeedFlow.completeBreath()
            activeElapsed = targetDuration
            secondsRemaining = 0
        } else {
            startOrResumeReset()
        }
    }

    private func prepareBeforeFeedPauseSnapshot(arguments: [String]) {
        guard context == .beforeFeed else { return }

        beforeFeedPausePreferences.migrateLegacyPausePreferencesIfNeeded()
        beforeFeedPausePreferences.normalizePersistedSettings()
        var snapshot = MoriBeforeFeedPauseSessionSnapshot(
            preferences: beforeFeedPausePreferences,
            customInhaleSeconds: customInhaleSeconds,
            customHoldSeconds: customHoldSeconds,
            customExhaleSeconds: customExhaleSeconds,
            customUsesHold: customUsesHold
        )

        #if DEBUG
        if arguments.contains("-MoriUseDefaultBeforeFeedPauseForUITest") ||
            arguments.contains("-MoriUseGuidedBeforeFeedFixtureForUITest") {
            snapshot = .defaultValue
        } else if arguments.contains("-MoriUseConfiguredGuidedBeforeFeedPauseForUITest") {
            let techniqueID = MoriBreathingTechniqueID.coherent5.rawValue
            let pattern = MoriBreathingTechniqueRepository.getTechnique(id: techniqueID)?.breathPattern
                ?? MoriBeforeFeedBreathKey.pattern
            let cycleCount = 3
            let targetDuration = pattern.totalCycleDuration * TimeInterval(cycleCount)
            snapshot = MoriBeforeFeedPauseSessionSnapshot(
                style: .guidedBreathing,
                guidedCycleCount: cycleCount,
                techniqueID: techniqueID,
                pattern: pattern,
                displayedDurationSeconds: max(1, Int(ceil(targetDuration))),
                targetDuration: targetDuration
            )
        } else if arguments.contains("-MoriUseFollowOwnBeforeFeedPauseForUITest") ||
                    arguments.contains("-MoriShowBeforeFeedQuietPauseForUITest") {
            snapshot = MoriBeforeFeedPauseSessionSnapshot(
                style: .quietPause,
                guidedCycleCount: MoriBeforeFeedPausePreferences.defaultGuidedCycleCount,
                techniqueID: MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID,
                pattern: nil,
                displayedDurationSeconds: 20,
                targetDuration: 20
            )
        }
        #endif

        beforeFeedPauseSnapshot = snapshot
    }

    private func cleanupReset() {
        cueCoordinator.stopResetCues()
        endAppLimitIfNeeded()
    }

    private func handleSoundEnabledChange(_ enabled: Bool) {
        guard enabled else {
            cueCoordinator.stopResetCues()
            return
        }

        guard isRunning else { return }
        guard context != .beforeFeed || beforeFeedPauseSnapshot.style == .guidedBreathing else {
            // Follow-your-own-breath only considers sound at its first start.
            // Enabling sound later must not introduce a delayed bowl.
            return
        }

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
    }

    private func resetAndDismiss() {
        reset()
        dismiss()
    }

    private func tick(now: Date = Date()) {
        guard isRunning else { return }

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-MoriFreezeBeforeFeedTimerForUITest") {
            return
        }
        #endif

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
        let completionSoundEnabled = soundEnabled && (
            context != .beforeFeed ||
            MoriBeforeFeedOwnBreathAudioPolicy.shouldPlayCompletionSound(
                style: beforeFeedPauseSnapshot.style
            )
        )
        cueCoordinator.playCompletionCues(
            context: context,
            soundEnabled: completionSoundEnabled,
            hapticsEnabled: hapticsEnabled
        )
        guard context == .morningGate else {
            _ = beforeFeedFlow.completeBreath()
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

    private func selectBeforeFeedEnoughChoice(_ choice: MoriBeforeFeedEnoughChoice) {
        _ = beforeFeedFlow.selectEnoughChoice(choice)
    }

    private func selectBeforeFeedReturnAnchor(_ anchor: MoriBeforeFeedReturnAnchor) {
        beforeFeedFlow.selectReturnAnchor(
            beforeFeedFlow.returnAnchor == anchor ? nil : anchor
        )
    }

    private func confirmBeforeFeedIntent() {
        finishBeforeFeedIntent()
    }

    private func finishBeforeFeedIntent() {
        guard context == .beforeFeed,
              let selectedBeforeFeedReason = beforeFeedFlow.reason,
              let enoughChoice = beforeFeedFlow.enoughChoice,
              let openWindowSeconds = beforeFeedFlow.confirmedOpenWindowSeconds,
              !didResolveBeforeFeedOutcome,
              beforeFeedFlow.canOpenFeed,
              secondsRemaining == 0
        else {
            return
        }

        didResolveBeforeFeedOutcome = true
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
        guard context == .beforeFeed,
              beforeFeedFlow.stage == .intent,
              beforeFeedFlow.hasCompletedBreath,
              !didResolveBeforeFeedOutcome
        else {
            return
        }

        didResolveBeforeFeedOutcome = true
        beforeFeedGateStore.recordKeptClosed(
            routeSource: routeSource?.rawValue,
            eventID: beforeFeedIntentEventID
        )
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
        if context == .beforeFeed,
           MoriBeforeFeedOwnBreathAudioPolicy.shouldHandleOpeningCue(
               style: beforeFeedPauseSnapshot.style,
               hasHandledOpeningCue: didHandleOwnBreathOpeningCue
           ) {
            // Mark the first start as handled even when audio is disabled or
            // iOS suppresses secondary audio, preventing a late cue on resume.
            didHandleOwnBreathOpeningCue = true
            cueCoordinator.playFollowOwnBreathOpeningCue(
                soundEnabled: soundEnabled,
                hapticsEnabled: hapticsEnabled
            )
        } else if context == .morningGate {
            cueCoordinator.playStartCues(
                soundEnabled: soundEnabled,
                hapticsEnabled: hapticsEnabled,
                hasBreathingTechnique: !activeBreathingSegments.isEmpty
            )
        }
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
