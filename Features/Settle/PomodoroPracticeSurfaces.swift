import SwiftUI

struct PomodoroPracticeSetupSurface: View {
    @Binding var focusMinutes: Int
    @Binding var shortBreakMinutes: Int
    @Binding var longBreakMinutes: Int
    @Binding var cycles: Int
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @Binding var animationEnabled: Bool
    @Binding var darkRoomEnabled: Bool

    let phase: MoriPomodoroPhase
    let timerState: SettleTimerState
    let progress: CGFloat
    let timeText: String
    let focusBreathing: MoriPomodoroBreakBreathing
    let breakBreathing: MoriPomodoroBreakBreathing
    let isGuidedBreathing: Bool
    let activeBreathing: MoriPomodoroBreakBreathing
    let currentPhaseElapsedSeconds: Int
    let blockedAppsText: String
    let blockedAppsCount: Int
    let onSelectPhase: (MoriPomodoroPhase) -> Void
    let onStart: () -> Void
    let onSelectFocusBreathing: (MoriPomodoroBreakBreathing) -> Void
    let onSelectBreakBreathing: (MoriPomodoroBreakBreathing) -> Void

    @State private var showsSessionOptions = false

    var body: some View {
        ZStack {
            MoriColors.sanctuaryPaper
                .ignoresSafeArea()

            MoriBotanicalScreenBackdrop(variant: .focus)
                .opacity(0.20)
                .ignoresSafeArea()

            Image("MoriActiveDeepSessionValley")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.44)

            LinearGradient(
                colors: [
                    MoriColors.sanctuaryPaper.opacity(0.96),
                    MoriColors.sanctuaryPaper.opacity(0.42),
                    MoriColors.sanctuaryPaper.opacity(0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(spacing: 6) {
                        Text(MoriL10n.display("Deep Session"))
                            .font(.system(size: 32, weight: .regular, design: .serif))
                            .foregroundColor(MoriV2Palette.forestInk)

                        Text(MoriL10n.display("Protect one quiet block."))
                            .font(MoriV2Type.supporting)
                            .foregroundColor(MoriV2Palette.stone)
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 2)

                    PomodoroSetupHeroVisual(
                        phase: phase,
                        progress: max(0.035, progress),
                        timeText: timeText
                    )

                    blockedAppsPanel

                    PomodoroSetupStartButton(
                        isCompleted: timerState == .completed,
                        action: onStart
                    )

                    sessionOptionsDisclosure
                }
                .padding(.horizontal, 20)
                .padding(.top, 72)
                .padding(.bottom, MoriMainTabBarMetrics.scrollBottomInset)
            }
        }
    }

