import SwiftUI

struct MoriBreathingSessionActiveSurface: View {
    let technique: MoriBreathingTechnique
    let visualState: MoriBreathingCycleVisualState
    let timeText: String
    let phaseSeconds: Int
    let sessionRemainingText: String
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
    let onClose: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var countdownSize: CGFloat = 112

    var body: some View {
        Group {
            if darkRoomEnabled {
                MoriDarkRoomSessionSurface(
                    timeText: timeText,
                    sessionLabel: "Focus time",
                    cueText: cueText,
                    cueStatus: MoriDarkRoomCueStatus.current(
                        soundEnabled: soundEnabled,
                        hapticsEnabled: hapticsEnabled
                    ),
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
            let visualHeight = max(286, min(420, proxy.size.height * 0.47))
            let landscapeHeight = max(300, min(460, proxy.size.height * 0.48))

            ZStack {
                MoriPaperBackground(variant: .breath) {
                    Color.clear
                }

                MoriGeneratedArtImage(art: .breathLandscapeWash, contentMode: .fill)
                    .frame(width: proxy.size.width, height: landscapeHeight)
                    .clipped()
                    .opacity(0.72)
                    .blendMode(.multiply)
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height - (landscapeHeight / 2)
                    )

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 52)

                    Spacer(minLength: 22)

                    Text(cueText)
                        .font(.system(.title2, design: .serif, weight: .regular))
                        .foregroundColor(MoriColors.sanctuaryInkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .padding(.horizontal, 24)

                    ZStack {
                        MoriBreathingInkBloomView(
                            visualState: visualState,
                            isSessionActive: runState.isActive,
                            animationEnabled: animationEnabled
                        )
                        .frame(
                            width: min(proxy.size.width * 1.28, 540),
                            height: visualHeight * 1.18
                        )

                        Text("\(phaseSeconds)")
                            .font(.system(size: countdownSize, weight: .ultraLight, design: .rounded))
                            .foregroundColor(MoriColors.sanctuaryInk.opacity(0.90))
                            .monospacedDigit()
                            .minimumScaleFactor(0.64)
                            .accessibilityHidden(true)
                    }
                    .frame(height: visualHeight)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        MoriL10n.string(
                            "breathing.phase_countdown.accessibility",
                            defaultValue: "%@, %d seconds",
                            arguments: [cueText, phaseSeconds]
                        )
                    )

                    Spacer(minLength: 12)

                    Text(sessionRemainingText)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(MoriColors.sanctuaryInkSoft.opacity(0.86))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)

                    pauseButton
                        .padding(.top, 18)
                        .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 18))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)

                Button(action: onClose) {
                    MoriBreathingCloseMark()
                }
                .buttonStyle(.plain)
                .position(
                    x: proxy.size.width - 36,
                    y: max(54, min(88, proxy.size.height * 0.09))
                )
                .zIndex(2)
                .accessibilityLabel(MoriL10n.string(
                    "breathing.session.close.accessibility",
                    defaultValue: "End breathing session"
                ))
                .accessibilityHint(MoriL10n.string(
                    "breathing.session.close.hint",
                    defaultValue: "Shows a confirmation before leaving."
                ))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }

    private var pauseButton: some View {
        Button(action: runState == .paused ? onResume : onPause) {
            Text(MoriL10n.display(runState == .paused ? "Resume" : "Pause"))
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.sanctuaryInkSoft)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(MoriColors.sanctuarySurface.opacity(0.82))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(MoriColors.sanctuaryHairline, lineWidth: 1)
                }
                .clipShape(Capsule(style: .continuous))
                .shadow(color: MoriColors.sanctuaryShadow.opacity(0.28), radius: 12, x: 0, y: 7)
        }
        .buttonStyle(.plain)
        .frame(width: 172)
        .accessibilityHint(
            runState == .paused
                ? MoriL10n.string(
                    "breathing.session.resume.hint",
                    defaultValue: "Continues from the current breathing phase."
                )
                : MoriL10n.string(
                    "breathing.session.pause.hint",
                    defaultValue: "Freezes the timer and watercolor at the current phase."
                )
        )
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
}

struct MoriBreathingSessionCompletionSurface: View {
    let summary: MoriBreathingCompletionSummary
    let onDone: () -> Void
    let onBreatheAgain: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let landscapeHeight = max(300, min(460, proxy.size.height * 0.48))

            ZStack {
                MoriPaperBackground(variant: .breath) {
                    Color.clear
                }

                MoriGeneratedArtImage(art: .breathLandscapeWash, contentMode: .fill)
                    .frame(width: proxy.size.width, height: landscapeHeight)
                    .clipped()
                    .opacity(0.72)
                    .blendMode(.multiply)
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height - (landscapeHeight / 2)
                    )

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 52)

                    Spacer(minLength: 28)

                    Text(MoriL10n.display("One quiet session protected."))
                        .font(MoriTypography.sanctuaryTitle)
                        .foregroundColor(MoriColors.sanctuaryInk)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    ZStack {
                        MoriBreathingInkBloomView(
                            visualState: .idle,
                            isSessionActive: false,
                            animationEnabled: false
                        )

                        MoriBitmapIconImage(icon: summary.icon, size: 38, opacity: 0.72)
                    }
                    .frame(width: min(proxy.size.width * 0.82, 330), height: min(330, proxy.size.height * 0.39))

                    Text(MoriL10n.string(
                        "settle.completion.quiet_minutes",
                        defaultValue: "%d quiet minutes.",
                        arguments: [summary.minutes]
                    ))
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(MoriColors.sanctuaryInkSoft.opacity(0.86))
                    .multilineTextAlignment(.center)

                    Spacer(minLength: 24)

                    Button(action: onDone) {
                        Text(MoriL10n.display("Done"))
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.sanctuaryInkSoft)
                            .frame(maxWidth: .infinity, minHeight: 58)
                            .background(MoriColors.sanctuarySurface.opacity(0.82))
                            .overlay {
                                Capsule(style: .continuous)
                                    .stroke(MoriColors.sanctuaryHairline, lineWidth: 1)
                            }
                            .clipShape(Capsule(style: .continuous))
                            .shadow(color: MoriColors.sanctuaryShadow.opacity(0.26), radius: 12, x: 0, y: 7)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: 282)
                    .padding(.horizontal, 44)

                    Button(action: onBreatheAgain) {
                        Text(MoriL10n.display("Breathe again"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(MoriColors.sanctuaryInkSoft)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .padding(.bottom, max(20, proxy.safeAreaInsets.bottom + 14))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)

                Button(action: onDone) {
                    MoriBreathingCloseMark()
                }
                .buttonStyle(.plain)
                .position(
                    x: proxy.size.width - 36,
                    y: max(54, min(88, proxy.size.height * 0.09))
                )
                .zIndex(2)
                .accessibilityLabel(MoriL10n.display("Done"))
            }
        }
        .ignoresSafeArea()
    }
}

private struct MoriBreathingCloseMark: View {
    var body: some View {
        ZStack {
            MoriBitmapIconImage(icon: .plus, size: 23, opacity: 1)
            MoriBitmapIconImage(icon: .plus, size: 23, opacity: 1)
        }
        .colorMultiply(MoriColors.sanctuaryInk)
        .rotationEffect(.degrees(45))
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .accessibilityHidden(true)
    }
}
