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

    private var totalSeconds: Int {
        switch context {
        case .beforeFeed:
            return max(30, durationSeconds)
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

    var body: some View {
        Color.clear
            .background {
                MoriPaperBackground(variant: .appLimit) {
                    Color.clear
                }
            }
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    MoriAttentionResetSheetHeader(
                        title: context.navigationTitle,
                        onDone: resetAndDismiss
                    )

                    MoriAttentionResetContent(
                        context: context,
                        resetDurationText: resetDurationText,
                        headerSubtitle: breathingState.headerSubtitle,
                        progress: progress,
                        breathingTint: breathingState.tint,
                        showsBreathingOrb: breathingState.hasTechnique,
                        breathingVisualState: breathingState.visualState,
                        isRunning: isRunning,
                        secondsRemaining: secondsRemaining,
                        timeText: timeText,
                        cueText: breathingState.cueText,
                        limitText: limitText,
                        openWindowText: openWindowText,
                        onPrimaryAction: toggleResetRunning,
                        onReset: reset
                    )
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

    private func prepareReset() {
        activeElapsed = 0
        secondsRemaining = totalSeconds
        resetStartDate = nil
        pausedAt = nil
        totalPausedDuration = 0
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
        switch context {
        case .beforeFeed:
            appLimitManager.perform(.completeBeforeFeedReset())
        case .morningGate:
            appLimitManager.perform(.completeMorningGateReset())
        }
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
        cueCoordinator.playCompletionCues(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
        appLimitWasActive = false
        _ = action
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
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(MoriColors.botanicalInk)
                .lineLimit(1)

            HStack {
                Spacer()

                Button(MoriL10n.display("Done")) {
                    onDone()
                }
                .font(.system(size: 21, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
                .padding(.horizontal, 21)
                .frame(height: 52)
                .background(MoriColors.botanicalPaper.opacity(0.92))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(MoriColors.botanicalLine.opacity(0.58), lineWidth: 0.8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(height: 82)
        .background {
            MoriAttentionResetSheetHeaderBackground()
        }
    }
}

private struct MoriAttentionResetSheetHeaderBackground: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            MoriGeneratedArtImage(art: .paperWash, contentMode: .fill)
                .opacity(0.20)
                .blendMode(.multiply)

            LinearGradient(
                colors: [
                    MoriColors.sanctuaryFern.opacity(0.08),
                    MoriColors.botanicalPaper.opacity(0.34),
                    MoriColors.sanctuarySand.opacity(0.08)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .blendMode(.multiply)

            MoriColors.botanicalPaper.opacity(0.58)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MoriColors.botanicalLine.opacity(0.34))
                .frame(height: 0.7)
        }
        .accessibilityHidden(true)
    }
}
