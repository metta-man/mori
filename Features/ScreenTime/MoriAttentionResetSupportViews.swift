import SwiftUI

enum MoriAttentionResetContext: Equatable {
    case beforeFeed
    case morningGate

    var feature: MoriScreenTimeFeature {
        switch self {
        case .beforeFeed: return .beforeFeed
        case .morningGate: return .morningGate
        }
    }

    var eyebrow: String {
        switch self {
        case .beforeFeed: return MoriL10n.string("Before Feed", defaultValue: "Before Feed")
        case .morningGate: return MoriL10n.string("Morning Gate", defaultValue: "Morning Gate")
        }
    }

    var navigationTitle: String {
        switch self {
        case .beforeFeed: return MoriL10n.string("Before Feed", defaultValue: "Before Feed")
        case .morningGate: return MoriL10n.string("Morning Reset", defaultValue: "Morning Reset")
        }
    }

    var completionTitle: String {
        switch self {
        case .beforeFeed: return MoriL10n.string("Before Feed Reset", defaultValue: "Before Feed Reset")
        case .morningGate: return MoriL10n.string("Morning Reset", defaultValue: "Morning Reset")
        }
    }

    var appLimitTitle: String {
        switch self {
        case .beforeFeed: return MoriL10n.string("attention_reset.protected.before_feed", defaultValue: "Before Feed App Limit")
        case .morningGate: return MoriL10n.string("attention_reset.protected.morning", defaultValue: "Morning App Limit")
        }
    }

    var completedNote: String {
        switch self {
        case .beforeFeed: return MoriL10n.string("attention_reset.note.completed_before_feed", defaultValue: "Completed a reset before opening a feed")
        case .morningGate: return MoriL10n.string("attention_reset.note.completed_morning", defaultValue: "Completed a reset before the morning feed")
        }
    }

    var appLimitNote: String {
        switch self {
        case .beforeFeed: return MoriL10n.string("attention_reset.note.protected_before_feed", defaultValue: "Kept selected apps limited before the feed")
        case .morningGate: return MoriL10n.string("attention_reset.note.protected_morning", defaultValue: "Kept selected apps limited during Morning Gate")
        }
    }

    func title(durationText: String) -> String {
        switch self {
        case .beforeFeed:
            return MoriL10n.string("attention_reset.title.before_feed", defaultValue: "%@ reset", arguments: [durationText])
        case .morningGate:
            return MoriL10n.string("attention_reset.title.morning", defaultValue: "%@ morning reset", arguments: [durationText])
        }
    }

    func subtitle(technique: MoriBreathingTechnique?) -> String {
        switch self {
        case .beforeFeed:
            guard let technique else {
                return MoriL10n.string("attention_reset.subtitle.before_feed.no_technique", defaultValue: "Let the timer create a gap before opening the feed.")
            }
            return MoriL10n.string("attention_reset.subtitle.before_feed.technique", defaultValue: "Follow %@ before the feed chooses for you.", arguments: [technique.name])
        case .morningGate:
            guard let technique else {
                return MoriL10n.string("attention_reset.subtitle.morning.no_technique", defaultValue: "Keep the first window clear before the day starts pulling.")
            }
            return MoriL10n.string("attention_reset.subtitle.morning.technique", defaultValue: "Follow %@ before selected apps open.", arguments: [technique.name])
        }
    }

    func idleCue(hasTechnique: Bool, isComplete: Bool) -> String {
        if isComplete {
            switch self {
            case .beforeFeed: return MoriL10n.string("attention_reset.cue.before_feed.complete", defaultValue: "Open only if you still mean to")
            case .morningGate: return MoriL10n.string("attention_reset.cue.morning.complete", defaultValue: "Morning window open")
            }
        }

        switch self {
        case .beforeFeed:
            return hasTechnique
                ? MoriL10n.string("attention_reset.cue.before_feed.technique", defaultValue: "Settle first, then decide")
                : MoriL10n.string("attention_reset.cue.before_feed.no_technique", defaultValue: "Wait first, then decide")
        case .morningGate:
            return hasTechnique
                ? MoriL10n.string("attention_reset.cue.morning.technique", defaultValue: "Breathe first, then begin")
                : MoriL10n.string("attention_reset.cue.morning.no_technique", defaultValue: "Start without the feed")
        }
    }

    func runningCue(hasTechnique: Bool, breathingLabel: String) -> String {
        guard hasTechnique else {
            switch self {
            case .beforeFeed: return MoriL10n.string("attention_reset.running.before_feed.no_technique", defaultValue: "Wait out the urge")
            case .morningGate: return MoriL10n.string("attention_reset.running.morning.no_technique", defaultValue: "Hold the first window")
            }
        }
        return breathingLabel
    }
}

struct MoriAttentionResetContent: View {
    let context: MoriAttentionResetContext
    let resetDurationText: String
    let headerSubtitle: String
    let progress: CGFloat
    let breathingTint: Color
    let showsBreathingOrb: Bool
    let breathingVisualState: MoriBreathingCycleVisualState
    let isRunning: Bool
    let secondsRemaining: Int
    let timeText: String
    let cueText: String
    let limitText: String
    let openWindowText: String
    let onPrimaryAction: () -> Void
    let onReset: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                MoriPageHeader(
                    eyebrow: context.eyebrow,
                    title: context.title(durationText: resetDurationText),
                    subtitle: headerSubtitle
                )