    private var blockedAppsPanel: some View {
        HStack(spacing: 12) {
            MoriBitmapIconImage(icon: .lockShield, size: 17, opacity: 0.86)
                .frame(width: 40, height: 40)
                .background(MoriV2Palette.sage.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display("Blocked apps"))
                    .font(MoriV2Type.control)
                    .foregroundColor(MoriV2Palette.forestInk)

                Text(MoriL10n.display(blockedAppsText))
                    .font(MoriV2Type.caption)
                    .foregroundColor(MoriV2Palette.stone)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Text(MoriL10n.string(
                "deep_session.blocked_count",
                defaultValue: blockedAppsCount == 1 ? "1 app" : "%d apps",
                arguments: [blockedAppsCount]
            ))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriV2Palette.forestInk)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 68)
        .background(MoriV2Palette.raisedPaper.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MoriV2Palette.hairline, lineWidth: 1)
        }
    }

    private var sessionOptionsDisclosure: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                showsSessionOptions.toggle()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(MoriL10n.display("Session options"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(MoriV2Palette.forestInk)

                        Text(MoriL10n.string(
                            "deep_session.options.summary",
                            defaultValue: "%d min · %d repeats",
                            arguments: [focusMinutes, cycles]
                        ))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(MoriV2Palette.stone)
                            .monospacedDigit()
                    }

                    Spacer(minLength: 12)

                    MoriBitmapIconImage(
                        icon: .chevron,
                        size: 13,
                        opacity: 0.72
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(showsSessionOptions ? 90 : 0))
                }
                .padding(.leading, 16)
                .padding(.trailing, 8)
                .frame(maxWidth: .infinity, minHeight: 62)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showsSessionOptions ? "Hide session options" : "Show session options")
            .background(MoriV2Palette.raisedPaper.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MoriV2Palette.hairline, lineWidth: 1)
            }
            .shadow(color: MoriV2Palette.shadow, radius: 10, x: 0, y: 5)

            if showsSessionOptions {
                VStack(alignment: .leading, spacing: 16) {
                    PomodoroFocusCycleRows(
                        selectedPhase: phase,
                        focusMinutes: $focusMinutes,
                        shortBreakMinutes: $shortBreakMinutes,
                        longBreakMinutes: $longBreakMinutes,
                        cycles: $cycles,
                        canChangeDuration: timerState.canChangeDuration,
                        onSelectPhase: onSelectPhase
                    )

                    PomodoroAdvancedSettingsCard(
                        canChangeDuration: timerState.canChangeDuration,
                        soundEnabled: $soundEnabled,
                        hapticsEnabled: $hapticsEnabled,
                        animationEnabled: $animationEnabled,
                        darkRoomEnabled: $darkRoomEnabled,
                        focusBreathing: focusBreathing,
                        breakBreathing: breakBreathing,
                        isGuidedBreathing: isGuidedBreathing,
                        activeBreathing: activeBreathing,
                        currentPhaseElapsedSeconds: currentPhaseElapsedSeconds,
                        onSelectFocusBreathing: onSelectFocusBreathing,
                        onSelectBreakBreathing: onSelectBreakBreathing
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .moriReduceMotionAnimation(MoriAnimation.slow, value: showsSessionOptions)
    }
}

struct MoriDeepSessionCompletion: Equatable {
    let quietMinutes: Int
    let completedPlannedSession: Bool

    var title: String {
        if completedPlannedSession {
            return MoriL10n.display("One quiet session protected.")
        }
        return quietMinutes > 0
            ? MoriL10n.display("A quiet moment protected.")
            : MoriL10n.display("A quiet moment.")
    }

    var detail: String? {
        guard quietMinutes > 0 else { return nil }
        return MoriL10n.string(
            "deep_session.completion.minutes",
            defaultValue: "%d quiet minutes.",
            arguments: [quietMinutes]
        )
    }
}

struct MoriDeepSessionCompletionSurface: View {
    let completion: MoriDeepSessionCompletion
    let onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            MoriColors.sanctuaryPaper
                .ignoresSafeArea()

            MoriBotanicalScreenBackdrop(variant: .focus)
                .opacity(0.52)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 18) {
                Spacer(minLength: 80)

                Text(MoriL10n.display("Session complete"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.sanctuaryMuted)

                Text(completion.title)
                    .font(.system(size: 38, weight: .regular, design: .serif))
                    .foregroundColor(MoriColors.sanctuaryInk)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail = completion.detail {
                    Text(detail)
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundColor(MoriColors.sanctuaryInkSoft)
                }

                Spacer()

                Button(action: onContinue) {
                    Text(MoriL10n.display("Continue"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(MoriColors.sanctuarySurface)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 54)
                        .background(MoriColors.botanicalInk)
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .accessibilityElement(children: .contain)
    }
}

struct PomodoroControlRow: View {
    let timerState: SettleTimerState
    let onStart: () -> Void
    let onReset: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            switch timerState {
            case .idle, .completed:
                settleControlButton(
                    title: timerState == .completed ? "Begin again" : "Start",
                    icon: .play,
                    tint: MoriColors.botanicalInk,
                    action: onStart
                )

                if timerState == .completed {
                    Button(action: onReset) {
                        MoriBitmapIconImage(icon: .refresh, size: 17, opacity: 0.86)
                            .frame(width: 48, height: 48)
                            .background(MoriColors.botanicalInk.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reset Deep Session")
                }

            case .running:
                settleControlButton(
                    title: "Pause",
                    icon: .pause,
                    tint: MoriColors.botanicalInk,
                    action: onPause
                )

            case .paused:
                settleControlButton(
                    title: "Resume",
                    icon: .play,
                    tint: MoriColors.botanicalInk,
                    action: onResume
                )
                endButton
            }
        }
    }

    private var endButton: some View {
        Button(action: onEnd) {
            Text(MoriL10n.display("End quietly"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.botanicalInk)
                .frame(width: 116)
                .frame(minHeight: 50)
                .background(MoriColors.botanicalInk.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
