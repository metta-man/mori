import Combine
import SwiftUI

private struct MoriWatchPracticeLaunch: Identifiable {
    let id = UUID()
    let practice: MoriWatchPractice
    let autoStart: Bool
}

struct MoriWatchResetHub: View {
    @ObservedObject var notificationCenter: MoriWatchNotificationCenter
    @State private var snapshot = MoriWidgetSnapshot()
    @State private var context = MoriWidgetContextSnapshot.load()
    @State private var activePractice: MoriWatchPracticeLaunch?
    @AppStorage(MoriWatchBellDefaults.isActiveKey) private var bellIsActive = false
    @AppStorage(MoriWatchBellDefaults.nextFireKey) private var nextBellTimestamp: Double = 0

    private let snapshotTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                homeContent
            }
            .moriWatchPaperBackground()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $activePractice) { launch in
                MoriWatchPracticeDetail(
                    practice: launch.practice,
                    autoStart: launch.autoStart
                )
            }
            .onReceive(snapshotTimer) { now in
                snapshot = MoriWidgetSnapshot(now: now)
                context = MoriWidgetContextSnapshot.load()
            }
            .onChange(of: notificationCenter.quickBreathingRequestID) { _, requestID in
                guard requestID != nil else { return }
                openPractice(.breathe, autoStart: true)
            }
        }
    }

    private var homeContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            lifeRemainingHero
            practiceLaunchGrid
            compactContextStrip
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var lifeRemainingHero: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 6) {
                MoriBitmapIconImage(icon: .roots, size: 15, opacity: 0.82)

                Text(MoriL10n.string("watch.life.title", defaultValue: "Life weeks left"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWatchPalette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                Spacer(minLength: 4)

                Text(snapshot.archiveProgressPercentText)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWatchPalette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .monospacedDigit()
            }

            Text(MoriL10n.string(
                "watch.life.weeks_left",
                defaultValue: "%@ weeks",
                arguments: [lifeWeeksLeft.formatted()]
            ))
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .foregroundStyle(MoriWatchPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.48)
                .monospacedDigit()

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(MoriL10n.string(
                    "watch.life.days_left",
                    defaultValue: "%@ days",
                    arguments: [lifeDaysLeft.formatted()]
                ))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MoriWatchPalette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                    .monospacedDigit()

                Text(MoriL10n.string(
                    "watch.life.current_week",
                    defaultValue: "Week %@",
                    arguments: [snapshot.archiveWeekNumber.formatted()]
                ))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(MoriWatchPalette.muted.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                    .monospacedDigit()
            }

            ProgressView(value: snapshot.progress)
                .tint(MoriWatchPalette.moss.opacity(0.72))
                .frame(height: 4)
        }
        .padding(10)
        .moriWatchCard(cornerRadius: 14)
        .accessibilityElement(children: .combine)
    }

    private var lifeWeeksLeft: Int {
        max(snapshot.totalWeeks - snapshot.archiveWeeksElapsed, 0)
    }

    private var lifeDaysLeft: Int {
        let calendar = Calendar.current
        let endDate = calendar.date(
            byAdding: .year,
            value: snapshot.archiveSpanYears,
            to: snapshot.archiveStartDate
        ) ?? snapshot.now
        let remainingDays = calendar.dateComponents([.day], from: snapshot.now, to: endDate).day ?? 0
        return max(remainingDays, 0)
    }

    private var practiceLaunchGrid: some View {
        LazyVGrid(columns: homeGridColumns, spacing: 5) {
            ForEach(MoriWatchPractice.launchTiles) { practice in
                Button {
                    openPractice(practice, autoStart: practice == .breathe)
                } label: {
                    MoriWatchPracticeLaunchTile(
                        practice: practice,
                        subtitle: practiceTileSubtitle(practice),
                        isPrimary: practice == .breathe
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel(for: practice))
            }
        }
    }

    private var homeGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 5),
            GridItem(.flexible(), spacing: 5)
        ]
    }

    private var compactContextStrip: some View {
        HStack(spacing: 6) {
            if context.hasRecoverySnapshot {
                MoriWatchStatusChip(
                    icon: .heart,
                    title: MoriL10n.string("recovery.widget.score", defaultValue: "Recovery %@", arguments: [context.recoveryScoreText]),
                    value: context.displayRecoveryState
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                MoriWatchStatusChip(
                    icon: .pulse,
                    title: MoriL10n.string("widget.inline.bloom", defaultValue: "Bloom %@", arguments: [context.bloomPercentText]),
                    value: MoriL10n.string("practice.seed.count", defaultValue: "%d Seeds", arguments: [context.seedsToday])
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            MoriWatchStatusChip(
                icon: .bell,
                title: MoriL10n.string("watch.home.bell_short", defaultValue: "Bell"),
                value: bellStatusText
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private func practiceTileSubtitle(_ practice: MoriWatchPractice) -> String {
        switch practice {
        case .breathe:
            return MoriL10n.string("watch.home.breathe_now.subtitle", defaultValue: "1 minute reset")
        case .settle:
            return MoriL10n.string("watch.home.settle.subtitle", defaultValue: "3 minute pause")
        case .pomodoro:
            return MoriL10n.string("watch.home.focus.subtitle", defaultValue: "25 minute focus")
        case .bell:
            return bellStatusText
        }
    }

    private func accessibilityLabel(for practice: MoriWatchPractice) -> String {
        if practice == .breathe {
            return MoriL10n.string(
                "watch.home.breathe_now.accessibility",
                defaultValue: "Breathe now. Starts a one minute guided reset."
            )
        }

        return "\(practice.watchHomeTitle). \(practiceTileSubtitle(practice))"
    }

    private func openPractice(_ practice: MoriWatchPractice, autoStart: Bool) {
        activePractice = MoriWatchPracticeLaunch(practice: practice, autoStart: autoStart)
    }

    private var bellStatusText: String {
        guard bellIsActive else { return MoriL10n.string("bell.status.paused", defaultValue: "Bell paused") }
        guard nextBellTimestamp > 0 else { return MoriL10n.string("bell.status.scheduled", defaultValue: "Bell scheduled") }

        let nextDate = Date(timeIntervalSince1970: nextBellTimestamp)
        if nextDate <= Date() { return MoriL10n.string("bell.status.refreshing_watch", defaultValue: "Bell refreshing") }

        let minutes = max(1, Int((nextDate.timeIntervalSinceNow / 60.0).rounded(.up)))
        return MoriL10n.string("bell.status.next_minutes", defaultValue: "Next bell in %dm", arguments: [minutes])
    }
}

private struct MoriWatchPracticeLaunchTile: View {
    let practice: MoriWatchPractice
    let subtitle: String
    let isPrimary: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                MoriBitmapIconImage(icon: practice.bitmapIcon, size: 14, opacity: 0.92)
                    .frame(width: 21, height: 21)
                    .background(practice.tint.opacity(isPrimary ? 0.22 : 0.13))
                    .clipShape(Circle())

                Text(practice.watchHomeTitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWatchPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                Spacer(minLength: 0)
            }

            Text(subtitle)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(MoriWatchPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, minHeight: 47, alignment: .leading)
        .background {
            MoriWatchCardBackground(cornerRadius: 14)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(practice.tint.opacity(isPrimary ? 0.34 : 0.18), lineWidth: isPrimary ? 1.1 : 0.8)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct MoriWatchStatusChip: View {
    let icon: MoriBitmapIcon
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 5) {
            MoriBitmapIconImage(icon: icon, size: 10, opacity: 0.78)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWatchPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)

                Text(value)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(MoriWatchPalette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .frame(minHeight: 26, alignment: .leading)
        .background(MoriWatchPalette.surface.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(MoriWatchPalette.line.opacity(0.42), lineWidth: 0.7)
        }
    }
}

private struct MoriWatchPracticeDetail: View {
    let practice: MoriWatchPractice
    let autoStart: Bool

    var body: some View {
        switch practice {
        case .breathe:
            MoriWatchTimerView(practice: .breathe, autoStart: autoStart)
        case .settle:
            MoriWatchTimerView(practice: .settle, autoStart: autoStart)
        case .pomodoro:
            MoriWatchTimerView(practice: .pomodoro, autoStart: autoStart)
        case .bell:
            MoriWatchBellSettingsView()
        }
    }
}

private extension MoriWatchPractice {
    var watchHomeTitle: String {
        switch self {
        case .breathe:
            return MoriL10n.string("watch.home.breathe", defaultValue: "Breathe")
        case .settle:
            return MoriL10n.string("watch.home.settle", defaultValue: "Settle")
        case .pomodoro:
            return MoriL10n.string("watch.home.focus", defaultValue: "Focus")
        case .bell:
            return MoriL10n.string("watch.home.bell", defaultValue: "Bell")
        }
    }

    var watchDetailTitle: String {
        switch self {
        case .breathe:
            return MoriL10n.string("watch.detail.breathe.title", defaultValue: "Guided breath")
        case .settle:
            return MoriL10n.string("watch.detail.settle.title", defaultValue: "Quiet pause")
        case .pomodoro:
            return MoriL10n.string("watch.detail.focus.title", defaultValue: "Focus cycle")
        case .bell:
            return MoriL10n.string("watch.detail.bell.title", defaultValue: "Mindfulness bell")
        }
    }

    var watchDetailPromise: String {
        switch self {
        case .breathe:
            return MoriL10n.string("watch.detail.breathe.promise", defaultValue: "Follow the wrist taps and let the next minute clear the noise.")
        case .settle:
            return MoriL10n.string("watch.detail.settle.promise", defaultValue: "A short timer for stepping away before you continue.")
        case .pomodoro:
            return MoriL10n.string("watch.detail.focus.promise", defaultValue: "Work in one protected block, then breathe before the next cycle.")
        case .bell:
            return MoriL10n.string("watch.detail.bell.promise", defaultValue: "Gentle wrist taps that bring you back to one breath.")
        }
    }
}

private struct MoriWatchTimerView: View {
    let practice: MoriWatchPractice
    let autoStart: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session = MoriWatchSessionModel()
    @AppStorage("mori_watch_breath_preset") private var breathPresetRaw = MoriWatchBreathPreset.coherent5.rawValue
    @AppStorage("mori_watch_breath_minutes") private var breathingMinutes = 1
    @AppStorage("mori_watch_settle_minutes") private var settleMinutes = 3
    @AppStorage("mori_watch_pomodoro_focus_minutes") private var pomodoroFocusMinutes = 25
    @AppStorage("mori_watch_pomodoro_cycles") private var pomodoroCycles = 2
    @AppStorage("mori_watch_pomodoro_break_breath_preset") private var pomodoroBreakPresetRaw = MoriWatchBreathPreset.longExhale.rawValue

    private var breathPreset: MoriWatchBreathPreset {
        MoriWatchBreathPreset(rawValue: breathPresetRaw) ?? .coherent5
    }

    private var pomodoroBreakPreset: MoriWatchBreathPreset {
        MoriWatchBreathPreset(rawValue: pomodoroBreakPresetRaw) ?? .longExhale
    }

    var body: some View {
        Group {
            if session.state.isIdle {
                idleTimerView
            } else {
                runningTimerView
            }
        }
        .moriWatchPaperBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            configureSession()
            if autoStart {
                session.start()
            }
        }
        .onDisappear {
            session.stopForViewDismissal(scenePhase: scenePhase)
        }
        .onChange(of: scenePhase) { _, phase in session.handleScenePhaseChange(phase) }
        .onChange(of: breathPresetRaw) { _, _ in configureSession() }
        .onChange(of: breathingMinutes) { _, _ in configureSession() }
        .onChange(of: settleMinutes) { _, _ in configureSession() }
        .onChange(of: pomodoroFocusMinutes) { _, _ in configureSession() }
        .onChange(of: pomodoroCycles) { _, _ in configureSession() }
        .onChange(of: pomodoroBreakPresetRaw) { _, _ in configureSession() }
    }

    private var idleTimerView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 9) {
                timerHeader
                timerRing(height: 136)
                setupControls
                controls
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
    }

    private var runningTimerView: some View {
        VStack(spacing: 8) {
            timerRing(height: 128)
            controls
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var timerHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                MoriBitmapIconImage(icon: practice.bitmapIcon, size: 20)
                    .frame(width: 32, height: 32)
                    .background(practice.tint.opacity(0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(practice.watchDetailTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MoriWatchPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    Text(timerSubtitleText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MoriWatchPalette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }

                Spacer(minLength: 0)
            }

            if session.state.isIdle {
                Text(practice.watchDetailPromise)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(MoriWatchPalette.muted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(9)
        .moriWatchCard(cornerRadius: 14)
    }

    private var timerSubtitleText: String {
        switch practice {
        case .breathe:
            return "\(session.headerTitle) · \(session.headerSubtitle)"
        case .settle, .pomodoro:
            return session.headerSubtitle
        case .bell:
            return ""
        }
    }

    private func timerRing(height: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(MoriWatchPalette.line, lineWidth: 10)

            Circle()
                .trim(from: 0, to: session.progress)
                .stroke(
                    session.activeTint,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: session.progress)

            VStack(spacing: 4) {
                Text(session.timeText)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWatchPalette.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.54)

                Text(session.phaseText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MoriWatchPalette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if !session.cycleText.isEmpty {
                    Text(session.cycleText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MoriWatchPalette.muted.opacity(0.82))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: height)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MoriL10n.string(
            "watch.practice.accessibility",
            defaultValue: "%@, %@, %@",
            arguments: [MoriL10n.display(practice.title), session.timeText, session.phaseText]
        ))
    }

    @ViewBuilder
    private var setupControls: some View {
        switch practice {
        case .breathe:
            VStack(alignment: .leading, spacing: 8) {
                setupSectionTitle("Breath pattern")

                LazyVGrid(columns: compactOptionColumns, spacing: 6) {
                    ForEach(quickBreathPresets) { preset in
                        setupOptionButton(
                            title: preset.shortTitle,
                            subtitle: preset.patternText,
                            isSelected: breathPresetRaw == preset.rawValue,
                            tint: practice.tint
                        ) {
                            breathPresetRaw = preset.rawValue
                        }
                    }
                }

                setupSectionTitle("Minutes")

                LazyVGrid(columns: compactOptionColumns, spacing: 6) {
                    ForEach([1, 2, 3, 5, 10], id: \.self) { minutes in
                        setupOptionButton(
                            title: localizedMinuteTitle(minutes),
                            subtitle: minutes == 1 ? "Quick" : "Reset",
                            isSelected: breathingMinutes == minutes,
                            tint: practice.tint
                        ) {
                            breathingMinutes = minutes
                        }
                    }
                }
            }

        case .settle:
            VStack(alignment: .leading, spacing: 7) {
                setupSectionTitle("Minutes")

                LazyVGrid(columns: compactOptionColumns, spacing: 6) {
                    ForEach([3, 5, 10, 15], id: \.self) { minutes in
                        setupOptionButton(
                            title: localizedMinuteTitle(minutes),
                            subtitle: minutes == 3 ? "Quick" : "Settle",
                            isSelected: settleMinutes == minutes,
                            tint: practice.tint
                        ) {
                            settleMinutes = minutes
                        }
                    }
                }
            }

        case .pomodoro:
            VStack(alignment: .leading, spacing: 8) {
                setupSectionTitle("Focus")

                LazyVGrid(columns: compactOptionColumns, spacing: 6) {
                    ForEach([15, 25, 45], id: \.self) { minutes in
                        setupOptionButton(
                            title: localizedMinuteTitle(minutes),
                            subtitle: minutes == 25 ? "Classic" : "Focus",
                            isSelected: pomodoroFocusMinutes == minutes,
                            tint: practice.tint
                        ) {
                            pomodoroFocusMinutes = minutes
                        }
                    }
                }

                compactStepper(
                    title: "Cycles",
                    value: pomodoroCycles,
                    range: 1...4,
                    tint: practice.tint,
                    decrement: { pomodoroCycles = max(1, pomodoroCycles - 1) },
                    increment: { pomodoroCycles = min(4, pomodoroCycles + 1) }
                )

                setupSectionTitle("Break breath")

                LazyVGrid(columns: compactOptionColumns, spacing: 6) {
                    ForEach(quickBreakBreathPresets) { preset in
                        setupOptionButton(
                            title: preset.shortTitle,
                            subtitle: preset.patternText,
                            isSelected: pomodoroBreakPresetRaw == preset.rawValue,
                            tint: MoriWatchPalette.moss
                        ) {
                            pomodoroBreakPresetRaw = preset.rawValue
                        }
                    }
                }
            }

        case .bell:
            EmptyView()
        }
    }

    private var compactOptionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }

    private var quickBreathPresets: [MoriWatchBreathPreset] {
        prioritizedBreathPresets(selectedRawValue: breathPresetRaw)
    }

    private var quickBreakBreathPresets: [MoriWatchBreathPreset] {
        prioritizedBreathPresets(selectedRawValue: pomodoroBreakPresetRaw)
    }

    private func prioritizedBreathPresets(selectedRawValue: String) -> [MoriWatchBreathPreset] {
        let recommended: [MoriWatchBreathPreset] = [.coherent5, .longExhale, .box4, .relaxing478]
        guard let selected = MoriWatchBreathPreset(rawValue: selectedRawValue),
              !recommended.contains(selected)
        else {
            return recommended
        }
        return [selected] + recommended
    }

    private func setupSectionTitle(_ title: String) -> some View {
        Text(MoriL10n.display(title))
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(MoriWatchPalette.muted)
            .padding(.horizontal, 2)
    }

    private func localizedMinuteTitle(_ minutes: Int) -> String {
        MoriL10n.string("duration.minutes_short", defaultValue: "%dm", arguments: [minutes])
    }

    private func setupOptionButton(
        title: String,
        subtitle: String,
        isSelected: Bool,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? MoriWatchPalette.background : MoriWatchPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)

                Text(MoriL10n.display(subtitle))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? MoriWatchPalette.background.opacity(0.72) : MoriWatchPalette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint.opacity(0.82))
                } else {
                    MoriWatchCardBackground(cornerRadius: 14)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func compactStepper(
        title: String,
        value: Int,
        range: ClosedRange<Int>,
        tint: Color,
        decrement: @escaping () -> Void,
        increment: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Text(MoriL10n.display(title))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MoriWatchPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.62)

            Spacer(minLength: 0)

            Button(action: decrement) {
                MoriBitmapIconImage(icon: .minus, size: 13, opacity: value <= range.lowerBound ? 0.36 : 0.88)
                    .frame(width: 28, height: 28)
            }
            .disabled(value <= range.lowerBound)
            .accessibilityLabel(MoriL10n.string(
                "watch.control.decrease_value",
                defaultValue: "Decrease %@",
                arguments: [MoriL10n.display(title)]
            ))
            .buttonStyle(MoriWatchIconButtonStyle())

            Text("\(value)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MoriWatchPalette.ink)
                .monospacedDigit()
                .frame(width: 28)

            Button(action: increment) {
                MoriBitmapIconImage(icon: .plus, size: 13, opacity: value >= range.upperBound ? 0.36 : 0.88)
                    .frame(width: 28, height: 28)
            }
            .disabled(value >= range.upperBound)
            .accessibilityLabel(MoriL10n.string(
                "watch.control.increase_value",
                defaultValue: "Increase %@",
                arguments: [MoriL10n.display(title)]
            ))
            .buttonStyle(MoriWatchIconButtonStyle(tint: tint))
        }
        .padding(8)
        .moriWatchCard(cornerRadius: 12)
    }

    private var runningContext: some View {
        HStack(spacing: 8) {
            MoriBitmapIconImage(icon: session.state == .paused ? .pause : .pulse, size: 17)

            Text(session.state.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MoriWatchPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 0)
        }
        .padding(8)
        .moriWatchCard(cornerRadius: 12)
    }

    private var controls: some View {
        HStack(spacing: 7) {
            switch session.state {
            case .idle, .completed:
                Button {
                    session.start()
                } label: {
                    controlLabel(
                        icon: .play,
                        title: session.state == .completed
                            ? MoriL10n.string("watch.control.again", defaultValue: "Again")
                            : MoriL10n.string("watch.control.start", defaultValue: "Start")
                    )
                }
                .buttonStyle(MoriWatchPrimaryButtonStyle(tint: practice.tint))

                Button {
                    configureSession(force: true)
                } label: {
                    controlLabel(icon: .refresh, title: MoriL10n.string("watch.control.reset", defaultValue: "Reset"))
                        .frame(width: 58)
                }
                .buttonStyle(MoriWatchSecondaryButtonStyle())

            case .running:
                Button {
                    session.pause()
                } label: {
                    controlLabel(icon: .pause, title: MoriL10n.string("watch.control.pause", defaultValue: "Pause"))
                }
                .buttonStyle(MoriWatchPrimaryButtonStyle(tint: practice.tint))

                stopButton

            case .paused:
                Button {
                    session.resume()
                } label: {
                    controlLabel(icon: .play, title: MoriL10n.string("watch.control.resume", defaultValue: "Resume"))
                }
                .buttonStyle(MoriWatchPrimaryButtonStyle(tint: practice.tint))

                stopButton
            }
        }
    }

    private func controlLabel(icon: MoriBitmapIcon, title: String) -> some View {
        HStack(spacing: 6) {
            MoriBitmapIconImage(icon: icon, size: 17, opacity: 0.94)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity)
    }

    private var stopButton: some View {
        Button {
            session.stop(reset: true)
        } label: {
            controlLabel(icon: .stop, title: MoriL10n.string("watch.control.end", defaultValue: "End"))
                .frame(width: 58)
        }
        .buttonStyle(MoriWatchSecondaryButtonStyle())
    }

    private func configureSession(force: Bool = false) {
        guard force || session.state.isIdle else { return }

        session.configure(
            practice: practice,
            breathPreset: breathPreset,
            breathingMinutes: breathingMinutes,
            settleMinutes: settleMinutes,
            pomodoroFocusMinutes: pomodoroFocusMinutes,
            pomodoroCycles: pomodoroCycles,
            pomodoroBreakPreset: pomodoroBreakPreset
        )
    }
}