                MoriAttentionResetTimerVisual(
                    progress: progress,
                    breathingTint: breathingTint,
                    showsBreathingOrb: showsBreathingOrb,
                    breathingVisualState: breathingVisualState,
                    isRunning: isRunning,
                    timeText: timeText,
                    cueText: cueText
                )

                MoriAttentionResetAppLimitCard(
                    limitText: limitText,
                    openWindowText: openWindowText
                )

                MoriAttentionResetControlRow(
                    context: context,
                    isRunning: isRunning,
                    secondsRemaining: secondsRemaining,
                    onPrimaryAction: onPrimaryAction,
                    onReset: onReset
                )
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
    }
}

private struct MoriAttentionResetTimerVisual: View {
    let progress: CGFloat
    let breathingTint: Color
    let showsBreathingOrb: Bool
    let breathingVisualState: MoriBreathingCycleVisualState
    let isRunning: Bool
    let timeText: String
    let cueText: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var watercolorPulse = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                MoriGeneratedArtImage(art: .resetRingWash, contentMode: .fit)
                    .opacity(watercolorBloomOpacity)
                    .blendMode(.multiply)
                    .blur(radius: reduceMotion ? 0 : 8)
                    .scaleEffect(watercolorBloomScale)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                MoriGeneratedArtImage(art: .resetRingWash, contentMode: .fit)
                    .opacity(0.96)
                    .blendMode(.multiply)
                    .scaleEffect(watercolorRingScale)
                    .rotationEffect(watercolorRingRotation)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text(timeText)
                    .font(.system(size: 54, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)
                    .monospacedDigit()
            }
            .frame(width: 294, height: 294)
            .frame(maxWidth: .infinity)
            .moriReduceMotionAnimation(.easeInOut(duration: 0.34), value: breathingVisualState.scale)

            Text(cueText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.botanicalMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 326)
        .onAppear(perform: updateWatercolorPulse)
        .onChange(of: isRunning) { _ in
            updateWatercolorPulse()
        }
        .onChange(of: showsBreathingOrb) { _ in
            updateWatercolorPulse()
        }
        .onChange(of: reduceMotion) { _ in
            updateWatercolorPulse()
        }
    }

    private var shouldAnimateGraphic: Bool {
        (isRunning || showsBreathingOrb) && !reduceMotion
    }

    private var watercolorRingScale: CGFloat {
        guard shouldAnimateGraphic else { return 1.0 }
        let breathScale = 1 + (breathingVisualState.scale - 1) * 0.10
        let pulseScale: CGFloat = watercolorPulse ? 1.018 : 0.992
        return breathScale * pulseScale
    }

    private var watercolorBloomScale: CGFloat {
        guard shouldAnimateGraphic else { return 1.04 }
        return watercolorPulse ? 1.095 : 1.025
    }

    private var watercolorBloomOpacity: Double {
        guard shouldAnimateGraphic else { return 0.10 }
        return watercolorPulse ? 0.24 : 0.12
    }

    private var watercolorRingRotation: Angle {
        guard shouldAnimateGraphic else { return .zero }
        let progressDrift = Double(1 - progress) * 3.4
        let pulseDrift = watercolorPulse ? 1.8 : -1.2
        return .degrees(progressDrift + pulseDrift)
    }

    private func updateWatercolorPulse() {
        guard shouldAnimateGraphic else {
            withAnimation(.easeOut(duration: 0.28)) {
                watercolorPulse = false
            }
            return
        }

        withAnimation(.easeInOut(duration: 4.8).repeatForever(autoreverses: true)) {
            watercolorPulse = true
        }
    }
}

private struct MoriAttentionResetAppLimitCard: View {
    let limitText: String
    let openWindowText: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 7) {
                MoriBitmapIconImage(icon: .timer, size: 14, opacity: 0.82)

                Text(limitText)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(MoriColors.botanicalInk)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(openWindowText)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(MoriColors.botanicalPaperDeep.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct MoriAttentionResetControlRow: View {
    let context: MoriAttentionResetContext
    let isRunning: Bool
    let secondsRemaining: Int
    let onPrimaryAction: () -> Void
    let onReset: () -> Void

    private var primaryTitle: String {
        if isRunning {
            return MoriL10n.display("Pause")
        }

        if secondsRemaining == 0 {
            return MoriL10n.display("Restart")
        }

        switch context {
        case .beforeFeed:
            return MoriL10n.display("Start reset")
        case .morningGate:
            return MoriL10n.display("Start")
        }
    }

    private var primaryIcon: MoriBitmapIcon {
        isRunning ? .pause : .play
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPrimaryAction) {
                HStack(spacing: 8) {
                    MoriBitmapIconImage(icon: primaryIcon, size: 16, opacity: 0.94)
                        .frame(width: 24, height: 24)
                        .background(MoriColors.sanctuarySurface.opacity(0.86))
                        .clipShape(Circle())

                    Text(primaryTitle)
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.botanicalSurface)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(MoriColors.botanicalInk)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onReset) {
                MoriBitmapIconImage(icon: .refresh, size: 17, opacity: 0.86)
                    .frame(width: 50, height: 50)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(MoriL10n.string(
                "attention_reset.timer.reset_accessibility",
                defaultValue: "Reset %@ timer",
                arguments: [context.navigationTitle]
            ))
        }
    }
}
