import SwiftUI

struct MoriBreathingCompletionSummary {
    let title: String
    let seeds: Int
    let minutes: Int
    let icon: MoriBitmapIcon
    let tint: Color

    init(
        title: String,
        seeds: Int,
        minutes: Int,
        icon: MoriBitmapIcon,
        tint: Color
    ) {
        self.title = title
        self.seeds = seeds
        self.minutes = minutes
        self.icon = icon
        self.tint = tint
    }

}

struct MoriBreathingSessionSetupSurface: View {
    let technique: MoriBreathingTechnique
    let currentPattern: MoriBreathPattern
    let segments: [MoriBreathingCycleSegment]
    let visualState: MoriBreathingCycleVisualState
    let timeText: String
    let progress: CGFloat
    let durationMinutes: Int
    let currentPhaseIndex: Int
    let completedBreathCount: Int
    let completedSummary: MoriBreathingCompletionSummary?
    let runState: MoriBreathingRunState
    let soundEnabled: Bool
    let hapticsEnabled: Bool
    let hapticStyle: MoriBreathingHapticStyle
    let keepScreenOn: Bool
    let onToggleSound: () -> Void
    let onToggleHaptics: () -> Void
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void

    private var tint: Color {
        Color(hex: technique.gradientColors.first ?? "#687E5E")
    }

    var body: some View {
        MoriPaperBackground(variant: .breath) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    MoriPageHeader(
                        eyebrow: "Breathing",
                        title: technique.name,
                        subtitle: technique.shortDescription
                    )

                    heroVisual

                    techniqueInfoCard
                    phaseSummaryGrid
                    timerCard
                    ScreenTimeLimitControls(contextTitle: "Breathing", feature: .breathing)
                    guidanceSettingsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
    }

    private var heroVisual: some View {
        ZStack {
            MoriWatercolorHeroWash(variant: .practice, placement: .corner)
                .clipShape(Circle())
                .frame(width: 226, height: 226)
                .opacity(0.94)
                .shadow(color: MoriColors.sanctuaryShadow.opacity(0.18), radius: 28, x: 0, y: 16)

            MoriBreathingProgressRing(progress: max(0.06, progress), tint: tint)
                .frame(width: 206, height: 206)

            MoriBreathingOrbView(
                visualState: visualState,
                isActive: runState == .running,
                isPaused: runState == .paused,
                tint: tint
            )
            .frame(width: 154, height: 154)

            VStack(spacing: 6) {
                Text(timeText)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)
                    .monospacedDigit()

                Text(visualState.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 236)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(technique.name), \(timeText), \(visualState.label)")
    }

    private var techniqueInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                MoriMiniBadge(title: technique.category, icon: .journal, tint: MoriColors.botanicalMoss)
                MoriMiniBadge(title: technique.difficulty.rawValue, icon: technique.difficulty.icon, tint: technique.difficulty.tint)
                MoriMiniBadge(title: MoriBreathingTechnique.patternDisplay(for: currentPattern), icon: .timer, tint: MoriColors.botanicalMist)
            }

            Text(technique.bestFor.prefix(3).joined(separator: " · "))
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }

    private var phaseSummaryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(max(segments.count, 2), 4)), spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                let isCurrent = index == currentPhaseIndex && runState == .running

                VStack(spacing: 5) {
                    MoriBitmapIconImage(icon: phaseIcon(for: segment.phase), size: 15, opacity: isCurrent ? 0.94 : 0.78)
                    Text(segment.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isCurrent ? MoriColors.botanicalSurface : MoriColors.botanicalInk)
                    Text(MoriBreathingTechnique.formatSeconds(segment.duration))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(isCurrent ? MoriColors.botanicalSurface : MoriColors.botanicalInk)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, minHeight: 78)
                .background(isCurrent ? MoriColors.botanicalInk : MoriColors.botanicalPaperDeep.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 12)
    }

    private var timerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                MoriSectionTitle(
                    title: visualState.label,
                    subtitle: runState == .running ? "Follow the cue. No forcing." : "Ready for \(durationMinutes)m of guided breathing."
                )

                Spacer()

                HStack(spacing: 8) {
                    MoriBreathingCueToggleButton(
                        isOn: soundEnabled,
                        onIcon: .sound,
                        offIcon: .quiet,
                        label: soundEnabled ? "Sound cues on" : "Sound cues off",
                        isDarkRoomActive: false,
                        action: onToggleSound
                    )
                    MoriBreathingCueToggleButton(
                        isOn: hapticsEnabled,
                        onIcon: .haptics,
                        offIcon: .minus,
                        label: hapticsEnabled ? "Haptics on" : "Haptics off",
                        isDarkRoomActive: false,
                        action: onToggleHaptics
                    )
                }
            }

            ZStack {
                MoriBreathingProgressRing(progress: progress, tint: tint)
                MoriBreathingOrbView(
                    visualState: visualState,
                    isActive: runState == .running,
                    isPaused: runState == .paused,
                    tint: tint
                )

                VStack {
                    Spacer()
                    Text(MoriL10n.string(
                        "breathing.completed_breaths",
                        defaultValue: "%d breaths",
                        arguments: [completedBreathCount]
                    ))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(MoriColors.botanicalInk.opacity(0.07))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 270)
            .overlay(alignment: .center) {
                VStack(spacing: 7) {
                    Text(timeText)
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)
                        .monospacedDigit()

                    Text(runState == .paused ? MoriL10n.display("Paused") : visualState.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalMuted)
                }
            }

            if let completedSummary {
                MoriBreathingCompletionBanner(summary: completedSummary)
            }

            MoriBreathingControlRow(
                runState: runState,
                onStart: onStart,
                onPause: onPause,
                onResume: onResume,
                onEnd: onEnd
            )
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }

    private var guidanceSettingsCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            MoriSectionTitle(title: "Guidance", subtitle: "Reference-style phase sound and haptic cues.")

            HStack(spacing: 10) {
                MoriMiniBadge(title: soundEnabled ? "Sound on" : "Sound off", icon: soundEnabled ? .sound : .quiet, tint: MoriColors.botanicalMoss)
                MoriMiniBadge(title: hapticStyle.rawValue, icon: .haptics, tint: MoriColors.botanicalMist)
                MoriMiniBadge(title: keepScreenOn ? "Screen awake" : "Screen normal", icon: keepScreenOn ? .focus : .quiet, tint: MoriColors.botanicalClay)
            }

            if technique.id == MoriBreathingTechniqueID.custom.rawValue {
                Text(MoriL10n.string(
                    "breathing.custom_pattern",
                    defaultValue: "Custom pattern: %@",
                    arguments: [MoriBreathingTechnique.patternDisplay(for: currentPattern)]
                ))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }

    private func phaseIcon(for phase: MoriBreathingCyclePhase) -> MoriBitmapIcon {
        switch phase {
        case .inhale: return .breathe
        case .exhale: return .leaf
        case .holdAfterInhale, .holdAfterExhale: return .pause
        case .idle: return .focus
        }
    }
}
