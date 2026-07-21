import SwiftUI

struct PomodoroActiveSessionSurface<ControlRow: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let darkRoomEnabled: Bool
    let darkRoomOffScreen: Bool
    let darkRoomControlsVisible: Bool
    let timeText: String
    let sessionLabel: String
    let blockedAppsText: String
    let blockedAppsCount: Int
    let primaryCueText: String
    let secondaryCueText: String
    let soundEnabled: Bool
    let hapticsEnabled: Bool
    let animationEnabled: Bool
    let phase: MoriPomodoroPhase
    let timerState: SettleTimerState
    let progress: CGFloat
    let isGuidedBreathing: Bool
    let activeBreathing: MoriPomodoroBreakBreathing
    let breathingVisualState: MoriBreathingCycleVisualState
    let onRevealDarkRoomControls: () -> Void
    let onExitDarkRoomOffScreen: () -> Void
    let onEnterDarkRoomOffScreen: () -> Void
    let onToggleSound: () -> Void
    let onToggleHaptics: () -> Void
    let onToggleAnimation: () -> Void
    let onToggleDarkRoom: () -> Void
    let onBack: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void
    let controlRow: () -> ControlRow
    @Binding var darkRoomDim: Double
    @State private var showsSessionOptions = false

    init(
        darkRoomEnabled: Bool,
        darkRoomDim: Binding<Double>,
        darkRoomOffScreen: Bool,
        darkRoomControlsVisible: Bool,
        timeText: String,
        sessionLabel: String,
        blockedAppsText: String,
        blockedAppsCount: Int,
        primaryCueText: String,
        secondaryCueText: String,
        soundEnabled: Bool,
        hapticsEnabled: Bool,
        animationEnabled: Bool,
        phase: MoriPomodoroPhase,
        timerState: SettleTimerState,
        progress: CGFloat,
        isGuidedBreathing: Bool,
        activeBreathing: MoriPomodoroBreakBreathing,
        breathingVisualState: MoriBreathingCycleVisualState,
        onRevealDarkRoomControls: @escaping () -> Void,
        onExitDarkRoomOffScreen: @escaping () -> Void,
        onEnterDarkRoomOffScreen: @escaping () -> Void,
        onToggleSound: @escaping () -> Void,
        onToggleHaptics: @escaping () -> Void,
        onToggleAnimation: @escaping () -> Void,
        onToggleDarkRoom: @escaping () -> Void,
        onBack: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onResume: @escaping () -> Void,
        onEnd: @escaping () -> Void,
        @ViewBuilder controlRow: @escaping () -> ControlRow
    ) {
        self.darkRoomEnabled = darkRoomEnabled
        _darkRoomDim = darkRoomDim
        self.darkRoomOffScreen = darkRoomOffScreen
        self.darkRoomControlsVisible = darkRoomControlsVisible
        self.timeText = timeText
        self.sessionLabel = sessionLabel
        self.blockedAppsText = blockedAppsText
        self.blockedAppsCount = blockedAppsCount
        self.primaryCueText = primaryCueText
        self.secondaryCueText = secondaryCueText
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.animationEnabled = animationEnabled
        self.phase = phase
        self.timerState = timerState
        self.progress = progress
        self.isGuidedBreathing = isGuidedBreathing
        self.activeBreathing = activeBreathing
        self.breathingVisualState = breathingVisualState
        self.onRevealDarkRoomControls = onRevealDarkRoomControls
        self.onExitDarkRoomOffScreen = onExitDarkRoomOffScreen
        self.onEnterDarkRoomOffScreen = onEnterDarkRoomOffScreen
        self.onToggleSound = onToggleSound
        self.onToggleHaptics = onToggleHaptics
        self.onToggleAnimation = onToggleAnimation
        self.onToggleDarkRoom = onToggleDarkRoom
        self.onBack = onBack
        self.onPause = onPause
        self.onResume = onResume
        self.onEnd = onEnd
        self.controlRow = controlRow
    }

    var body: some View {
        Group {
            if darkRoomEnabled {
                MoriDarkRoomSessionSurface(
                    timeText: timeText,
                    sessionLabel: sessionLabel,
                    cueText: primaryCueText,
                    cueStatus: MoriDarkRoomCueStatus.current(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled),
                    dim: $darkRoomDim,
                    isFullBlack: darkRoomOffScreen,
                    controlsVisible: darkRoomControlsVisible,
                    onRevealControls: onRevealDarkRoomControls,
                    onExitFullBlack: onExitDarkRoomOffScreen
                ) {
                    darkRoomControlPanel
                }
            } else {
                normalActiveSurface
            }
        }
    }

    private var normalActiveSurface: some View {
        GeometryReader { proxy in
            ZStack {
                MoriV2Palette.paper

                Image("MoriActiveDeepSessionValley")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .scaleEffect(1.16)
                    .offset(y: -proxy.size.height * 0.065)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(animationEnabled ? 1 : 0.88)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                LinearGradient(
                    stops: [
                        .init(color: MoriV2Palette.raisedPaper.opacity(0.98), location: 0),
                        .init(color: MoriV2Palette.raisedPaper.opacity(0.94), location: 0.075),
                        .init(color: MoriV2Palette.raisedPaper.opacity(0.32), location: 0.18),
                        .init(color: .clear, location: 0.27)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.76),
                        .init(color: MoriV2Palette.raisedPaper.opacity(0.12), location: 0.84),
                        .init(color: MoriV2Palette.raisedPaper.opacity(0.58), location: 0.94),
                        .init(color: MoriV2Palette.raisedPaper.opacity(0.82), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                if dynamicTypeSize.isAccessibilitySize || proxy.size.height < 760 {
                    accessibleActiveContent(in: proxy)
                } else {
                    positionedActiveContent(in: proxy)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func positionedActiveContent(in proxy: GeometryProxy) -> some View {
        let verticalScale = proxy.size.height / 932
        let panelWidth = max(280, min(390, proxy.size.width - 40))
        let ringSize = max(248, min(288, proxy.size.width - 72))

        return ZStack {
            activeHeader
                .frame(width: max(0, proxy.size.width - 16), height: 44)
                .position(x: proxy.size.width / 2, y: 82 * verticalScale)

            Image(systemName: "leaf")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(MoriV2Palette.forestInk.opacity(0.58))
                .position(x: proxy.size.width / 2, y: 97 * verticalScale)

            Text(MoriL10n.display(sessionLabel))
                .font(.system(size: 31, weight: .regular, design: .serif))
                .foregroundColor(MoriV2Palette.forestInk)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .position(x: proxy.size.width / 2, y: 135 * verticalScale)

            Text(MoriL10n.display(primaryCueText))
                .font(MoriV2Type.supporting)
                .foregroundColor(MoriV2Palette.stone)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .position(x: proxy.size.width / 2, y: 167 * verticalScale)

            activeTimerVisual(size: ringSize)
                .position(x: proxy.size.width / 2, y: 345 * verticalScale)

            normalSessionControl
                .position(
                    x: proxy.size.width / 2,
                    y: (timerState == .paused ? 575 : 574) * verticalScale
                )

            blockedAppsCard
                .frame(width: panelWidth, height: 135)
                .position(
                    x: proxy.size.width / 2,
                    y: 632 * verticalScale + 67.5
                )

            sessionOptionsCard
                .frame(width: panelWidth, height: 69)
                .position(
                    x: proxy.size.width / 2,
                    y: 795 * verticalScale + 34.5
                )
        }
    }

    private func accessibleActiveContent(in proxy: GeometryProxy) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                activeHeader
                    .frame(height: 44)

                VStack(spacing: 5) {
                    Image(systemName: "leaf")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(MoriV2Palette.forestInk.opacity(0.58))

                    Text(MoriL10n.display(sessionLabel))
                        .font(MoriV2Type.cardTitle)
                        .foregroundColor(MoriV2Palette.forestInk)
                        .multilineTextAlignment(.center)

                    Text(MoriL10n.display(primaryCueText))
                        .font(MoriV2Type.supporting)
                        .foregroundColor(MoriV2Palette.stone)
                        .multilineTextAlignment(.center)
                }

                activeTimerVisual(size: min(276, max(232, proxy.size.width - 88)))

                normalSessionControl

                blockedAppsCard
                    .frame(minHeight: 145)

                sessionOptionsCard
                    .frame(minHeight: 69)
            }
            .padding(.horizontal, 20)
            .padding(.top, max(54, proxy.safeAreaInsets.top + 8))
            .padding(.bottom, max(28, proxy.safeAreaInsets.bottom + 18))
        }
    }

    private var activeHeader: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundColor(MoriV2Palette.forestInk.opacity(0.88))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(MoriL10n.display("Back"))

            Spacer(minLength: 0)

            Button(action: toggleSessionOptions) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(MoriV2Palette.forestInk.opacity(0.92))
                    .offset(x: -4)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(MoriL10n.display(
                showsSessionOptions ? "Hide session options" : "Show session options"
            ))
        }
    }

    private func activeTimerVisual(size: CGFloat) -> some View {
        PomodoroActiveVisual(
            isGuidedBreathing: isGuidedBreathing,
            activeBreathing: activeBreathing,
            breathingVisualState: breathingVisualState,
            timerState: timerState,
            phase: phase,
            progress: progress,
            primaryCueText: primaryCueText,
            timeText: timeText,
            trackTint: MoriV2Palette.forestInk.opacity(0.12),
            animationEnabled: animationEnabled
        )
        .frame(width: size, height: size)
        .accessibilityHint(Text(MoriL10n.display(secondaryCueText)))
    }

    private var normalSessionControl: some View {
        VStack(spacing: 3) {
            Button(action: timerState == .paused ? onResume : onPause) {
                Image(systemName: timerState == .paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundColor(MoriV2Palette.forestInk.opacity(0.92))
                    .frame(width: 66, height: 66)
                    .background(MoriV2Palette.raisedPaper.opacity(0.96))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.68), lineWidth: 1)
                    )
                    .shadow(color: MoriV2Palette.shadow.opacity(0.85), radius: 13, x: 0, y: 7)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(MoriL10n.display(timerState == .paused ? "Resume" : "Pause"))

            if timerState == .paused {
                Button(action: onEnd) {
                    Text(MoriL10n.display("End quietly"))
                        .font(MoriV2Type.caption)
                        .foregroundColor(MoriV2Palette.forestInk)
                        .frame(minWidth: 92, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var blockedAppsCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(MoriL10n.display("Blocked apps"))
                    .font(MoriV2Type.control)
                    .foregroundColor(MoriV2Palette.forestInk)

                Spacer(minLength: 0)

                Text(blockedSelectionCountText)
                    .font(MoriV2Type.supporting)
                    .foregroundColor(MoriV2Palette.mutedStone)
            }

            HStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundColor(MoriV2Palette.forestInk.opacity(0.76))
                    .frame(width: 48, height: 48)
                    .background(MoriV2Palette.forestInk.opacity(0.065))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text(MoriL10n.display(blockedAppsText))
                    .font(MoriV2Type.supporting)
                    .foregroundColor(MoriV2Palette.stone)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 17)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .pomodoroActivePaperPanel(cornerRadius: 22)
        .accessibilityElement(children: .combine)
    }

    private var blockedSelectionCountText: String {
        MoriL10n.string(
            "deep_session.blocked_apps.compact_count",
            defaultValue: "%d apps",
            arguments: [blockedAppsCount]
        )
    }

    private var sessionOptionsCard: some View {
        Group {
            if showsSessionOptions && dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 5) {
                        sessionOptionsLabel
                        Spacer(minLength: 5)
                        sessionOptionsDisclosureButton
                    }

                    HStack(spacing: 5) {
                        Spacer(minLength: 0)
                        sessionOptionButtons
                    }
                }
                .padding(.leading, 20)
            } else {
                HStack(spacing: 5) {
                    sessionOptionsLabel

                    Spacer(minLength: 5)

                    if showsSessionOptions {
                        sessionOptionButtons
                    }

                    sessionOptionsDisclosureButton
                }
                .padding(.leading, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pomodoroActivePaperPanel(cornerRadius: 22)
        .animation(MoriV2Motion.disclosure, value: showsSessionOptions)
    }

    private var sessionOptionsLabel: some View {
        Text(MoriL10n.display("Session options"))
            .font(MoriV2Type.supporting)
            .foregroundColor(MoriV2Palette.forestInk)
            .lineLimit(1)
            .minimumScaleFactor(0.70)
    }

    @ViewBuilder
    private var sessionOptionButtons: some View {
        PomodoroActiveOptionButton(
            isOn: soundEnabled,
            icon: soundEnabled ? .sound : .quiet,
            label: soundEnabled ? "Sound on" : "Sound off",
            action: onToggleSound
        )

        PomodoroActiveOptionButton(
            isOn: hapticsEnabled,
            icon: hapticsEnabled ? .haptics : .minus,
            label: hapticsEnabled ? "Haptics on" : "Haptics off",
            action: onToggleHaptics
        )

        PomodoroActiveOptionButton(
            isOn: animationEnabled,
            icon: animationEnabled ? .roots : .focus,
            label: animationEnabled ? "Animation on" : "Animation off",
            action: onToggleAnimation
        )

        PomodoroActiveOptionButton(
            isOn: darkRoomEnabled,
            icon: darkRoomEnabled ? .quiet : .leaf,
            label: darkRoomEnabled ? "Dark room on" : "Dark room off",
            action: onToggleDarkRoom
        )
    }

    private var sessionOptionsDisclosureButton: some View {
        Button(action: toggleSessionOptions) {
            Image(systemName: showsSessionOptions ? "minus" : "chevron.right")
                .font(.system(size: showsSessionOptions ? 15 : 16, weight: .regular))
                .foregroundColor(MoriV2Palette.forestInk.opacity(0.64))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display(
            showsSessionOptions ? "Hide session options" : "Show session options"
        ))
    }

    private func toggleSessionOptions() {
        showsSessionOptions.toggle()
    }

    private var darkRoomControlPanel: some View {
        VStack(spacing: 14) {
            toggleRow

            HStack(spacing: 12) {
                MoriDarkRoomDimControl(dim: $darkRoomDim)
                MoriDarkRoomFullBlackButton(action: onEnterDarkRoomOffScreen)
            }

            controlRow()
        }
    }

    private var toggleRow: some View {
        PomodoroActiveToggleRow(
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            animationEnabled: animationEnabled,
            darkRoomEnabled: darkRoomEnabled,
            onToggleSound: onToggleSound,
            onToggleHaptics: onToggleHaptics,
            onToggleAnimation: onToggleAnimation,
            onToggleDarkRoom: onToggleDarkRoom
        )
    }

}

private struct PomodoroActiveOptionButton: View {
    let isOn: Bool
    let icon: MoriBitmapIcon
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon.legacySystemName)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(MoriV2Palette.forestInk.opacity(isOn ? 0.82 : 0.46))
                .frame(width: 44, height: 44)
                .background(MoriV2Palette.forestInk.opacity(isOn ? 0.10 : 0.035))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display(label))
        .accessibilityValue(MoriL10n.display(isOn ? "On" : "Off"))
    }
}

private struct PomodoroActivePaperPanelModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(MoriV2Palette.raisedPaper.opacity(0.91))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MoriV2Palette.forestInk.opacity(0.10), lineWidth: 0.8)
            )
            .shadow(color: MoriV2Palette.shadow, radius: 16, x: 0, y: 8)
    }
}

private extension View {
    func pomodoroActivePaperPanel(cornerRadius: CGFloat) -> some View {
        modifier(PomodoroActivePaperPanelModifier(cornerRadius: cornerRadius))
    }
}

private struct PomodoroActiveToggleRow: View {
    let soundEnabled: Bool
    let hapticsEnabled: Bool
    let animationEnabled: Bool
    let darkRoomEnabled: Bool
    let onToggleSound: () -> Void
    let onToggleHaptics: () -> Void
    let onToggleAnimation: () -> Void
    let onToggleDarkRoom: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            PomodoroMinimalToggleButton(
                isOn: soundEnabled,
                onIcon: .sound,
                offIcon: .quiet,
                label: soundEnabled ? "Sound on" : "Sound off",
                darkRoomEnabled: darkRoomEnabled,
                action: onToggleSound
            )

            PomodoroMinimalToggleButton(
                isOn: hapticsEnabled,
                onIcon: .haptics,
                offIcon: .minus,
                label: hapticsEnabled ? "Haptics on" : "Haptics off",
                darkRoomEnabled: darkRoomEnabled,
                action: onToggleHaptics
            )

