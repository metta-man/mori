import FamilyControls
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
        ZStack {
            MoriColors.sanctuaryPaper
                .ignoresSafeArea()

            MoriBotanicalScreenBackdrop(variant: .practice)
                .opacity(0.28)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    MoriPageHeader(
                        eyebrow: "QUIET",
                        title: "Quiet Mode",
                        subtitle: "Rest without a goal. A simple timer, nothing to finish."
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
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
                title: showsMoreQuietChoices ? "Hide quiet tools" : "Quiet tools",
                subtitle: showsMoreQuietChoices
                    ? "Return to the simple timer."
                    : "Optional limits, a brief note, and gentle alternatives.",
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

enum EssentialModeDuration: String, CaseIterable, Identifiable {
    case resetEight
    case thirtyMinutes
    case oneHour
    case twoHours
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .resetEight: return "8 min reset"
        case .thirtyMinutes: return "30 min"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        case .manual: return "Until I turn it off"
        }
    }

    var compactTitle: String {
        switch self {
        case .resetEight: return "8 min"
        case .thirtyMinutes: return "30 min"
        case .oneHour: return "1 hr"
        case .twoHours: return "2 hr"
        case .manual: return "Manual"
        }
    }

    var seconds: Int? {
        switch self {
        case .resetEight: return 8 * 60
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        case .manual: return nil
        }
    }
}

struct EssentialModeView: View {
    var showsDismissButton = false

    @Environment(\.dismiss) private var dismiss
    @StateObject private var appLimitManager = AppLimitManager.shared
    @StateObject private var clarityStore = MoriClarityStore.shared
    @AppStorage("mori_essential_mode_duration") private var selectedDurationRaw = EssentialModeDuration.oneHour.rawValue
    @State private var pickerTarget: AppLimitSelectionTarget?
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var pendingStart = false
    @State private var showsReplaceConfirmation = false
    @State private var showsEndConfirmation = false
    @State private var didComplete = false
    @State private var errorMessage: String?

    private var selectedDuration: EssentialModeDuration {
        get { EssentialModeDuration(rawValue: selectedDurationRaw) ?? .oneHour }
        nonmutating set { selectedDurationRaw = newValue.rawValue }
    }

    private var snapshot: AppLimitSettingsSnapshot {
        appLimitManager.settingsSnapshot
    }

    private var summary: MoriScreenTimeProfileSummary {
        if showsEssentialActiveFixture {
            return MoriScreenTimeProfileSummary(
                feature: .walkOfflineReset,
                isEnabled: true,
                usesDefaultSelection: false,
                customSelectedCount: 3,
                effectiveSelectedCount: 3,
                displayNames: ["Phone", "Messages", "Maps"],
                restrictionPolicy: .allowSelected
            )
        }
        return snapshot.profileSummary(for: .walkOfflineReset)
    }

    private var activeSession: MoriScreenTimeActiveSession? {
        if showsEssentialActiveFixture {
            return MoriScreenTimeActiveSession(
                feature: .walkOfflineReset,
                startedAt: Date().addingTimeInterval(-18 * 60),
                endDate: .distantFuture,
                endPolicy: .manual
            )
        }
        guard let session = appLimitManager.activeSession,
              session.feature == .walkOfflineReset,
              !session.isExpired else {
            return nil
        }
        return session
    }

    private var showsEssentialActiveFixture: Bool {
        ProcessInfo.processInfo.arguments.contains("-MoriShowEssentialActiveForUITest")
    }

