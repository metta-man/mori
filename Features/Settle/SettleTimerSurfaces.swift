import SwiftUI

struct SettleTimerSetupSurface<TimerCardContent: View>: View {
    let recommendedMinutes: Int
    let weeklySummary: SettleWeeklySummary
    @Binding var intervalBellEnabled: Bool
    @Binding var intervalBellMinutes: Int
    let intervalOptions: [Int]
    let onUseRecommendation: () -> Void
    let onStartRecommendation: () -> Void
    private let timerCardContent: () -> TimerCardContent

    init(
        recommendedMinutes: Int,
        weeklySummary: SettleWeeklySummary,
        intervalBellEnabled: Binding<Bool>,
        intervalBellMinutes: Binding<Int>,
        intervalOptions: [Int],
        onUseRecommendation: @escaping () -> Void,
        onStartRecommendation: @escaping () -> Void,
        @ViewBuilder timerCardContent: @escaping () -> TimerCardContent
    ) {
        self.recommendedMinutes = recommendedMinutes
        self.weeklySummary = weeklySummary
        self._intervalBellEnabled = intervalBellEnabled
        self._intervalBellMinutes = intervalBellMinutes
        self.intervalOptions = intervalOptions
        self.onUseRecommendation = onUseRecommendation
        self.onStartRecommendation = onStartRecommendation
        self.timerCardContent = timerCardContent
    }

    var body: some View {
        MoriPaperBackground(variant: .practice) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    MoriPageHeader(
                        eyebrow: "Settle",
                        title: "Reset Timer",
                        subtitle: "A quiet timer for coming back from digital noise before the next tap chooses for you."
                    )

                    MoriWatercolorHeroWash(variant: .practice, placement: .corner)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.82), lineWidth: 1)
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 210)
                        .padding(.vertical, 2)

                    SettleRecommendationCard(
                        recommendedMinutes: recommendedMinutes,
                        weeklySummary: weeklySummary,
                        onUseRecommendation: onUseRecommendation,
                        onStartRecommendation: onStartRecommendation
                    )

                    timerCardContent()

                    SettleBellSettingsCard(
                        intervalBellEnabled: $intervalBellEnabled,
                        intervalBellMinutes: $intervalBellMinutes,
                        intervalOptions: intervalOptions
                    )

                    ScreenTimeLimitControls(contextTitle: "Settle", feature: .settle)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
    }
}

struct SettleTimerNormalActiveSurface: View {
    let timeText: String
    let timerState: SettleTimerState
    let animationEnabled: Bool
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @Binding var animationEnabledBinding: Bool
    @Binding var darkRoomEnabled: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                MoriPaperBackground(variant: .practice) {
                    Color.clear
                }

                VStack(spacing: 20) {
                    Spacer(minLength: 16)

                    VStack(spacing: 8) {
                        Text(timeText)
                            .font(.system(size: 68, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.botanicalInk)
                            .monospacedDigit()
                            .minimumScaleFactor(0.65)

                        HStack(spacing: 6) {
                            MoriBitmapIconImage(icon: timerState.icon, size: 15, opacity: 0.68)

                            Text(MoriL10n.display(timerState == .paused ? "Paused" : "Settle"))
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalMuted)
                    }

                    if animationEnabled {
                        SettleLeafPulse(isActive: timerState == .running)
                            .frame(height: 132)
                    } else {
                        MoriBitmapIconImage(icon: .leaf, size: 54, opacity: 0.54)
                            .frame(height: 132)
                    }

                    SettleTimerToggleRow(
                        soundEnabled: $soundEnabled,
                        hapticsEnabled: $hapticsEnabled,
                        animationEnabled: $animationEnabledBinding,
                        darkRoomEnabled: $darkRoomEnabled
                    )

                    SettleTimerControlRow(
                        timerState: timerState,
                        onStart: onStart,
                        onPause: onPause,
                        onResume: onResume,
                        onEnd: onEnd
                    )

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom + 12, 22))
            }
        }
    }
}

struct SettleTimerActiveSurface: View {
    let timeText: String
    let timerState: SettleTimerState
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @Binding var animationEnabled: Bool
    @Binding var darkRoomEnabled: Bool
    @Binding var darkRoomDim: Double
    let darkRoomOffScreen: Bool
    let darkRoomControlsVisible: Bool
    let onRevealDarkRoomControls: () -> Void
    let onExitDarkRoomOffScreen: () -> Void
    let onEnterDarkRoomOffScreen: () -> Void
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void

    var body: some View {
        Group {
            if darkRoomEnabled {
                MoriDarkRoomSessionSurface(
                    timeText: timeText,
                    sessionLabel: "Settle time",
                    cueText: darkRoomCueText,
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
                SettleTimerNormalActiveSurface(
                    timeText: timeText,
                    timerState: timerState,
                    animationEnabled: animationEnabled,
                    soundEnabled: $soundEnabled,
                    hapticsEnabled: $hapticsEnabled,
                    animationEnabledBinding: $animationEnabled,
                    darkRoomEnabled: $darkRoomEnabled,
                    onStart: onStart,
                    onPause: onPause,
                    onResume: onResume,
                    onEnd: onEnd
                )
            }
        }
    }

    private var darkRoomControlPanel: some View {
        VStack(spacing: 14) {
            SettleTimerToggleRow(
                soundEnabled: $soundEnabled,
                hapticsEnabled: $hapticsEnabled,
                animationEnabled: $animationEnabled,
                darkRoomEnabled: $darkRoomEnabled
            )

            HStack(spacing: 12) {
                MoriDarkRoomDimControl(dim: $darkRoomDim)
                MoriDarkRoomFullBlackButton(action: onEnterDarkRoomOffScreen)
            }

            SettleTimerControlRow(
                timerState: timerState,
                onStart: onStart,
                onPause: onPause,
                onResume: onResume,
                onEnd: onEnd
            )
        }
    }

    private var darkRoomCueText: String {
        timerState == .paused ? "Paused" : "Settle"
    }
}
