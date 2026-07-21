import SwiftUI

struct QuietModeView: View {
    var showsDismissButton = false

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: UserSettings
    @StateObject private var clarityStore = MoriClarityStore.shared
    @StateObject private var appLimitManager = AppLimitManager.shared
    @State private var selectedMinutes = 10
    @State private var isCustomDurationSelected = false
    @State private var customHours = 1
    @State private var customMinutes = 0
    @State private var secondsRemaining = 10 * 60
    @State private var isRunning = false
    @State private var urgeReason = ""
    @State private var selectedReplacement: QuietReplacementAction?
    @State private var didCompleteTimer = false
    @State private var quietAppLimitWasActive = false
    @State private var activeTimerSession: MoriQuietTimerSession?
    @State private var showsMoreQuietChoices = false

    private let minuteOptions = [5, 10, 20, 30]
    private let deepDetoxMinuteOptions = [60, 180, 24 * 60]
    private let customMinuteOptions = Array(stride(from: 0, through: 55, by: MoriQuietTimerDuration.minuteStep))

    private var metrics: MoriClarityMetrics {
        clarityStore.metrics(settings: settings)
    }

    var body: some View {
        NavigationStack {
            MoriPaperBackground(variant: .practice) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        MoriPageHeader(
                            eyebrow: "Quiet",
                            title: "Quiet Mode",
                            subtitle: "A little room before the next feed."
                        )

                        QuietTimerCard(
                            customHours: $customHours,
                            customMinutes: $customMinutes,
                            selectedMinutes: selectedMinutes,
                            isCustomDurationSelected: isCustomDurationSelected,
                            isRunning: isRunning,
                            timerSelectionIsLocked: timerSelectionIsLocked,
                            minuteOptions: minuteOptions,
                            deepDetoxMinuteOptions: deepDetoxMinuteOptions,
                            availableCustomMinuteOptions: availableCustomMinuteOptions,
                            timerProgress: timerProgress,
                            timeText: timeText,
                            timerStatusText: timerStatusText,
                            primaryTimerActionTitle: primaryTimerActionTitle,
                            onSelectDuration: selectDuration,
                            onSelectCustomDuration: selectCustomDuration,
                            onToggleTimer: toggleTimer,
                            onResetTimer: resetTimer
                        )

                        if !isRunning {
                            quietChoicesDisclosure
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, showsDismissButton ? 72 : 18)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                if showsDismissButton {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(MoriV2Palette.forestInk)
                                .frame(width: MoriV2Layout.minimumHitTarget, height: MoriV2Layout.minimumHitTarget)
                                .background(MoriV2Palette.primaryForest.opacity(0.07))
                                .clipShape(Circle())
                        }
                        .buttonStyle(MoriV2PressButtonStyle())
                        .accessibilityLabel("Back")
                    }
                }
            }
            .quietModeLifecycle(
                selectedMinutes: selectedMinutes,
                customHours: customHours,
                customMinutes: customMinutes,
                onPrepare: refreshFromPersistentTimer,
                onTick: tick,
                onSelectedMinutesChange: syncSelectedMinutes,
                onCustomHoursChange: syncCustomHours,
                onCustomMinutesChange: syncCustomMinutes
            )
            .moriKeyboardDoneToolbar()
            .moriHidesMainTabBar()
        }
    }

    private var timerProgress: CGFloat {
        let total = max(1, activeTimerSession?.durationSeconds ?? selectedDurationSeconds)
        let completed = max(0, min(total, total - secondsRemaining))
        return CGFloat(completed) / CGFloat(total)
    }

    private var timeText: String {
        MoriQuietTimerDuration.formattedClock(secondsRemaining)
    }

    private var timerStatusText: String {
        if isRunning {
            return MoriL10n.display("quiet in progress")
        }
        return didCompleteTimer ? MoriL10n.display("one quiet session protected") : MoriL10n.display("ready when you are")
    }

    private var quietChoicesDisclosure: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriV2QuietDisclosureRow(
                title: showsMoreQuietChoices ? "Keep this simple" : "More quiet choices",
                subtitle: showsMoreQuietChoices
                    ? "Hide the secondary choices."
                    : "Limits, a brief note, and other ways to pause stay here.",
                isExpanded: showsMoreQuietChoices,
                action: { showsMoreQuietChoices.toggle() }
            )

            if showsMoreQuietChoices {
                VStack(spacing: 16) {
                    QuietSettleSuggestionCard()

                    ScreenTimeLimitControls(contextTitle: "Quiet Mode", feature: .quiet)

                    QuietUrgeCheckInCard(
                        urgeReason: $urgeReason,
                        onPlantPause: recordUrgeCheckIn
                    )

                    QuietReplacementActionsCard(
                        selectedReplacement: $selectedReplacement,
                        onSelect: recordReplacementAction
                    )

                    QuietDailySummarySection(metrics: metrics)
                }
                .transition(.opacity)
            }
        }
        .moriReduceMotionAnimation(MoriV2Motion.disclosure, value: showsMoreQuietChoices)
    }

    private var selectedDurationSeconds: Int {
        if isCustomDurationSelected {
            return MoriQuietTimerDuration.normalizedSeconds(customHours * 3600 + customMinutes * 60)
        }
        return selectedMinutes * 60
    }

    private var timerSelectionIsLocked: Bool {
        activeTimerSession != nil && !didCompleteTimer
    }

    private var primaryTimerActionTitle: String {
        if isRunning {
            return MoriL10n.display("Pause")
        }
        return activeTimerSession == nil ? MoriL10n.display("Start") : MoriL10n.display("Resume")
    }

    private var availableCustomMinuteOptions: [Int] {
        customHours >= 72 ? [0] : customMinuteOptions
    }

    private var presetMinuteOptions: [Int] {
        minuteOptions + deepDetoxMinuteOptions
    }

    private func syncSelectedMinutes(_ newValue: Int) {
        guard !timerSelectionIsLocked else { return }
        secondsRemaining = newValue * 60
        didCompleteTimer = false
    }

    private func syncCustomHours(_ newValue: Int) {
        if newValue >= 72 {
            customMinutes = 0
        } else if newValue == 0 && customMinutes == 0 {
            customMinutes = MoriQuietTimerDuration.minuteStep
        }
        syncRemainingWithSelectedDuration()
    }

    private func syncCustomMinutes() {
        if customHours == 0 && customMinutes == 0 {
            customMinutes = MoriQuietTimerDuration.minuteStep
        }
        syncRemainingWithSelectedDuration()
    }

    private func selectDuration(_ minutes: Int) {
        guard !timerSelectionIsLocked else { return }
        isCustomDurationSelected = false
        selectedMinutes = minutes
        secondsRemaining = minutes * 60
        didCompleteTimer = false
    }

    private func selectCustomDuration() {
        guard !timerSelectionIsLocked else { return }
        isCustomDurationSelected = true
        syncRemainingWithSelectedDuration()
        didCompleteTimer = false
    }

    private func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startOrResumeTimer()
        }
    }

    private func recordUrgeCheckIn(_ note: String) {
        clarityStore.record(
            kind: .urgeCheckIn,
            title: MoriL10n.display("Named the urge"),
            seeds: 2,
            minutes: 2,
            note: note
        )
    }

    private func recordReplacementAction(_ action: QuietReplacementAction) {
        selectedReplacement = action
        clarityStore.record(
            kind: .replacementAction,
            title: action.title,
            seeds: action.seeds,
            minutes: action.minutes,
            note: action.note
        )
    }

    private func tick() {
        guard isRunning, let session = activeTimerSession else { return }

        let remaining = session.remainingSeconds()
        if remaining > 0 {
            secondsRemaining = remaining
            return
        }

        completeTimer(session)
    }

    private func startOrResumeTimer() {
        let now = Date()
        let session: MoriQuietTimerSession
        if let existingSession = activeTimerSession {
            session = existingSession.resumed(at: now)
        } else {
            let duration = selectedDurationSeconds
            session = MoriQuietTimerSession(
                durationSeconds: duration,
                startedAt: now,
                endDate: now.addingTimeInterval(TimeInterval(duration)),
                remainingSeconds: duration
            )
        }

        var persistedSession = session
        persistedSession.quietShieldWasActive = startQuietAppLimitIfPossible(endDate: persistedSession.endDate)
        QuietTimerCoordinator.saveSession(persistedSession)
        QuietTimerCoordinator.scheduleCompletionNotification(for: persistedSession)
        applyTimerSession(persistedSession)
        didCompleteTimer = false
    }

    private func pauseTimer() {
        guard let session = activeTimerSession else {
            isRunning = false
            return
        }

        var pausedSession = session.paused()
        pausedSession.quietShieldWasActive = quietAppLimitWasActive
        activeTimerSession = pausedSession
        secondsRemaining = pausedSession.remainingSeconds
        isRunning = false
        QuietTimerCoordinator.saveSession(pausedSession)
        QuietTimerCoordinator.cancelCompletionNotification()
        appLimitManager.perform(.endAppLimit(feature: .quiet))
    }

    private func resetTimer() {
        isRunning = false
        activeTimerSession = nil
        secondsRemaining = selectedDurationSeconds
        didCompleteTimer = false
        quietAppLimitWasActive = false
        QuietTimerCoordinator.cancelCompletionNotification()
        QuietTimerCoordinator.clearSession()
        appLimitManager.perform(.endAppLimit(feature: .quiet))
    }

    private func completeTimer(_ session: MoriQuietTimerSession) {
        isRunning = false
        secondsRemaining = 0
        activeTimerSession = nil
        didCompleteTimer = true
        quietAppLimitWasActive = false
        QuietTimerCoordinator.completeSession(session, clarityStore: clarityStore, appLimitManager: appLimitManager)
    }

    private func refreshFromPersistentTimer() {
        let previousHadSession = activeTimerSession != nil
        if let session = QuietTimerCoordinator.reconcileExpiredSession(
            clarityStore: clarityStore,
            appLimitManager: appLimitManager
        ) {
            applyTimerSession(session)
        } else {
            activeTimerSession = nil
            isRunning = false
                quietAppLimitWasActive = false
            if previousHadSession {
                didCompleteTimer = true
                secondsRemaining = 0
            } else {
                secondsRemaining = selectedDurationSeconds
            }
        }
    }

    private func applyTimerSession(_ session: MoriQuietTimerSession) {
        activeTimerSession = session
        syncSelection(for: session.durationSeconds)
        secondsRemaining = session.remainingSeconds()
        isRunning = session.isRunning
        quietAppLimitWasActive = session.quietShieldWasActive
        didCompleteTimer = false
    }

    private func syncSelection(for durationSeconds: Int) {
        let minutes = durationSeconds / 60
        if presetMinuteOptions.contains(minutes) {
            isCustomDurationSelected = false
            selectedMinutes = minutes
            return
        }

        isCustomDurationSelected = true
        customHours = min(72, durationSeconds / 3600)
        customMinutes = customHours >= 72 ? 0 : (durationSeconds % 3600) / 60
    }

    private func syncRemainingWithSelectedDuration() {
        guard !timerSelectionIsLocked else { return }
        secondsRemaining = selectedDurationSeconds
        didCompleteTimer = false
    }

    private func startQuietAppLimitIfPossible(endDate: Date) -> Bool {
        appLimitManager.perform(
            .startTimedAppLimit(
                feature: .quiet,
                duration: endDate.timeIntervalSinceNow
            )
        )
    }
}

#Preview {
    QuietModeView()
        .environmentObject(UserSettings())
}