    var body: some View {
        ZStack {
            MoriColors.sanctuaryPaper
                .ignoresSafeArea()

            MoriBotanicalScreenBackdrop(variant: .focus)
                .opacity(activeSession == nil ? 0.20 : 0.42)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    if didComplete {
                        completionSurface
                    } else if let activeSession {
                        activeSurface(activeSession)
                    } else {
                        setupSurface
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if showsDismissButton {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
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
        .task {
            appLimitManager.perform(.reconcileAppLimitState)
        }
        .sheet(item: $pickerTarget) { target in
            ScreenTimeSettingsPickerSheet(
                title: "Apps to keep available",
                selection: $pickerSelection,
                onDone: { finishPicker(target) }
            )
            .moriBotanicalSheetPresentation()
        }
        .confirmationDialog(
            "Replace the current app-limited session?",
            isPresented: $showsReplaceConfirmation,
            titleVisibility: .visible
        ) {
            Button("End current session and start") {
                beginSelectedDuration()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mori can keep only one Screen Time mode active at a time.")
        }
        .confirmationDialog(
            "End Essential Mode?",
            isPresented: $showsEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Essential Mode", role: .destructive) {
                endEssentialMode()
            }
            Button("Keep it on", role: .cancel) {}
        } message: {
            Text("All apps will become available again.")
        }
        .moriHidesMainTabBar()
    }

    private var setupSurface: some View {
        VStack(alignment: .leading, spacing: 20) {
            MoriPageHeader(
                eyebrow: "ESSENTIAL",
                title: "Essential Mode",
                subtitle: "Turn your phone simple. Keep only what you need."
            )

            essentialLandscape

            VStack(alignment: .leading, spacing: 6) {
                Text(MoriL10n.display("Only essentials open"))
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundColor(MoriV2Palette.forestInk)

                Text(MoriL10n.display("Calls, maps, rides, and the apps you choose stay available. Everything else pauses behind Mori's shield."))
                    .font(MoriV2Type.supporting)
                    .foregroundColor(MoriV2Palette.stone)
                    .fixedSize(horizontal: false, vertical: true)
            }

            permissionAndSelectionPanel
            durationSection

            if let active = appLimitManager.activeSession, active.feature != .walkOfflineReset {
                Text(MoriL10n.display("Starting Essential Mode will end the current app-limited session."))
                    .font(MoriV2Type.caption)
                    .foregroundColor(MoriV2Palette.stone)
            }

            MoriV2PrimaryButton(
                title: startButtonTitle,
                icon: snapshot.isAuthorized && summary.hasEffectiveSelection ? .play : .lockShield,
                action: requestStart
            )

            if let errorMessage {
                Text(MoriL10n.display(errorMessage))
                    .font(MoriV2Type.caption)
                    .foregroundColor(MoriColors.botanicalClay)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var essentialLandscape: some View {
        ZStack(alignment: .bottomLeading) {
            Image("MoriActiveDeepSessionValley")
                .resizable()
                .scaledToFill()
                .frame(height: 205)
                .clipped()
                .saturation(0.72)
                .brightness(0.06)

            LinearGradient(
                colors: [MoriV2Palette.raisedPaper.opacity(0.10), MoriV2Palette.raisedPaper.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(spacing: 9) {
                MoriBitmapIconImage(icon: .leaf, size: 17, opacity: 0.86)
                Text(MoriL10n.display("Less phone. More day."))
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(MoriV2Palette.forestInk)
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 205)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(MoriV2Palette.hairline, lineWidth: 1)
        }
    }

    private var permissionAndSelectionPanel: some View {
        VStack(spacing: 0) {
            if !snapshot.isAuthorized {
                Button {
                    appLimitManager.perform(.requestAuthorization)
                } label: {
                    essentialRow(
                        icon: .lockShield,
                        title: "Allow Screen Time",
                        detail: "Needed to pause apps on this iPhone.",
                        value: "Allow"
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button(action: showAllowedAppsPicker) {
                    essentialRow(
                        icon: .leaf,
                        title: "Apps to keep",
                        detail: summary.hasEffectiveSelection
                            ? summary.selectionStatusText
                            : "Choose at least one essential app.",
                        value: summary.hasEffectiveSelection ? "Edit" : "Choose"
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(MoriV2Palette.raisedPaper.opacity(0.90))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MoriV2Palette.hairline, lineWidth: 1)
        }
    }

    private func essentialRow(
        icon: MoriBitmapIcon,
        title: String,
        detail: String,
        value: String
    ) -> some View {
        HStack(spacing: 12) {
            MoriBitmapIconImage(icon: icon, size: 17, opacity: 0.86)
                .frame(width: 40, height: 40)
                .background(MoriV2Palette.sage.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display(title))
                    .font(MoriV2Type.control)
                    .foregroundColor(MoriV2Palette.forestInk)
                Text(MoriL10n.display(detail))
                    .font(MoriV2Type.caption)
                    .foregroundColor(MoriV2Palette.stone)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Text(MoriL10n.display(value))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriV2Palette.forestInk)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 68)
        .contentShape(Rectangle())
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(
                title: "How long?",
                subtitle: "It ends automatically unless you choose manual."
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(EssentialModeDuration.allCases) { duration in
                    Button {
                        selectedDuration = duration
                    } label: {
                        Text(MoriL10n.display(duration.title))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(
                                selectedDuration == duration
                                    ? MoriColors.sanctuarySurface
                                    : MoriV2Palette.forestInk
                            )
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(
                                selectedDuration == duration
                                    ? MoriV2Palette.primaryForest
                                    : MoriV2Palette.raisedPaper.opacity(0.84)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(MoriV2PressButtonStyle())
                }
            }
        }
    }

    private func activeSurface(_ session: MoriScreenTimeActiveSession) -> some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text(MoriL10n.display("ESSENTIAL"))
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(MoriV2Palette.sage)

                Text(MoriL10n.display("Only what matters"))
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .foregroundColor(MoriV2Palette.forestInk)

                Text(MoriL10n.display("The rest of your phone can wait."))
                    .font(MoriV2Type.supporting)
                    .foregroundColor(MoriV2Palette.stone)
            }
            .multilineTextAlignment(.center)

            ZStack(alignment: .bottom) {
                Image("MoriActiveDeepSessionValley")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 390)
                    .clipped()
                    .saturation(0.70)
                    .brightness(0.04)

                LinearGradient(
                    colors: [.clear, MoriColors.sanctuaryPaper.opacity(0.88)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 8) {
                        Text(activeTimeText(session, now: context.date))
                            .font(.system(size: 54, weight: .regular, design: .serif))
                            .foregroundColor(MoriV2Palette.forestInk)
                            .monospacedDigit()

                        Text(activeEndDetail(session))
                            .font(MoriV2Type.caption)
                            .foregroundColor(MoriV2Palette.stone)
                    }
                    .padding(.bottom, 32)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 390)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(MoriL10n.display("Apps still available"))
                    .font(MoriV2Type.control)
                    .foregroundColor(MoriV2Palette.forestInk)
                Text(MoriL10n.display(summary.selectionStatusText))
                    .font(MoriV2Type.caption)
                    .foregroundColor(MoriV2Palette.stone)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(MoriV2Palette.raisedPaper.opacity(0.90))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                showsEndConfirmation = true
            } label: {
                Text(MoriL10n.display("End Essential Mode"))
                    .font(MoriV2Type.control)
                    .foregroundColor(MoriV2Palette.forestInk)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(MoriV2Palette.raisedPaper.opacity(0.86))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(MoriV2Palette.hairline, lineWidth: 1)
                    }
            }
            .buttonStyle(MoriV2PressButtonStyle())
        }
    }

    private var completionSurface: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 120)
            MoriBitmapIconImage(icon: .leaf, size: 28, opacity: 0.88)
                .frame(width: 64, height: 64)
                .background(MoriV2Palette.sage.opacity(0.12))
                .clipShape(Circle())

            Text(MoriL10n.display("Your phone is open again."))
                .font(.system(size: 36, weight: .regular, design: .serif))
                .foregroundColor(MoriV2Palette.forestInk)
                .multilineTextAlignment(.center)

            Text(MoriL10n.display("A little more room was enough."))
                .font(MoriV2Type.supporting)
                .foregroundColor(MoriV2Palette.stone)

            Spacer(minLength: 100)

            MoriV2PrimaryButton(title: "Continue", icon: .leaf) {
                dismiss()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 680)
    }

    private var startButtonTitle: String {
        if !snapshot.isAuthorized { return "Allow Screen Time" }
        if !summary.hasEffectiveSelection { return "Choose essential apps" }
        return "Start Essential Mode"
    }

    private func showAllowedAppsPicker() {
        let target = AppLimitSelectionTarget.feature(.walkOfflineReset)
        let draft = appLimitManager.selectionDraft(for: target)
        pickerSelection = draft.selection
        pickerTarget = target
    }

    private func finishPicker(_ target: AppLimitSelectionTarget) {
        appLimitManager.perform(
            .commitSelectionDraft(
                AppLimitSelectionDraft(target: target, selection: pickerSelection)
            )
        )
        errorMessage = pickerSelection.applicationTokens.isEmpty
            ? "Choose at least one app to keep available."
            : nil
        if pendingStart, !pickerSelection.applicationTokens.isEmpty {
            pendingStart = false
            requestStart()
        }
    }

    private func requestStart() {
        errorMessage = nil
        guard snapshot.isAuthorized else {
            appLimitManager.perform(.requestAuthorization)
            return
        }
        guard summary.hasEffectiveSelection else {
            pendingStart = true
            showAllowedAppsPicker()
            return
        }
        if let active = appLimitManager.activeSession, active.feature != .walkOfflineReset {
            showsReplaceConfirmation = true
            return
        }
        beginSelectedDuration()
    }

    private func beginSelectedDuration() {
        let didStart: Bool
        if let seconds = selectedDuration.seconds {
            didStart = appLimitManager.perform(
                .startTimedAppLimit(
                    feature: .walkOfflineReset,
                    remainingSeconds: seconds
                )
            )
        } else {
            didStart = appLimitManager.perform(
                .startManualAppLimit(feature: .walkOfflineReset)
            )
        }
        if !didStart {
            errorMessage = "Essential Mode could not start. Check Screen Time access and your app selection."
        }
    }

    private func endEssentialMode() {
        guard let session = activeSession else { return }
        appLimitManager.perform(.endAppLimit(feature: .walkOfflineReset))
        let protectedMinutes = max(1, Int(Date().timeIntervalSince(session.startedAt) / 60))
        clarityStore.record(
            kind: .replacementAction,
            title: "Essential Mode",
            seeds: 2,
            minutes: protectedMinutes,
            note: "Kept only essential apps available"
        )
        didComplete = true
    }

    private func activeTimeText(_ session: MoriScreenTimeActiveSession, now: Date) -> String {
        guard session.endPolicy == .timed else { return "On" }
        return MoriQuietTimerDuration.formattedClock(max(0, Int(ceil(session.endDate.timeIntervalSince(now)))))
    }

    private func activeEndDetail(_ session: MoriScreenTimeActiveSession) -> String {
        guard session.endPolicy == .timed else {
            return MoriL10n.display("until you turn it off")
        }
        return MoriL10n.string(
            "essential_mode.ends_at",
            defaultValue: "ends at %@",
            arguments: [session.endDate.formatted(date: .omitted, time: .shortened)]
        )
    }
}

#Preview("Essential Mode") {
    NavigationStack {
        EssentialModeView()
    }
}
