import SwiftUI

struct MoriBreathingSessionActiveSurface: View {
    let technique: MoriBreathingTechnique
    let visualState: MoriBreathingCycleVisualState
    let timeText: String
    let progress: CGFloat
    let runState: MoriBreathingRunState
    let animationEnabled: Bool
    let soundEnabled: Bool
    let hapticsEnabled: Bool
    let darkRoomEnabled: Bool
    @Binding var darkRoomDim: Double
    let darkRoomOffScreen: Bool
    let darkRoomControlsVisible: Bool
    let onToggleSound: () -> Void
    let onToggleHaptics: () -> Void
    let onToggleAnimation: () -> Void
    let onToggleDarkRoom: () -> Void
    let onRevealDarkRoomControls: () -> Void
    let onExitDarkRoomOffScreen: () -> Void
    let onEnterDarkRoomOffScreen: () -> Void
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void

    private var tint: Color {
        Color(hex: technique.gradientColors.first ?? "#687E5E")
    }

    var body: some View {
        Group {
            if darkRoomEnabled {
                MoriDarkRoomSessionSurface(
                    timeText: timeText,
                    sessionLabel: "Focus time",
                    cueText: cueText,
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
                MoriPaperBackground(variant: .breath) {
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

                        Text(cueText)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(activeSecondaryColor)

                        Text(technique.name)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(activeSecondaryColor.opacity(0.82))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    if animationEnabled {
                        ZStack {
                            MoriBreathingProgressRing(progress: progress, tint: tint)
                            MoriBreathingOrbView(
                                visualState: visualState,
                                isActive: runState == .running,
                                isPaused: runState == .paused,
                                tint: tint
                            )
                        }
                        .frame(width: 210, height: 210)
                    } else {
                        MoriBitmapIconImage(icon: technique.icon, size: 58, opacity: 0.72)
                            .frame(height: 210)
                    }

                    activeToggleRow
                    controlRow

                    Spacer(minLength: 14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom + 12, 22))
            }
        }
    }

    private var darkRoomControlPanel: some View {
        VStack(spacing: 14) {
            activeToggleRow

            HStack(spacing: 12) {
                MoriDarkRoomDimControl(dim: $darkRoomDim)
                MoriDarkRoomFullBlackButton(action: onEnterDarkRoomOffScreen)
            }

            controlRow
        }
    }

    private var activeToggleRow: some View {
        MoriBreathingCueToggleRow(
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            animationEnabled: animationEnabled,
            darkRoomEnabled: darkRoomEnabled,
            isDarkRoomActive: darkRoomEnabled && runState.isActive,
            onToggleSound: onToggleSound,
            onToggleHaptics: onToggleHaptics,
            onToggleAnimation: onToggleAnimation,
            onToggleDarkRoom: onToggleDarkRoom
        )
    }

    private var controlRow: some View {
        MoriBreathingControlRow(
            runState: runState,
            onStart: onStart,
            onPause: onPause,
            onResume: onResume,
            onEnd: onEnd
        )
    }

    private var cueText: String {
        runState == .paused ? MoriL10n.display("Paused") : visualState.label
    }

    private var activePrimaryColor: Color {
        darkRoomEnabled ? .white.opacity(0.92) : MoriColors.botanicalInk
    }

    private var activeSecondaryColor: Color {
        darkRoomEnabled ? .white.opacity(0.62) : MoriColors.botanicalMuted
    }
}
