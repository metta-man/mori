import SwiftUI

struct SettleTimerCompletionBanner: View {
    let session: SettleSession
    let seedsOverride: Int?

    private var seeds: Int {
        seedsOverride ?? session.seedsEarned
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            MoriBitmapIconImage(icon: .leaf, size: 21, opacity: 0.88)
                .frame(width: 36, height: 36)
                .background(MoriColors.sanctuarySurface.opacity(0.74))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("Reset complete")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(MoriL10n.string(
                    "settle.completion.duration_seed",
                    defaultValue: "%@ planted %d Seeds.",
                    arguments: [session.durationText, seeds]
                ))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
            }

            Spacer()
        }
        .padding(14)
        .background(MoriColors.botanicalMoss.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SettleTimerCard<CompletionPrompt: View>: View {
    let timerState: SettleTimerState
    let durationOptions: [Int]
    let recommendedMinutes: Int
    let timerProgress: CGFloat
    let timeText: String
    let completedSession: SettleSession?
    let completedSettleSeeds: Int?
    @Binding var soundEnabled: Bool
    @Binding var selectedMinutes: Int
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void
    private let completionPrompt: () -> CompletionPrompt

    init(
        timerState: SettleTimerState,
        durationOptions: [Int],
        recommendedMinutes: Int,
        timerProgress: CGFloat,
        timeText: String,
        completedSession: SettleSession?,
        completedSettleSeeds: Int?,
        soundEnabled: Binding<Bool>,
        selectedMinutes: Binding<Int>,
        onStart: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onResume: @escaping () -> Void,
        onEnd: @escaping () -> Void,
        @ViewBuilder completionPrompt: @escaping () -> CompletionPrompt
    ) {
        self.timerState = timerState
        self.durationOptions = durationOptions
        self.recommendedMinutes = recommendedMinutes
        self.timerProgress = timerProgress
        self.timeText = timeText
        self.completedSession = completedSession
        self.completedSettleSeeds = completedSettleSeeds
        self._soundEnabled = soundEnabled
        self._selectedMinutes = selectedMinutes
        self.onStart = onStart
        self.onPause = onPause
        self.onResume = onResume
        self.onEnd = onEnd
        self.completionPrompt = completionPrompt
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            SettleTimerDurationPicker(
                durationOptions: durationOptions,
                recommendedMinutes: recommendedMinutes,
                timerState: timerState,
                selectedMinutes: $selectedMinutes
            )

            progressRing

            if let completedSession {
                SettleTimerCompletionBanner(session: completedSession, seedsOverride: completedSettleSeeds)
                completionPrompt()
            }

            SettleTimerControlRow(
                timerState: timerState,
                onStart: onStart,
                onPause: onPause,
                onResume: onResume,
                onEnd: onEnd
            )
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }

    private var header: some View {
        HStack(alignment: .top) {
            MoriSectionTitle(
                title: "Reset Timer",
                subtitle: timerState.subtitle
            )

            Spacer()

            Button {
                soundEnabled.toggle()
            } label: {
                MoriBitmapIconImage(icon: soundEnabled ? .sound : .quiet, size: 18, opacity: soundEnabled ? 0.88 : 0.48)
                    .frame(width: 38, height: 38)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(MoriL10n.display(soundEnabled ? "Settle bells on" : "Settle bells off"))
        }
    }

    private var progressRing: some View {
        ZStack {
            MoriTimerProgressRing(
                progress: timerProgress,
                tint: MoriColors.botanicalMoss
            )

            SettleLeafPulse(isActive: timerState == .running)

            VStack(spacing: 6) {
                Text(timeText)
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)
                    .monospacedDigit()
                    .minimumScaleFactor(0.75)

                HStack(spacing: 6) {
                    MoriBitmapIconImage(icon: timerState.icon, size: 14, opacity: 0.68)

                    Text(timerState.label)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.botanicalMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 244)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MoriL10n.string("settle.timer.accessibility", defaultValue: "Settle timer %@, %@", arguments: [timeText, timerState.label]))
    }
}

struct SettleMindfulnessBellCompletionPrompt: View {
    let mindfulnessBellEnabled: Bool
    let nextFireTimestamp: Double
    let promptDismissed: Bool
    let authorizationDenied: Bool
    let onSetBell: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        if mindfulnessBellEnabled {
            MindfulnessBellStatusRow(
                text: MindfulnessBellStatusFormatter.nextBellText(
                    isActive: mindfulnessBellEnabled,
                    nextFireTimestamp: nextFireTimestamp
                )
            )
        } else if !promptDismissed {
            MindfulnessBellCompletionNudge(
                authorizationDenied: authorizationDenied,
                onSetBell: onSetBell,
                onDismiss: onDismiss
            )
        }
    }
}

struct SettleLeafPulse: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    private var outerSize: CGFloat {
        guard !reduceMotion else { return isActive ? 118 : 112 }
        return pulse && isActive ? 136 : 112
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(MoriColors.botanicalSage.opacity(isActive ? 0.18 : 0.10))
                .frame(width: outerSize, height: outerSize)

            Circle()
                .fill(MoriColors.botanicalPaperDeep.opacity(0.8))
                .frame(width: 88, height: 88)

            MoriBitmapIconImage(icon: .leaf, size: 34, opacity: 0.88)
        }
        .onAppear {
            guard !reduceMotion else {
                pulse = false
                return
            }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onChange(of: reduceMotion) { shouldReduceMotion in
            if shouldReduceMotion {
                pulse = false
            } else {
                withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }
}