            PomodoroMinimalToggleButton(
                isOn: animationEnabled,
                onIcon: .roots,
                offIcon: .focus,
                label: animationEnabled ? "Animation on" : "Animation off",
                darkRoomEnabled: darkRoomEnabled,
                action: onToggleAnimation
            )

            PomodoroMinimalToggleButton(
                isOn: darkRoomEnabled,
                onIcon: .quiet,
                offIcon: .leaf,
                label: darkRoomEnabled ? "Dark room on" : "Dark room off",
                darkRoomEnabled: darkRoomEnabled,
                action: onToggleDarkRoom
            )
        }
    }
}

private struct PomodoroMinimalToggleButton: View {
    let isOn: Bool
    let onIcon: MoriBitmapIcon
    let offIcon: MoriBitmapIcon
    let label: String
    let darkRoomEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MoriBitmapIconImage(icon: isOn ? onIcon : offIcon, size: 17, opacity: isOn ? 0.88 : 0.48)
                .frame(width: 42, height: 42)
                .background(darkRoomEnabled ? Color.white.opacity(0.10) : MoriColors.botanicalInk.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display(label))
    }
}

private struct PomodoroActiveVisual: View {
    let isGuidedBreathing: Bool
    let activeBreathing: MoriPomodoroBreakBreathing
    let breathingVisualState: MoriBreathingCycleVisualState
    let timerState: SettleTimerState
    let phase: MoriPomodoroPhase
    let progress: CGFloat
    let primaryCueText: String
    let timeText: String
    let trackTint: Color
    let animationEnabled: Bool

    var body: some View {
        ZStack {
            MoriTimerProgressRing(
                progress: progress,
                tint: phase == .focus ? MoriV2Palette.primaryForest : phase.tint,
                trackTint: trackTint,
                lineWidth: 5.5,
                animation: animationEnabled ? .easeInOut(duration: 0.25) : nil
            )

            if isGuidedBreathing {
                MoriBreathingOrbView(
                    visualState: breathingVisualState,
                    isActive: animationEnabled && timerState == .running,
                    isPaused: timerState == .paused,
                    tint: activeBreathing.tint
                )
                .padding(38)
                .opacity(animationEnabled ? 0.22 : 0.12)
            }

            Text(timeText)
                .font(.system(size: 74, weight: .regular, design: .serif))
                .foregroundColor(MoriV2Palette.forestInk)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .padding(.horizontal, 22)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MoriL10n.string(
            "pomodoro.active_timer.accessibility",
            defaultValue: "%@, %@ remaining",
            arguments: [MoriL10n.display(primaryCueText), timeText]
        ))
    }
}
