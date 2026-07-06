import SwiftUI

struct PomodoroActiveSessionSurface<ControlRow: View>: View {
    let darkRoomEnabled: Bool
    let darkRoomOffScreen: Bool
    let darkRoomControlsVisible: Bool
    let timeText: String
    let sessionLabel: String
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
    let controlRow: () -> ControlRow
    @Binding var darkRoomDim: Double

    init(
        darkRoomEnabled: Bool,
        darkRoomDim: Binding<Double>,
        darkRoomOffScreen: Bool,
        darkRoomControlsVisible: Bool,
        timeText: String,
        sessionLabel: String,
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
        @ViewBuilder controlRow: @escaping () -> ControlRow
    ) {
        self.darkRoomEnabled = darkRoomEnabled
        _darkRoomDim = darkRoomDim
        self.darkRoomOffScreen = darkRoomOffScreen
        self.darkRoomControlsVisible = darkRoomControlsVisible
        self.timeText = timeText
        self.sessionLabel = sessionLabel
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
                MoriPaperBackground(variant: .practice) {
                    Color.clear
                }

                VStack(spacing: 18) {
                    Spacer(minLength: 14)

                    VStack(spacing: 8) {
                        Text(timeText)
                            .font(.system(size: 66, weight: .semibold, design: .rounded))
                            .foregroundColor(activePrimaryColor)
                            .monospacedDigit()
                            .minimumScaleFactor(0.65)

                        Text(primaryCueText)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(activeSecondaryColor)

                        Text(secondaryCueText)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(activeSecondaryColor.opacity(0.82))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.78)
                    }

                    if animationEnabled {
                        PomodoroActiveVisual(
                            isGuidedBreathing: isGuidedBreathing,
                            activeBreathing: activeBreathing,
                            breathingVisualState: breathingVisualState,
                            timerState: timerState,
                            phase: phase,
                            progress: progress,
                            primaryCueText: primaryCueText,
                            timeText: timeText,
                            trackTint: activeSecondaryColor.opacity(0.22)
                        )
                    } else {
                        MoriBitmapIconImage(
                            icon: isGuidedBreathing ? activeBreathing.icon : phase.icon,
                            size: 58,
                            opacity: 0.72
                        )
                        .frame(height: isGuidedBreathing ? 210 : 172)
                    }

                    toggleRow

                    controlRow()

                    Spacer(minLength: 14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom + 12, 22))
            }
        }
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

    private var activePrimaryColor: Color {
        darkRoomEnabled ? .white.opacity(0.92) : MoriColors.botanicalInk
    }

    private var activeSecondaryColor: Color {
        darkRoomEnabled ? .white.opacity(0.62) : MoriColors.botanicalMuted
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

    var body: some View {
        Group {
            if isGuidedBreathing {
                ZStack {
                    MoriBreathingProgressRing(progress: progress, tint: activeBreathing.tint)
                    MoriBreathingOrbView(
                        visualState: breathingVisualState,
                        isActive: timerState == .running,
                        isPaused: timerState == .paused,
                        tint: activeBreathing.tint
                    )
                }
                .frame(width: 230, height: 230)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(MoriL10n.string(
                    "pomodoro.guided_timer.accessibility",
                    defaultValue: "%@, %@, %@ remaining",
                    arguments: [MoriL10n.display(activeBreathing.title), primaryCueText, timeText]
                ))
            } else {
                ZStack {
                    MoriTimerProgressRing(
                        progress: progress,
                        tint: phase.tint,
                        trackTint: trackTint,
                        lineWidth: 12
                    )
                }
                .frame(width: 190, height: 190)
            }
        }
    }
}
