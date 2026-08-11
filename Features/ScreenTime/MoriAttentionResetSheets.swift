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

private enum MoriBeforeFeedFlowStage: Equatable {
    case reason
    case offer
    case pause
    case completion
}

private struct MoriAttentionResetSheet: View {
    let context: MoriAttentionResetContext
    let durationSeconds: Int
    let routeSource: MoriAppRouteSource?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var clarityStore = MoriClarityStore.shared
    @StateObject private var appLimitManager = AppLimitManager.shared
    @AppStorage(
        MoriScreenTimeShared.beforeFeedNativeGateEnabledKey,
        store: MoriAppGroup.defaults
    ) private var nativeGateEnabled: Bool = MoriScreenTimeShared.defaultBeforeFeedNativeGateEnabled
    @AppStorage(
        MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedBreathingTechniqueID: String = MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
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
    @State private var beforeFeedStage: MoriBeforeFeedFlowStage = .reason
    @State private var selectedBeforeFeedReason: MoriBeforeFeedIntentReason?
    @State private var beforeFeedIntentEventID = UUID()
    @State private var didConfirmBeforeFeedIntent = false

    private let beforeFeedGateStore = BeforeFeedGateStore()

    private var totalSeconds: Int {
        switch context {
        case .beforeFeed:
            return max(MoriScreenTimeShared.minBeforeFeedDurationSeconds, durationSeconds)
        case .morningGate:
            return max(5 * 60, durationSeconds)
        }
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
            beforeFeedTechniqueID: beforeFeedBreathingTechniqueID,
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

    private var resetDurationText: String {
        switch context {
        case .beforeFeed:
            return BeforeFeedGate.formattedDuration(totalSeconds)
        case .morningGate:
            return MorningGate.formattedDuration(totalSeconds)
        }
    }

    private var openWindowDurationText: String {
        BeforeFeedGate.formattedDuration(BeforeFeedGate.graceWindowSeconds)
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
            switch routeSource {
            case .screenTimeGate?:
                return MoriL10n.string(
                    "attention_reset.open_window.before_feed.screen_time_gate",
                    defaultValue: "Complete the reset, then switch back manually if the feed still feels intentional. Window: %@.",
                    arguments: [openWindowDurationText]
                )
            case .shortcut?:
                return MoriL10n.string(
                    "attention_reset.open_window.before_feed.shortcut",
                    defaultValue: "Completion opens selected apps for %@; switch back manually only if you still mean to.",
                    arguments: [openWindowDurationText]
                )
            default:
                return MoriL10n.string(
                    "attention_reset.open_window.before_feed.default",
                    defaultValue: "Completion opens selected feed apps for %@.",
                    arguments: [openWindowDurationText]
                )
            }
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

    private var beforeFeedBreathingCueText: String {
        if secondsRemaining == 0 {
            return MoriL10n.display("Pause complete")
        }
        if isRunning, breathingState.hasTechnique {
            return breathingState.visualState.label
        }
        if beforeFeedStage == .pause, activeElapsed > 0 {
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
            return beforeFeedStage == .pause ? .breath : .appLimit
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
    }

    @ViewBuilder
    private var resetContent: some View {
        switch context {
        case .beforeFeed:
            switch beforeFeedStage {
            case .reason:
                MoriBeforeFeedReasonContent(
                    selectedReason: selectedBeforeFeedReason,
                    secondaryContext: beforeFeedSecondaryContext,
                    onSelectReason: selectBeforeFeedReason,
                    onContinue: continueFromBeforeFeedReason
                )
            case .offer:
                MoriBeforeFeedPauseOfferContent(
                    resetDurationText: resetDurationText,
                    timeText: timeText,
                    selectedReason: selectedBeforeFeedReason,
                    secondaryContext: beforeFeedSecondaryContext,
                    onBeginPause: beginBeforeFeedPause,
                    onContinueNow: continueBeforeFeedNow,
                    onBack: returnToBeforeFeedReasons
                )
            case .pause:
                MoriBeforeFeedPauseContent(
                    showsBreathingOrb: breathingState.hasTechnique,
                    breathingVisualState: breathingState.visualState,
                    isRunning: isRunning,
                    timeText: timeText,
                    cueText: beforeFeedBreathingCueText,
                    secondaryContext: beforeFeedSecondaryContext,
                    onToggleBreathing: toggleResetRunning,
                    onBack: returnToBeforeFeedReasons
                )
            case .completion:
                MoriBeforeFeedCompletionContent(
                    secondaryContext: beforeFeedSecondaryContext,
                    onContinue: confirmBeforeFeedIntent,
                    onBack: returnToBeforeFeedReasons
                )
            }
        case .morningGate:
            MoriMorningResetContent(
                context: context,
                resetDurationText: resetDurationText,
                headerSubtitle: breathingState.headerSubtitle,
                showsBreathingOrb: breathingState.hasTechnique,
                breathingVisualState: breathingState.visualState,
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
        activeElapsed = 0
        secondsRemaining = totalSeconds
        resetStartDate = nil
        pausedAt = nil
        totalPausedDuration = 0

        guard context == .beforeFeed else { return }

        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-MoriShowBeforeFeedCompletionForUITest") {
            selectedBeforeFeedReason = .habit
            activeElapsed = TimeInterval(totalSeconds)
            secondsRemaining = 0
            beforeFeedStage = .completion
        } else if arguments.contains("-MoriShowBeforeFeedOfferForUITest") {
            selectedBeforeFeedReason = .habit
            beforeFeedStage = .offer
        } else if arguments.contains("-MoriShowHabitBreathingForUITest") {
            selectedBeforeFeedReason = .habit
            beforeFeedStage = .pause
            startOrResumeReset()
        }
    }

    private func cleanupReset() {
        cueCoordinator.stopResetCues()
        endAppLimitIfNeeded()
    }

    private func handleSoundEnabledChange(_ enabled: Bool) {
        if enabled, isRunning {
            cueCoordinator.playCurrentBreathingSound(
                segments: breathingState.segments,
                currentPhaseIndex: currentPhaseIndex,
                canPlay: { soundEnabled && isRunning }
            )
            cueCoordinator.scheduleSoundForNextPhase(
                segments: breathingState.segments,
                currentPhaseIndex: currentPhaseIndex,
                phaseRemaining: breathingState.phaseRemaining,
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

        guard activeElapsed < TimeInterval(totalSeconds) else {
            complete()
            return
        }

        syncBreathingCueTiming()
    }

    private func complete() {
        isRunning = false
        activeElapsed = TimeInterval(totalSeconds)
        secondsRemaining = 0
        resetStartDate = nil
        pausedAt = nil
        totalPausedDuration = 0
        cueCoordinator.stopResetCues()
        cueCoordinator.playCompletionCues(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
        guard context == .morningGate else {
            beforeFeedStage = .completion
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
        selectedBeforeFeedReason = reason
    }

    private func continueFromBeforeFeedReason() {
        guard selectedBeforeFeedReason != nil else { return }

        beforeFeedStage = .offer
    }

    private func beginBeforeFeedPause() {
        guard selectedBeforeFeedReason != nil else { return }

        activeElapsed = 0
        secondsRemaining = totalSeconds
        resetStartDate = nil
        pausedAt = nil
        totalPausedDuration = 0
        currentPhaseIndex = 0
        beforeFeedStage = .pause
        startOrResumeReset()
    }

    private func continueBeforeFeedNow() {
        finishBeforeFeedIntent(requiresCompletedPause: false)
    }

    private func returnToBeforeFeedReasons() {
        reset()
        selectedBeforeFeedReason = nil
        beforeFeedStage = .reason
    }

    private func confirmBeforeFeedIntent() {
        finishBeforeFeedIntent(requiresCompletedPause: true)
    }

    private func finishBeforeFeedIntent(requiresCompletedPause: Bool) {
        guard context == .beforeFeed,
              let selectedBeforeFeedReason,
              !didConfirmBeforeFeedIntent,
              !requiresCompletedPause || (beforeFeedStage == .completion && secondsRemaining == 0)
        else {
            return
        }

        didConfirmBeforeFeedIntent = true
        isRunning = false
        cueCoordinator.stopResetCues()
        appLimitManager.perform(.completeBeforeFeedReset())
        beforeFeedGateStore.recordIntent(
            reason: selectedBeforeFeedReason,
            routeSource: routeSource?.rawValue,
            eventID: beforeFeedIntentEventID
        )
        appLimitWasActive = false
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
            hasBreathingTechnique: breathingState.hasTechnique
        )
        isRunning = true
        beginBreathingCueTiming()
    }

    private func pauseReset() {
        syncResetClock()
        isRunning = false
        pausedAt = Date()
        cueCoordinator.stopResetCues()
    }

    private func syncResetClock(now: Date = Date()) {
        guard let resetStartDate else { return }

        activeElapsed = min(
            TimeInterval(totalSeconds),
            max(0, now.timeIntervalSince(resetStartDate) - totalPausedDuration)
        )
        secondsRemaining = max(0, Int(ceil(TimeInterval(totalSeconds) - activeElapsed)))
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
        guard breathingState.hasTechnique, !breathingState.segments.isEmpty else { return }
        currentPhaseIndex = cueCoordinator.beginBreathingCueTiming(
            segments: breathingState.segments,
            elapsedTime: elapsedTime,
            phaseRemaining: breathingState.phaseRemaining,
            hapticsEnabled: hapticsEnabled,
            canPlaySound: { soundEnabled && isRunning }
        )
    }

    private func syncBreathingCueTiming() {
        guard breathingState.hasTechnique, !breathingState.segments.isEmpty else { return }
        currentPhaseIndex = cueCoordinator.syncBreathingCueTiming(
            segments: breathingState.segments,
            currentPhaseIndex: currentPhaseIndex,
            elapsedTime: elapsedTime,
            phaseRemaining: breathingState.phaseRemaining,
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
