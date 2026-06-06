import SwiftUI
import UIKit

struct SettleView: View {
    @EnvironmentObject var settings: UserSettings
    @StateObject private var clarityStore = MoriClarityStore.shared
    @StateObject private var settleStore = SettleSessionStore.shared

    private let topAnchorID = "settle-top"

    private var weeklySummary: SettleWeeklySummary {
        settleStore.weeklySummary()
    }

    var body: some View {
        NavigationStack {
            MoriForestBackground {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            Color.clear
                                .frame(height: 0)
                                .id(topAnchorID)

                            MoriPageHeader(
                                eyebrow: "Settle",
                                title: "Return to Presence",
                                subtitle: "A quiet timer for coming back from digital noise before the next tap chooses for you."
                            )

                            VStack(spacing: 12) {
                                NavigationLink(destination: SettleTimerDetailView()) {
                                    SettlePracticeCard(
                                        mode: .settle,
                                        title: "Settle",
                                        subtitle: "A quiet timer for presence, bells, and completed Settle history.",
                                        detail: "Meditation timer",
                                        tint: MoriColors.forestMoss
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink(destination: MoriBreathingLibraryView()) {
                                    SettlePracticeCard(
                                        mode: .breathing,
                                        title: "Breathing",
                                        subtitle: "Guided inhale, exhale, and hold cues with sound and haptics.",
                                        detail: "1-10 min",
                                        tint: MoriColors.forestMist
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink(destination: PomodoroPracticeDetailView()) {
                                    SettlePracticeCard(
                                        mode: .pomodoro,
                                        title: "Pomodoro",
                                        subtitle: "A focused work cycle with mindful breaks and completion Seeds.",
                                        detail: "Focus cycle",
                                        tint: MoriColors.forestClay
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            weeklyRootsCard

                            historyCard

                            privacyNote
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 40)
                    }
                    .onAppear {
                        scrollToTop(with: proxy)
                    }
                }
            }
            .navigationTitle("Settle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
    }

    private var weeklyRootsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            MoriSectionTitle(
                title: "Settle Roots",
                subtitle: "This week's meditation rhythm, kept local on this device."
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MoriMetricTile(
                    title: "Sessions",
                    value: "\(weeklySummary.completedSessions)",
                    detail: "completed this week",
                    symbolName: "figure.mind.and.body",
                    tint: MoriColors.forestMoss
                )

                MoriMetricTile(
                    title: "Minutes",
                    value: "\(weeklySummary.totalMinutes)m",
                    detail: "settled time",
                    symbolName: "timer",
                    tint: MoriColors.forestMist
                )

                MoriMetricTile(
                    title: "Consistency",
                    value: "\(weeklySummary.consistencyDays)d",
                    detail: "practice days",
                    symbolName: "chart.bar.fill",
                    tint: MoriColors.forestRoot
                )

                MoriMetricTile(
                    title: "Bloom",
                    value: weeklySummary.bloomPercentText,
                    detail: "meditation growth",
                    symbolName: "camera.macro",
                    tint: MoriColors.forestFern
                )
            }

            MoriForestProgressBar(value: weeklySummary.bloomProgress, tint: MoriColors.forestFern)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Session History",
                subtitle: "Completed practices plant Seeds; early endings stay visible without judgment."
            )

            let recent = settleStore.recentSessions(limit: 6)
            if recent.isEmpty {
                Text("No Settle sessions yet. The first completed practice will show up here and in Roots.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(recent) { session in
                    SettleHistoryRow(session: session)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundColor(MoriColors.forestMoss)

            Text("Settle, Breathing, and Pomodoro sessions are stored locally. Mori uses only aggregate Seeds, minutes, and consistency for Roots and Bloom.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }

    private func scrollToTop(with proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo(topAnchorID, anchor: .top)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            proxy.scrollTo(topAnchorID, anchor: .top)
        }
    }
}

private struct SettleTimerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var clarityStore = MoriClarityStore.shared
    @StateObject private var settleStore = SettleSessionStore.shared

    @AppStorage("mori_settle_last_duration") private var selectedMinutes: Int = 10
    @AppStorage("mori_settle_sound_enabled") private var soundEnabled: Bool = true
    @AppStorage("mori_settle_interval_enabled") private var intervalBellEnabled: Bool = false
    @AppStorage("mori_settle_interval_minutes") private var intervalBellMinutes: Int = 5

    @State private var timerState: SettleTimerState = .idle
    @State private var secondsRemaining: Int = 10 * 60
    @State private var sessionStartedAt: Date?
    @State private var lastIntervalBellElapsed = 0
    @State private var completedSession: SettleSession?
    @State private var completedSettleSeeds: Int?
    @State private var showLeaveDialog = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let baseDurations = [5, 10, 15, 20, 30, 45]
    private let intervalOptions = [5, 10, 15]

    private var weeklySummary: SettleWeeklySummary {
        settleStore.weeklySummary()
    }

    private var recommendedMinutes: Int {
        settleStore.recommendedDurationMinutes()
    }

    private var durationOptions: [Int] {
        Array(Set(baseDurations + [recommendedMinutes])).sorted()
    }

    var body: some View {
        MoriForestBackground {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    MoriPageHeader(
                        eyebrow: "Settle",
                        title: "Practice Timer",
                        subtitle: "A quiet timer for coming back from digital noise before the next tap chooses for you."
                    )

                    SettleRecommendationCard(
                        recommendedMinutes: recommendedMinutes,
                        weeklySummary: weeklySummary,
                        onUseRecommendation: {
                            guard timerState.canChangeDuration else { return }
                            selectedMinutes = recommendedMinutes
                            secondsRemaining = recommendedMinutes * 60
                            completedSession = nil
                            completedSettleSeeds = nil
                        },
                        onStartRecommendation: {
                            guard timerState.canChangeDuration else { return }
                            selectedMinutes = recommendedMinutes
                            startTimer()
                        }
                    )

                    timerCard

                    settleSettings
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Settle")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    requestClose()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                }
                .accessibilityLabel("Back")
            }
        }
        .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear {
            if timerState.canChangeDuration {
                secondsRemaining = selectedMinutes * 60
            }
        }
        .onChange(of: selectedMinutes) { newValue in
            guard timerState.canChangeDuration else { return }
            secondsRemaining = newValue * 60
            completedSession = nil
            completedSettleSeeds = nil
        }
        .onReceive(ticker) { _ in
            tick()
        }
        .confirmationDialog(
            "End this Settle session?",
            isPresented: $showLeaveDialog,
            titleVisibility: .visible
        ) {
            Button("Keep practicing", role: .cancel) {}
            Button("End and leave", role: .destructive) {
                endTimer()
                dismiss()
            }
        } message: {
            Text("The partial Settle session will be saved as ended early.")
        }
    }

    private var timerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                MoriSectionTitle(
                    title: "Practice Timer",
                    subtitle: timerState.subtitle
                )

                Spacer()

                Button {
                    soundEnabled.toggle()
                } label: {
                    Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                        .frame(width: 38, height: 38)
                        .background(MoriColors.forestCanopy.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(soundEnabled ? "Settle bells on" : "Settle bells off")
            }

            durationPicker

            ZStack {
                Circle()
                    .stroke(MoriColors.forestLine.opacity(0.62), lineWidth: 13)

                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(
                        MoriColors.forestMoss,
                        style: StrokeStyle(lineWidth: 13, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.25), value: timerProgress)

                SettleLeafPulse(isActive: timerState == .running)

                VStack(spacing: 6) {
                    Text(timeText)
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)
                        .monospacedDigit()
                        .minimumScaleFactor(0.75)

                    Label(timerState.label, systemImage: timerState.symbolName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.forestMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 244)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Settle timer \(timeText), \(timerState.label)")

            if let completedSession {
                completionBanner(completedSession, seedsOverride: completedSettleSeeds)
            }

            controlRow
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Duration")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MoriColors.forestMuted)

            FlowLayout(spacing: 8) {
                ForEach(durationOptions, id: \.self) { minutes in
                    Button {
                        guard timerState.canChangeDuration else { return }
                        selectedMinutes = minutes
                    } label: {
                        MoriPill(
                            title: "\(minutes)m",
                            symbolName: minutes == recommendedMinutes ? "leaf.fill" : nil,
                            isSelected: selectedMinutes == minutes,
                            tint: minutes == recommendedMinutes ? MoriColors.forestMoss : MoriColors.forestCanopy
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!timerState.canChangeDuration)
                    .accessibilityLabel("\(minutes) minute Settle practice")
                }
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            switch timerState {
            case .idle, .completed:
                Button {
                    startTimer()
                } label: {
                    Label(timerState == .completed ? "Begin again" : "Start", systemImage: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MoriColors.forestCanopy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

            case .running:
                settleControlButton(title: "Pause", symbolName: "pause.fill", tint: MoriColors.forestCanopy) {
                    pauseTimer()
                }
                settleEndButton

            case .paused:
                settleControlButton(title: "Resume", symbolName: "play.fill", tint: MoriColors.forestCanopy) {
                    resumeTimer()
                }
                settleEndButton
            }
        }
    }

    private var settleEndButton: some View {
        Button {
            endTimer()
        } label: {
            Label("End", systemImage: "stop.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.forestCanopy)
                .frame(width: 100)
                .padding(.vertical, 14)
                .background(MoriColors.forestCanopy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func settleControlButton(
        title: String,
        symbolName: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.forestCard)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var settleSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Bells",
                subtitle: "Soft sound at the beginning and end, with an optional interval bell."
            )

            Toggle(isOn: $intervalBellEnabled) {
                Label("Interval bell", systemImage: "bell.and.waves.left.and.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.forestCanopy)
            }
            .tint(MoriColors.forestMoss)

            if intervalBellEnabled {
                FlowLayout(spacing: 8) {
                    ForEach(intervalOptions, id: \.self) { minutes in
                        Button {
                            intervalBellMinutes = minutes
                        } label: {
                            MoriPill(
                                title: "\(minutes)m",
                                isSelected: intervalBellMinutes == minutes,
                                tint: MoriColors.forestMist
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var timerProgress: CGFloat {
        let total = max(1, selectedMinutes * 60)
        return CGFloat(total - secondsRemaining) / CGFloat(total)
    }

    private var timeText: String {
        formatTime(secondsRemaining)
    }

    private func startTimer() {
        sessionStartedAt = Date()
        secondsRemaining = selectedMinutes * 60
        timerState = .running
        lastIntervalBellElapsed = 0
        completedSession = nil

        if soundEnabled {
            SettleBellService.shared.playStartBell()
        }
    }

    private func pauseTimer() {
        guard timerState == .running else { return }
        timerState = .paused
    }

    private func resumeTimer() {
        guard timerState == .paused else { return }
        timerState = .running
    }

    private func endTimer() {
        guard timerState == .running || timerState == .paused else { return }

        let totalSeconds = selectedMinutes * 60
        let actualSeconds = max(0, totalSeconds - secondsRemaining)

        if actualSeconds > 0, let startedAt = sessionStartedAt {
            settleStore.recordSession(
                startedAt: startedAt,
                plannedMinutes: selectedMinutes,
                actualSeconds: actualSeconds,
                completed: false,
                intervalBellMinutes: activeIntervalBellMinutes
            )
        }

        SettleBellService.shared.stop()
        sessionStartedAt = nil
        secondsRemaining = selectedMinutes * 60
        timerState = .idle
        completedSession = nil
        completedSettleSeeds = nil
        lastIntervalBellElapsed = 0
    }

    private func tick() {
        guard timerState == .running else { return }

        if secondsRemaining > 0 {
            secondsRemaining -= 1
            playIntervalBellIfNeeded()
        }

        if secondsRemaining == 0 {
            completeTimer()
        }
    }

    private func completeTimer() {
        guard timerState == .running, let startedAt = sessionStartedAt else { return }

        timerState = .completed
        let totalSeconds = selectedMinutes * 60
        let session = settleStore.recordSession(
            startedAt: startedAt,
            plannedMinutes: selectedMinutes,
            actualSeconds: totalSeconds,
            completed: true,
            intervalBellMinutes: activeIntervalBellMinutes
        )

        let action = clarityStore.record(
            kind: .settleSession,
            title: session.title,
            seeds: session.seedsEarned,
            minutes: session.actualMinutes,
            note: "Completed a Settle practice"
        )

        completedSession = session
        completedSettleSeeds = action.seeds
        sessionStartedAt = nil
        lastIntervalBellElapsed = 0

        if soundEnabled {
            SettleBellService.shared.playEndingBell()
        }
    }

    private func playIntervalBellIfNeeded() {
        guard soundEnabled,
              let interval = activeIntervalBellMinutes,
              timerState == .running
        else {
            return
        }

        let totalSeconds = selectedMinutes * 60
        let elapsed = totalSeconds - secondsRemaining
        let intervalSeconds = interval * 60

        guard elapsed > 0,
              secondsRemaining > 0,
              elapsed.isMultiple(of: intervalSeconds),
              elapsed != lastIntervalBellElapsed
        else {
            return
        }

        lastIntervalBellElapsed = elapsed
        SettleBellService.shared.playIntervalBell()
    }

    private var activeIntervalBellMinutes: Int? {
        guard intervalBellEnabled, intervalBellMinutes > 0, intervalBellMinutes < selectedMinutes else {
            return nil
        }
        return intervalBellMinutes
    }

    private func requestClose() {
        if timerState == .running || timerState == .paused {
            showLeaveDialog = true
        } else {
            dismiss()
        }
    }
}

private struct BreathingPracticeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var clarityStore = MoriClarityStore.shared

    @AppStorage("mori_settle_breathing_duration") private var breathingMinutes: Int = 2
    @AppStorage("mori_settle_breathing_preset") private var breathingPresetRaw: String = MoriBreathingPreset.calm.rawValue
    @AppStorage("mori_settle_breathing_sound_enabled") private var breathingSoundEnabled: Bool = true
    @AppStorage("mori_settle_breathing_haptics_enabled") private var breathingHapticsEnabled: Bool = true

    @State private var breathingState: SettleTimerState = .idle
    @State private var breathingSecondsRemaining: Int = 2 * 60
    @State private var breathingElapsedSeconds = 0
    @State private var completedBreathingSummary: MindfulCompletionSummary?
    @State private var lastCuePhase: BreathingCyclePhase?
    @State private var scheduledHapticTimers: [Timer] = []
    @State private var showLeaveDialog = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let breathingDurationOptions = [1, 2, 5, 10]

    private var breathingPreset: MoriBreathingPreset {
        get { MoriBreathingPreset(rawValue: breathingPresetRaw) ?? .calm }
        nonmutating set { breathingPresetRaw = newValue.rawValue }
    }

    var body: some View {
        MoriForestBackground {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    MoriPageHeader(
                        eyebrow: "Breathing",
                        title: "Follow the Breath",
                        subtitle: "Gentle phase cues for returning to the body before attention runs ahead."
                    )

                    breathingCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Breathing")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    requestClose()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                }
                .accessibilityLabel("Back")
            }
        }
        .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear {
            if breathingState.canChangeDuration {
                breathingSecondsRemaining = breathingMinutes * 60
                breathingElapsedSeconds = 0
            }
        }
        .onDisappear {
            cleanupCues()
        }
        .onChange(of: breathingMinutes) { newValue in
            guard breathingState.canChangeDuration else { return }
            breathingSecondsRemaining = newValue * 60
            breathingElapsedSeconds = 0
            completedBreathingSummary = nil
        }
        .onChange(of: breathingPresetRaw) { _ in
            guard breathingState.canChangeDuration else { return }
            breathingElapsedSeconds = 0
            completedBreathingSummary = nil
            lastCuePhase = nil
        }
        .onReceive(ticker) { _ in
            tickBreathing()
        }
        .confirmationDialog(
            "End this breathing session?",
            isPresented: $showLeaveDialog,
            titleVisibility: .visible
        ) {
            Button("Keep breathing", role: .cancel) {}
            Button("End and leave", role: .destructive) {
                resetBreathing()
                dismiss()
            }
        } message: {
            Text("Breathing sessions only record when the timer completes.")
        }
    }

    private var breathingCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                MoriSectionTitle(
                    title: "Breathing Timer",
                    subtitle: breathingState == .running ? "Follow the rhythm and let the body lead." : "Choose a simple rhythm for a short nervous system reset."
                )

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        breathingSoundEnabled.toggle()
                        if breathingSoundEnabled, breathingState == .running {
                            emitBreathingCue(force: true)
                        } else {
                            SettleBellService.shared.stopBreathingCues()
                        }
                    } label: {
                        Image(systemName: breathingSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(MoriColors.forestCanopy)
                            .frame(width: 36, height: 36)
                            .background(MoriColors.forestCanopy.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(breathingSoundEnabled ? "Breathing sound cues on" : "Breathing sound cues off")

                    Button {
                        breathingHapticsEnabled.toggle()
                        if !breathingHapticsEnabled {
                            cancelScheduledHaptics()
                        } else if breathingState == .running {
                            emitBreathingCue(force: true)
                        }
                    } label: {
                        Image(systemName: breathingHapticsEnabled ? "water.waves" : "waveform.slash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(MoriColors.forestCanopy)
                            .frame(width: 36, height: 36)
                            .background(MoriColors.forestCanopy.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(breathingHapticsEnabled ? "Breathing haptics on" : "Breathing haptics off")
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Technique")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.forestMuted)

                FlowLayout(spacing: 8) {
                    ForEach(MoriBreathingPreset.allCases) { preset in
                        Button {
                            guard breathingState.canChangeDuration else { return }
                            breathingPreset = preset
                        } label: {
                            MoriPill(
                                title: preset.title,
                                symbolName: preset.symbolName,
                                isSelected: breathingPreset == preset,
                                tint: preset.tint
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!breathingState.canChangeDuration)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Duration")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.forestMuted)

                FlowLayout(spacing: 8) {
                    ForEach(breathingDurationOptions, id: \.self) { minutes in
                        Button {
                            guard breathingState.canChangeDuration else { return }
                            breathingMinutes = minutes
                        } label: {
                            MoriPill(
                                title: "\(minutes)m",
                                isSelected: breathingMinutes == minutes,
                                tint: MoriColors.forestCanopy
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!breathingState.canChangeDuration)
                    }
                }
            }

            BreathingOrbTimer(
                preset: breathingPreset,
                elapsedSeconds: breathingElapsedSeconds,
                secondsRemaining: breathingSecondsRemaining,
                isRunning: breathingState == .running,
                isPaused: breathingState == .paused,
                progress: breathingProgress
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Breathing timer \(breathingTimeText), \(breathingPhase.label)")

            if let completedBreathingSummary {
                mindfulCompletionBanner(completedBreathingSummary)
            }

            breathingControlRow
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }

    private var breathingControlRow: some View {
        HStack(spacing: 12) {
            switch breathingState {
            case .idle, .completed:
                Button {
                    startBreathing()
                } label: {
                    Label(breathingState == .completed ? "Breathe again" : "Start", systemImage: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MoriColors.forestCanopy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

            case .running:
                settleControlButton(title: "Pause", symbolName: "pause.fill", tint: MoriColors.forestCanopy) {
                    pauseBreathing()
                }
                breathingEndButton

            case .paused:
                settleControlButton(title: "Resume", symbolName: "play.fill", tint: MoriColors.forestCanopy) {
                    resumeBreathing()
                }
                breathingEndButton
            }
        }
    }

    private var breathingEndButton: some View {
        Button {
            resetBreathing()
        } label: {
            Label("End", systemImage: "stop.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.forestCanopy)
                .frame(width: 100)
                .padding(.vertical, 14)
                .background(MoriColors.forestCanopy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var breathingProgress: CGFloat {
        let total = max(1, breathingMinutes * 60)
        return CGFloat(total - breathingSecondsRemaining) / CGFloat(total)
    }

    private var breathingTimeText: String {
        formatTime(breathingSecondsRemaining)
    }

    private var breathingPhase: BreathingCycleState {
        breathingPreset.phase(at: breathingElapsedSeconds)
    }

    private func startBreathing() {
        breathingSecondsRemaining = breathingMinutes * 60
        breathingElapsedSeconds = 0
        breathingState = .running
        completedBreathingSummary = nil
        lastCuePhase = nil
        emitBreathingCue(force: true)
    }

    private func pauseBreathing() {
        guard breathingState == .running else { return }
        breathingState = .paused
        cleanupCues()
    }

    private func resumeBreathing() {
        guard breathingState == .paused else { return }
        breathingState = .running
        emitBreathingCue(force: true)
    }

    private func resetBreathing() {
        breathingState = .idle
        breathingSecondsRemaining = breathingMinutes * 60
        breathingElapsedSeconds = 0
        completedBreathingSummary = nil
        lastCuePhase = nil
        cleanupCues()
    }

    private func tickBreathing() {
        guard breathingState == .running else { return }

        if breathingSecondsRemaining > 0 {
            breathingSecondsRemaining -= 1
            breathingElapsedSeconds += 1
            emitBreathingCue()
        }

        if breathingSecondsRemaining == 0 {
            completeBreathing()
        }
    }

    private func completeBreathing() {
        guard breathingState == .running else { return }

        breathingState = .completed
        cleanupCues()

        let seeds = max(1, breathingMinutes / 2)
        let action = clarityStore.record(
            kind: .breathingSession,
            title: "\(breathingPreset.title) breathing",
            seeds: seeds,
            minutes: breathingMinutes,
            note: "Completed a guided breathing reset"
        )
        completedBreathingSummary = MindfulCompletionSummary(
            title: "Breath settled",
            seeds: action.seeds,
            minutes: breathingMinutes,
            symbolName: "wind.circle.fill",
            tint: MoriColors.forestMist
        )

        if breathingSoundEnabled {
            SettleBellService.shared.playEndingBell()
        }
        if breathingHapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func emitBreathingCue(force: Bool = false) {
        guard breathingState == .running else { return }
        let phase = breathingPhase.phase
        guard force || phase != lastCuePhase else { return }

        lastCuePhase = phase
        cancelScheduledHaptics()

        if breathingSoundEnabled {
            SettleBellService.shared.playBreathingCue(phase.breathingCue)
        }

        if breathingHapticsEnabled {
            playHaptic(for: phase)
        }
    }

    private func playHaptic(for phase: BreathingCyclePhase) {
        switch phase {
        case .inhale:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .exhale:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .hold:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            scheduleHapticTap(after: 0.2, style: .medium)
        }
    }

    private func scheduleHapticTap(after delay: TimeInterval, style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let timer = Timer.scheduledTimer(withTimeInterval: max(0, delay), repeats: false) { _ in
            guard breathingHapticsEnabled, breathingState == .running else { return }
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
        scheduledHapticTimers.append(timer)
        RunLoop.current.add(timer, forMode: .common)
    }

    private func cancelScheduledHaptics() {
        scheduledHapticTimers.forEach { $0.invalidate() }
        scheduledHapticTimers.removeAll()
    }

    private func cleanupCues() {
        cancelScheduledHaptics()
        SettleBellService.shared.stopBreathingCues()
    }

    private func requestClose() {
        if breathingState == .running || breathingState == .paused {
            showLeaveDialog = true
        } else {
            dismiss()
        }
    }
}

private struct PomodoroPracticeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var clarityStore = MoriClarityStore.shared
    @StateObject private var shieldManager = FocusShieldManager.shared

    @AppStorage("mori_settle_sound_enabled") private var soundEnabled: Bool = true
    @AppStorage("mori_settle_pomodoro_focus_minutes") private var pomodoroFocusMinutes: Int = 25
    @AppStorage("mori_settle_pomodoro_short_break_minutes") private var pomodoroShortBreakMinutes: Int = 5
    @AppStorage("mori_settle_pomodoro_long_break_minutes") private var pomodoroLongBreakMinutes: Int = 15
    @AppStorage("mori_settle_pomodoro_cycles") private var pomodoroCycles: Int = 4
    @AppStorage("mori_settle_pomodoro_break_breathing") private var pomodoroBreakBreathingRaw: String = MoriPomodoroBreakBreathing.none.rawValue

    @State private var pomodoroState: SettleTimerState = .idle
    @State private var pomodoroPhase: MoriPomodoroPhase = .focus
    @State private var pomodoroSecondsRemaining: Int = 25 * 60
    @State private var pomodoroCompletedCycles = 0
    @State private var pomodoroFocusSecondsCompleted = 0
    @State private var pomodoroBreakSecondsCompleted = 0
    @State private var completedPomodoroSummary: MindfulCompletionSummary?
    @State private var lastBreakBreathingPhase: BreathingCyclePhase?
    @State private var showLeaveDialog = false
    @State private var pomodoroShieldWasActive = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var pomodoroBreakBreathing: MoriPomodoroBreakBreathing {
        get { MoriPomodoroBreakBreathing(rawValue: pomodoroBreakBreathingRaw) ?? .none }
        nonmutating set { pomodoroBreakBreathingRaw = newValue.rawValue }
    }

    var body: some View {
        MoriForestBackground {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    MoriPageHeader(
                        eyebrow: "Pomodoro",
                        title: "Focus Cycle",
                        subtitle: "A focused work rhythm with quiet breaks and completion Seeds."
                    )

                    pomodoroCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Pomodoro")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    requestClose()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                }
                .accessibilityLabel("Back")
            }
        }
        .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear {
            if pomodoroState.canChangeDuration {
                resetPomodoroClock()
            }
        }
        .onChange(of: pomodoroFocusMinutes) { _ in
            if pomodoroState.canChangeDuration {
                resetPomodoroClock()
            }
        }
        .onChange(of: pomodoroShortBreakMinutes) { _ in
            if pomodoroState.canChangeDuration {
                resetPomodoroClock()
            }
        }
        .onChange(of: pomodoroLongBreakMinutes) { _ in
            if pomodoroState.canChangeDuration {
                resetPomodoroClock()
            }
        }
        .onChange(of: pomodoroCycles) { _ in
            if pomodoroState.canChangeDuration {
                resetPomodoroClock()
            }
        }
        .onReceive(ticker) { _ in
            tickPomodoro()
        }
        .confirmationDialog(
            "End this Pomodoro?",
            isPresented: $showLeaveDialog,
            titleVisibility: .visible
        ) {
            Button("Keep focusing", role: .cancel) {}
            Button("End and leave", role: .destructive) {
                endPomodoro(recordCompletion: false)
                dismiss()
            }
        } message: {
            Text("Pomodoro sessions only record when the full cycle completes.")
        }
    }

    private var pomodoroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                MoriSectionTitle(
                    title: "Pomodoro",
                    subtitle: pomodoroState == .running ? pomodoroPhase.runningSubtitle : "Set a focused rhythm with mindful breaks."
                )

                Spacer()

                Button {
                    soundEnabled.toggle()
                } label: {
                    Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                        .frame(width: 38, height: 38)
                        .background(MoriColors.forestCanopy.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(soundEnabled ? "Pomodoro bells on" : "Pomodoro bells off")
            }

            ZStack {
                Circle()
                    .stroke(MoriColors.forestLine.opacity(0.62), lineWidth: 13)

                Circle()
                    .trim(from: 0, to: pomodoroProgress)
                    .stroke(
                        pomodoroPhase.tint,
                        style: StrokeStyle(lineWidth: 13, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.25), value: pomodoroProgress)

                VStack(spacing: 8) {
                    Image(systemName: pomodoroPhase.symbolName)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(pomodoroPhase.tint)

                    Text(pomodoroTimeText)
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)
                        .monospacedDigit()
                        .minimumScaleFactor(0.75)

                    Text(pomodoroPhase.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.forestMuted)

                    Text("Cycle \(min(pomodoroCompletedCycles + 1, pomodoroCycles)) of \(pomodoroCycles)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestMuted.opacity(0.82))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 244)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Pomodoro timer \(pomodoroTimeText), \(pomodoroPhase.title)")

            pomodoroBreakBreathingCue

            if pomodoroState.canChangeDuration {
                pomodoroSettings
            }

            ScreenTimeLimitControls(contextTitle: "Pomodoro")

            if let completedPomodoroSummary {
                mindfulCompletionBanner(completedPomodoroSummary)
            }

            pomodoroControlRow
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }

    private var pomodoroSettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            Stepper("Focus \(pomodoroFocusMinutes)m", value: $pomodoroFocusMinutes, in: 5...90, step: 5)
            Stepper("Short break \(pomodoroShortBreakMinutes)m", value: $pomodoroShortBreakMinutes, in: 1...30, step: 1)
            Stepper("Long break \(pomodoroLongBreakMinutes)m", value: $pomodoroLongBreakMinutes, in: 5...45, step: 5)
            Stepper("Cycles \(pomodoroCycles)", value: $pomodoroCycles, in: 1...8, step: 1)

            VStack(alignment: .leading, spacing: 10) {
                Text("Break breathing")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.forestMuted)

                FlowLayout(spacing: 8) {
                    ForEach(MoriPomodoroBreakBreathing.allCases) { option in
                        Button {
                            pomodoroBreakBreathing = option
                            lastBreakBreathingPhase = nil
                        } label: {
                            MoriPill(
                                title: option.title,
                                symbolName: option.symbolName,
                                isSelected: pomodoroBreakBreathing == option,
                                tint: option.tint
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundColor(MoriColors.forestCanopy)
        .padding(14)
        .background(MoriColors.forestPaperDeep.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var pomodoroControlRow: some View {
        HStack(spacing: 12) {
            switch pomodoroState {
            case .idle, .completed:
                Button {
                    startPomodoro()
                } label: {
                    Label(pomodoroState == .completed ? "Begin again" : "Start", systemImage: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MoriColors.forestCanopy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                if pomodoroState == .completed {
                    Button {
                        resetPomodoroClock()
                        completedPomodoroSummary = nil
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(MoriColors.forestCanopy)
                            .frame(width: 48, height: 48)
                            .background(MoriColors.forestCanopy.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reset Pomodoro")
                }

            case .running:
                settleControlButton(title: "Pause", symbolName: "pause.fill", tint: MoriColors.forestCanopy) {
                    pomodoroState = .paused
                }
                pomodoroEndButton

            case .paused:
                settleControlButton(title: "Resume", symbolName: "play.fill", tint: MoriColors.forestCanopy) {
                    pomodoroState = .running
                }
                pomodoroEndButton
            }
        }
    }

    private var pomodoroEndButton: some View {
        Button {
            endPomodoro(recordCompletion: false)
        } label: {
            Label("End", systemImage: "stop.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.forestCanopy)
                .frame(width: 100)
                .padding(.vertical, 14)
                .background(MoriColors.forestCanopy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var pomodoroProgress: CGFloat {
        let total = max(1, pomodoroPhase.durationSeconds(
            focusMinutes: pomodoroFocusMinutes,
            shortBreakMinutes: pomodoroShortBreakMinutes,
            longBreakMinutes: pomodoroLongBreakMinutes
        ))
        return CGFloat(total - pomodoroSecondsRemaining) / CGFloat(total)
    }

    private var pomodoroTimeText: String {
        formatTime(pomodoroSecondsRemaining)
    }

    @ViewBuilder
    private var pomodoroBreakBreathingCue: some View {
        if pomodoroPhase.isBreak,
           let preset = pomodoroBreakBreathing.preset {
            let state = preset.phase(at: pomodoroCurrentPhaseElapsedSeconds)
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: preset.symbolName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(preset.tint)
                    .frame(width: 36, height: 36)
                    .background(preset.tint.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(state.label)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)

                    Text("\(preset.title) · \(preset.timingDescription)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(preset.tint.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var pomodoroCurrentPhaseElapsedSeconds: Int {
        max(0, pomodoroPhase.durationSeconds(
            focusMinutes: pomodoroFocusMinutes,
            shortBreakMinutes: pomodoroShortBreakMinutes,
            longBreakMinutes: pomodoroLongBreakMinutes
        ) - pomodoroSecondsRemaining)
    }

    private func startPomodoro() {
        resetPomodoroClock()
        pomodoroState = .running
        completedPomodoroSummary = nil
        startPomodoroShieldIfPossible()

        if soundEnabled {
            SettleBellService.shared.playStartBell()
        }
    }

    private func resetPomodoroClock() {
        pomodoroState = .idle
        pomodoroPhase = .focus
        pomodoroSecondsRemaining = pomodoroFocusMinutes * 60
        pomodoroCompletedCycles = 0
        pomodoroFocusSecondsCompleted = 0
        pomodoroBreakSecondsCompleted = 0
        lastBreakBreathingPhase = nil
        pomodoroShieldWasActive = false
        shieldManager.endShield(mode: .pomodoro)
        SettleBellService.shared.stopBreathingCues()
    }

    private func tickPomodoro() {
        guard pomodoroState == .running else { return }

        if pomodoroSecondsRemaining > 0 {
            pomodoroSecondsRemaining -= 1
            if pomodoroPhase == .focus {
                pomodoroFocusSecondsCompleted += 1
            } else if pomodoroPhase.isBreak {
                pomodoroBreakSecondsCompleted += 1
                emitPomodoroBreakBreathingCue()
            }
        }

        if pomodoroSecondsRemaining == 0 {
            advancePomodoroPhase()
        }
    }

    private func advancePomodoroPhase() {
        switch pomodoroPhase {
        case .focus:
            pomodoroCompletedCycles += 1
            if pomodoroCompletedCycles >= pomodoroCycles {
                pomodoroPhase = .completed
                pomodoroSecondsRemaining = 0
                endPomodoro(recordCompletion: true)
            } else if pomodoroCompletedCycles.isMultiple(of: 4) {
                playPomodoroTransitionBell()
                shieldManager.endShield(mode: .pomodoro)
                pomodoroPhase = .longBreak
                pomodoroSecondsRemaining = pomodoroLongBreakMinutes * 60
                lastBreakBreathingPhase = nil
                emitPomodoroBreakBreathingCue(force: true)
            } else {
                playPomodoroTransitionBell()
                shieldManager.endShield(mode: .pomodoro)
                pomodoroPhase = .shortBreak
                pomodoroSecondsRemaining = pomodoroShortBreakMinutes * 60
                lastBreakBreathingPhase = nil
                emitPomodoroBreakBreathingCue(force: true)
            }

        case .shortBreak, .longBreak:
            SettleBellService.shared.stopBreathingCues()
            playPomodoroTransitionBell()
            pomodoroPhase = .focus
            pomodoroSecondsRemaining = pomodoroFocusMinutes * 60
            startPomodoroShieldIfPossible()

        case .completed:
            endPomodoro(recordCompletion: true)
        }
    }

    private func playPomodoroTransitionBell() {
        if soundEnabled {
            SettleBellService.shared.playIntervalBell()
        }
    }

    private func endPomodoro(recordCompletion: Bool) {
        let actualMinutes = max(1, Int((Double(pomodoroFocusSecondsCompleted + pomodoroBreakSecondsCompleted) / 60.0).rounded(.up)))
        let completedCycles = pomodoroCompletedCycles
        let hadProtectedFocus = pomodoroShieldWasActive

        pomodoroState = recordCompletion ? .completed : .idle
        pomodoroShieldWasActive = false
        shieldManager.endShield(mode: .pomodoro)
        SettleBellService.shared.stop()
        SettleBellService.shared.stopBreathingCues()
        lastBreakBreathingPhase = nil

        if recordCompletion, pomodoroFocusSecondsCompleted > 0 {
            let focusMinutes = Int((Double(pomodoroFocusSecondsCompleted) / 60.0).rounded(.down))
            let seeds = min(12, max(2, focusMinutes / 10 + completedCycles))
            let action = clarityStore.record(
                kind: .pomodoroSession,
                title: "\(completedCycles)-cycle Pomodoro",
                seeds: seeds,
                minutes: actualMinutes,
                note: "Completed a mindful focus cycle"
            )
            if hadProtectedFocus {
                clarityStore.record(
                    kind: .screenTimeLimitKept,
                    title: "Protected Pomodoro",
                    seeds: 1,
                    minutes: focusMinutes,
                    note: "Kept selected apps limited during Pomodoro focus"
                )
            }
            completedPomodoroSummary = MindfulCompletionSummary(
                title: "Focus cycle complete",
                seeds: action.seeds,
                minutes: actualMinutes,
                symbolName: "timer.circle.fill",
                tint: MoriColors.forestClay
            )
            if soundEnabled {
                SettleBellService.shared.playEndingBell()
            }
        } else {
            completedPomodoroSummary = nil
            resetPomodoroClock()
        }
    }

    private func startPomodoroShieldIfPossible() {
        guard pomodoroPhase == .focus,
              shieldManager.isAuthorized,
              shieldManager.hasSelection
        else {
            return
        }

        let endDate = Date().addingTimeInterval(TimeInterval(max(1, pomodoroSecondsRemaining)))
        shieldManager.startShield(mode: .pomodoro, endDate: endDate)
        if shieldManager.activeSession?.mode == .pomodoro {
            pomodoroShieldWasActive = true
        }
    }

    private func requestClose() {
        if pomodoroState == .running || pomodoroState == .paused {
            showLeaveDialog = true
        } else {
            dismiss()
        }
    }

    private func emitPomodoroBreakBreathingCue(force: Bool = false) {
        guard soundEnabled,
              pomodoroState == .running,
              pomodoroPhase.isBreak,
              let preset = pomodoroBreakBreathing.preset
        else {
            return
        }

        let phase = preset.phase(at: pomodoroCurrentPhaseElapsedSeconds).phase
        guard force || phase != lastBreakBreathingPhase else { return }

        lastBreakBreathingPhase = phase
        SettleBellService.shared.playBreathingCue(phase.breathingCue)
    }
}

private enum SettlePracticeMode: String, CaseIterable, Identifiable {
    case settle
    case breathing
    case pomodoro

    var id: String { rawValue }

    var title: String {
        switch self {
        case .settle: return "Settle"
        case .breathing: return "Breathing"
        case .pomodoro: return "Pomodoro"
        }
    }

    var symbolName: String {
        switch self {
        case .settle: return "figure.mind.and.body"
        case .breathing: return "wind"
        case .pomodoro: return "timer"
        }
    }
}

private struct MindfulCompletionSummary {
    let title: String
    let seeds: Int
    let minutes: Int
    let symbolName: String
    let tint: Color
}

private struct SettlePracticeCard: View {
    let mode: SettlePracticeMode
    let title: String
    let subtitle: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: mode.symbolName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 46, height: 46)
                .background(tint.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)

                    Text(detail)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tint.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 10)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(MoriColors.forestMuted.opacity(0.7))
        }
        .padding(16)
        .background(MoriColors.forestPaperDeep.opacity(0.58))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MoriColors.forestLine.opacity(0.52), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private func completionBanner(_ session: SettleSession, seedsOverride: Int? = nil) -> some View {
    HStack(alignment: .center, spacing: 12) {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(MoriColors.forestMoss)

        VStack(alignment: .leading, spacing: 3) {
            Text("Practice complete")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.forestCanopy)

            let seeds = seedsOverride ?? session.seedsEarned
            Text("\(session.durationText) planted \(seeds) Seeds.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
        }

        Spacer()
    }
    .padding(14)
    .background(MoriColors.forestMoss.opacity(0.10))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
}

private func mindfulCompletionBanner(_ summary: MindfulCompletionSummary) -> some View {
    HStack(alignment: .center, spacing: 12) {
        Image(systemName: summary.symbolName)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(summary.tint)

        VStack(alignment: .leading, spacing: 3) {
            Text(summary.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.forestCanopy)

            Text("\(summary.minutes)m completed · \(summary.seeds) Seeds")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
        }

        Spacer()
    }
    .padding(14)
    .background(summary.tint.opacity(0.10))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
}

private func settleControlButton(
    title: String,
    symbolName: String,
    tint: Color,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        Label(title, systemImage: symbolName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(MoriColors.forestCard)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    .buttonStyle(.plain)
}

private func formatTime(_ seconds: Int) -> String {
    let minutes = max(0, seconds) / 60
    let seconds = max(0, seconds) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

private enum MoriBreathingPreset: String, CaseIterable, Identifiable {
    case calm
    case box
    case reset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: return "Calm 4-6"
        case .box: return "Box 4-4-4-4"
        case .reset: return "Reset 4-4"
        }
    }

    var symbolName: String {
        switch self {
        case .calm: return "leaf"
        case .box: return "square"
        case .reset: return "wind"
        }
    }

    var tint: Color {
        switch self {
        case .calm: return MoriColors.forestMoss
        case .box: return MoriColors.forestClay
        case .reset: return MoriColors.forestMist
        }
    }

    var segments: [BreathingCycleSegment] {
        switch self {
        case .calm:
            return [
                BreathingCycleSegment(phase: .inhale, label: "Inhale", duration: 4),
                BreathingCycleSegment(phase: .exhale, label: "Exhale", duration: 6)
            ]
        case .box:
            return [
                BreathingCycleSegment(phase: .inhale, label: "Inhale", duration: 4),
                BreathingCycleSegment(phase: .hold, label: "Hold", duration: 4),
                BreathingCycleSegment(phase: .exhale, label: "Exhale", duration: 4),
                BreathingCycleSegment(phase: .hold, label: "Hold", duration: 4)
            ]
        case .reset:
            return [
                BreathingCycleSegment(phase: .inhale, label: "Inhale", duration: 4),
                BreathingCycleSegment(phase: .exhale, label: "Exhale", duration: 4)
            ]
        }
    }

    func phase(at elapsedSeconds: Int) -> BreathingCycleState {
        let cycleDuration = max(1, segments.reduce(0) { $0 + $1.duration })
        let elapsedInCycle = elapsedSeconds % cycleDuration
        var cursor = 0

        for segment in segments {
            let start = cursor
            cursor += segment.duration
            if elapsedInCycle < cursor {
                let progress = Double(elapsedInCycle - start) / Double(max(1, segment.duration))
                return BreathingCycleState(
                    label: segment.label,
                    phase: segment.phase,
                    progress: min(1, max(0, progress))
                )
            }
        }

        return BreathingCycleState(label: "Inhale", phase: .inhale, progress: 0)
    }

    var timingDescription: String {
        segments
            .map { "\($0.label) \($0.duration)s" }
            .joined(separator: " · ")
    }
}

private enum MoriPomodoroBreakBreathing: String, CaseIterable, Identifiable {
    case none
    case calm
    case box
    case reset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "None"
        case .calm: return MoriBreathingPreset.calm.title
        case .box: return MoriBreathingPreset.box.title
        case .reset: return MoriBreathingPreset.reset.title
        }
    }

    var symbolName: String {
        switch self {
        case .none: return "nosign"
        case .calm: return MoriBreathingPreset.calm.symbolName
        case .box: return MoriBreathingPreset.box.symbolName
        case .reset: return MoriBreathingPreset.reset.symbolName
        }
    }

    var tint: Color {
        switch self {
        case .none: return MoriColors.forestMuted
        case .calm: return MoriBreathingPreset.calm.tint
        case .box: return MoriBreathingPreset.box.tint
        case .reset: return MoriBreathingPreset.reset.tint
        }
    }

    var preset: MoriBreathingPreset? {
        switch self {
        case .none: return nil
        case .calm: return .calm
        case .box: return .box
        case .reset: return .reset
        }
    }
}

private enum BreathingCyclePhase: Equatable {
    case inhale
    case hold
    case exhale

    var breathingCue: SettleBreathingCue {
        switch self {
        case .inhale: return .inhale
        case .hold: return .hold
        case .exhale: return .exhale
        }
    }
}

private struct BreathingCycleSegment: Equatable {
    let phase: BreathingCyclePhase
    let label: String
    let duration: Int
}

private struct BreathingCycleState: Equatable {
    let label: String
    let phase: BreathingCyclePhase
    let progress: Double

    var scale: CGFloat {
        let eased = 0.5 - 0.5 * cos(.pi * progress)
        switch phase {
        case .inhale:
            return 0.86 + CGFloat(eased) * 0.20
        case .hold:
            return 1.06
        case .exhale:
            return 1.06 - CGFloat(eased) * 0.20
        }
    }

    var phaseProgress: Double {
        switch phase {
        case .exhale:
            return 1 - progress
        default:
            return progress
        }
    }
}

private enum MoriPomodoroPhase: String, Equatable {
    case focus
    case shortBreak
    case longBreak
    case completed

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        case .completed: return "Completed"
        }
    }

    var runningSubtitle: String {
        switch self {
        case .focus: return "Stay with one meaningful task."
        case .shortBreak: return "Let the mind breathe before the next round."
        case .longBreak: return "Take a longer pause and come back clean."
        case .completed: return "A focused action has become a Seed."
        }
    }

    var symbolName: String {
        switch self {
        case .focus: return "timer"
        case .shortBreak: return "leaf.fill"
        case .longBreak: return "sun.min"
        case .completed: return "checkmark.seal"
        }
    }

    var tint: Color {
        switch self {
        case .focus: return MoriColors.forestCanopy
        case .shortBreak: return MoriColors.forestMist
        case .longBreak: return MoriColors.forestSeed
        case .completed: return MoriColors.forestMoss
        }
    }

    var isBreak: Bool {
        self == .shortBreak || self == .longBreak
    }

    func durationSeconds(focusMinutes: Int, shortBreakMinutes: Int, longBreakMinutes: Int) -> Int {
        switch self {
        case .focus: return focusMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        case .completed: return 0
        }
    }
}

private enum SettleTimerState: Equatable {
    case idle
    case running
    case paused
    case completed

    var label: String {
        switch self {
        case .idle: return "ready"
        case .running: return "settling"
        case .paused: return "paused"
        case .completed: return "complete"
        }
    }

    var subtitle: String {
        switch self {
        case .idle: return "Choose a duration and let the forest get quiet."
        case .running: return "Stay with the bell and the breath."
        case .paused: return "The practice is waiting."
        case .completed: return "A mindful action has become a Seed."
        }
    }

    var symbolName: String {
        switch self {
        case .idle: return "leaf"
        case .running: return "figure.mind.and.body"
        case .paused: return "pause.circle"
        case .completed: return "checkmark.seal"
        }
    }

    var canChangeDuration: Bool {
        self == .idle || self == .completed
    }
}

private struct SettleRecommendationCard: View {
    let recommendedMinutes: Int
    let weeklySummary: SettleWeeklySummary
    let onUseRecommendation: () -> Void
    let onStartRecommendation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "leaf.arrow.circlepath")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MoriColors.forestMoss)
                    .frame(width: 38, height: 38)
                    .background(MoriColors.forestMoss.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Recommended practice")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.forestMoss)

                    Text("\(recommendedMinutes) minutes to settle")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)

                    Text(recommendationCopy)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button(action: onUseRecommendation) {
                    Label("Set duration", systemImage: "timer")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(MoriColors.forestCanopy.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onStartRecommendation) {
                    Label("Start", systemImage: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(MoriColors.forestCanopy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var recommendationCopy: String {
        if weeklySummary.completedSessions == 0 {
            return "A small first sit is enough to turn noise into presence."
        }

        if weeklySummary.consistencyDays >= 4 {
            return "Your roots are steady enough for a slightly deeper sit."
        }

        return "Keep the rhythm gentle and repeatable."
    }
}

private struct SettleLeafPulse: View {
    let isActive: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(MoriColors.forestSage.opacity(isActive ? 0.18 : 0.10))
                .frame(width: pulse && isActive ? 136 : 112, height: pulse && isActive ? 136 : 112)

            Circle()
                .fill(MoriColors.forestPaperDeep.opacity(0.8))
                .frame(width: 88, height: 88)

            Image(systemName: "leaf.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(MoriColors.forestMoss)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct BreathingOrbTimer: View {
    let preset: MoriBreathingPreset
    let elapsedSeconds: Int
    let secondsRemaining: Int
    let isRunning: Bool
    let isPaused: Bool
    let progress: CGFloat

    private var state: BreathingCycleState {
        preset.phase(at: elapsedSeconds)
    }

    private var timeText: String {
        let minutes = max(0, secondsRemaining) / 60
        let seconds = max(0, secondsRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(MoriColors.forestLine.opacity(0.62), lineWidth: 13)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    preset.tint,
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)

            ZStack {
                Circle()
                    .fill(preset.tint.opacity(isRunning ? 0.18 : 0.10))
                    .frame(width: 132, height: 132)
                    .scaleEffect(isRunning && !isPaused ? state.scale : 0.92)
                    .animation(.easeInOut(duration: 0.9), value: state.scale)

                Circle()
                    .fill(MoriColors.forestPaperDeep.opacity(0.86))
                    .frame(width: 92, height: 92)

                VStack(spacing: 7) {
                    Text(timeText)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)
                        .monospacedDigit()
                        .minimumScaleFactor(0.78)

                    Text(isPaused ? "Paused" : state.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.forestMuted)
                }
            }

            VStack {
                Spacer()

                Text(preset.timingDescription)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.forestMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(MoriColors.forestCanopy.opacity(0.07))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 244)
    }
}

private struct SettleHistoryRow: View {
    let session: SettleSession

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: session.completed ? "checkmark.circle.fill" : "stop.circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(session.completed ? MoriColors.forestMoss : MoriColors.forestClay)
                .frame(width: 34, height: 34)
                .background((session.completed ? MoriColors.forestMoss : MoriColors.forestClay).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.forestCanopy)

                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.durationText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.forestCanopy)

                if session.seedsEarned > 0 {
                    Text("+\(session.seedsEarned)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestRoot)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(MoriColors.forestSeed.opacity(0.20))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(MoriColors.forestPaperDeep.opacity(0.48))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    SettleView()
        .environmentObject(UserSettings())
}
