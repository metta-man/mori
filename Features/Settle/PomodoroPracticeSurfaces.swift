import SwiftUI

struct PomodoroPracticeSetupSurface: View {
    @Binding var focusMinutes: Int
    @Binding var shortBreakMinutes: Int
    @Binding var longBreakMinutes: Int
    @Binding var cycles: Int

    let phase: MoriPomodoroPhase
    let timerState: SettleTimerState
    let progress: CGFloat
    let timeText: String
    let focusBreathing: MoriPomodoroBreakBreathing
    let breakBreathing: MoriPomodoroBreakBreathing
    let isGuidedBreathing: Bool
    let activeBreathing: MoriPomodoroBreakBreathing
    let currentPhaseElapsedSeconds: Int
    let darkRoomEnabled: Bool
    let completedSummary: MindfulCompletionSummary?
    let onSelectPhase: (MoriPomodoroPhase) -> Void
    let onStart: () -> Void
    let onSelectFocusBreathing: (MoriPomodoroBreakBreathing) -> Void
    let onSelectBreakBreathing: (MoriPomodoroBreakBreathing) -> Void

    var body: some View {
        MoriPaperBackground(variant: .practice) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    MoriPageHeader(
                        eyebrow: "Pomodoro",
                        title: "Focus Cycle",
                        subtitle: "A focused work rhythm with quiet breaks and completion Seeds."
                    )

                    PomodoroSetupHeroVisual(
                        phase: phase,
                        progress: max(0.035, progress),
                        timeText: timeText
                    )

                    PomodoroFocusCycleRows(
                        selectedPhase: phase,
                        focusMinutes: focusMinutes,
                        shortBreakMinutes: shortBreakMinutes,
                        longBreakMinutes: longBreakMinutes,
                        cycles: cycles,
                        canChangeDuration: timerState.canChangeDuration,
                        onSelectPhase: onSelectPhase
                    )

                    PomodoroSetupStartButton(
                        isCompleted: timerState == .completed,
                        action: onStart
                    )

                    Color.clear
                        .frame(height: 150)

                    PomodoroAdvancedSettingsCard(
                        canChangeDuration: timerState.canChangeDuration,
                        focusMinutes: $focusMinutes,
                        shortBreakMinutes: $shortBreakMinutes,
                        longBreakMinutes: $longBreakMinutes,
                        cycles: $cycles,
                        focusBreathing: focusBreathing,
                        breakBreathing: breakBreathing,
                        isGuidedBreathing: isGuidedBreathing,
                        activeBreathing: activeBreathing,
                        currentPhaseElapsedSeconds: currentPhaseElapsedSeconds,
                        darkRoomEnabled: darkRoomEnabled,
                        completedSummary: completedSummary,
                        onSelectFocusBreathing: onSelectFocusBreathing,
                        onSelectBreakBreathing: onSelectBreakBreathing
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, MoriMainTabBarMetrics.scrollBottomInset)
            }
        }
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
                    .accessibilityLabel("Reset Pomodoro")
                }

            case .running:
                settleControlButton(title: "Pause", icon: .pause, tint: MoriColors.botanicalInk, action: onPause)
                endButton

            case .paused:
                settleControlButton(title: "Resume", icon: .play, tint: MoriColors.botanicalInk, action: onResume)
                endButton
            }
        }
    }

    private var endButton: some View {
        Button(action: onEnd) {
            HStack(spacing: 6) {
                MoriBitmapIconImage(icon: .stop, size: 15, opacity: 0.86)

                Text("End")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(MoriColors.botanicalInk)
            .frame(width: 100)
            .padding(.vertical, 14)
            .background(MoriColors.botanicalInk.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
