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

extension MoriBeforeFeedIntentReason {
    var displayTitle: String {
        switch self {
        case .replyToSomeone:
            return MoriL10n.display("Reply to someone")
        case .learn:
            return MoriL10n.display("Learn")
        case .relax:
            return MoriL10n.display("Relax")
        case .habit:
            return MoriL10n.display("Habit")
        case .other:
            return MoriL10n.display("Other")
        }
    }
}

struct MoriBeforeFeedReasonContent: View {
    let selectedReason: MoriBeforeFeedIntentReason?
    let secondaryContext: String?
    let onSelectReason: (MoriBeforeFeedIntentReason) -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text(MoriL10n.display("Why now?"))
                        .font(MoriTypography.sanctuaryDisplay)
                        .foregroundColor(MoriColors.sanctuaryInk)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(MoriL10n.display("Pause. Notice. Choose."))
                        .font(MoriTheme.Typography.supporting)
                        .foregroundColor(MoriColors.sanctuaryMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    ForEach(MoriBeforeFeedIntentReason.allCases) { reason in
                        reasonButton(reason)
                    }
                }
                .padding(.top, 28)

                if let secondaryContext {
                    Text(secondaryContext)
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.sanctuaryMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                        .padding(.top, 18)
                        .accessibilityHint(MoriL10n.display("This is context about how the pause opened."))
                }

                MoriResetPrimaryButton(
                    title: MoriL10n.display("Continue"),
                    isEnabled: selectedReason != nil,
                    action: onContinue
                )
                .padding(.top, 20)
                .accessibilityHint(
                    selectedReason == nil
                        ? MoriL10n.display("Choose a reason first.")
                        : MoriL10n.display("Continues with the selected reason.")
                )
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal, 26)
            .padding(.top, 24)
            .padding(.bottom, 36)
        }
    }

    private func reasonButton(_ reason: MoriBeforeFeedIntentReason) -> some View {
        let isSelected = selectedReason == reason

        return Button {
            onSelectReason(reason)
        } label: {
            HStack(spacing: 14) {
                Text(reason.displayTitle)
                    .font(MoriTheme.Typography.control)
                    .foregroundColor(MoriColors.sanctuaryInk)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 12)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 23, weight: .regular))
                    .foregroundColor(
                        isSelected
                            ? MoriColors.sanctuaryInkSoft
                            : MoriColors.sanctuaryMuted.opacity(0.42)
                    )
                    .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            }
            .padding(.horizontal, 17)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(
                isSelected
                    ? MoriColors.sanctuarySage.opacity(0.19)
                    : MoriColors.sanctuarySurface.opacity(0.68)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected
                            ? MoriColors.sanctuaryInk.opacity(0.30)
                            : MoriColors.sanctuaryLine.opacity(0.62),
                        lineWidth: 0.8
                    )
            }
            .shadow(
                color: MoriColors.sanctuaryShadow.opacity(isSelected ? 0.20 : 0.10),
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reason.displayTitle)
        .accessibilityValue(
            isSelected ? MoriL10n.display("Selected") : MoriL10n.display("Not selected")
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(MoriL10n.display("Selects this reason for opening the feed."))
    }
}

struct MoriBeforeFeedPauseOfferContent: View {
    let resetDurationText: String
    let timeText: String
    let selectedReason: MoriBeforeFeedIntentReason?
    let secondaryContext: String?
    let onBeginPause: () -> Void
    let onContinueNow: () -> Void
    let onBack: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    MoriBeforeFeedBackAction(action: onBack)

                    VStack(spacing: 7) {
                        if let selectedReason {
                            Text(selectedReason.displayTitle.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.1)
                                .foregroundColor(MoriColors.sanctuarySage)
                        }

                        Text(MoriL10n.display("A short pause?"))
                            .font(MoriTypography.sanctuaryDisplay)
                            .foregroundColor(MoriColors.sanctuaryInk)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Text(MoriL10n.string(
                            "before_feed.offer.subtitle",
                            defaultValue: "%@, if it would help.",
                            arguments: [resetDurationText]
                        ))
                            .font(MoriTheme.Typography.supporting)
                            .foregroundColor(MoriColors.sanctuaryMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    MoriResetBreathingComposition(
                        context: .beforeFeed,
                        visualState: .idle,
                        isRunning: false,
                        showsBreathingOrb: true,
                        timeText: timeText,
                        cueText: MoriL10n.display("A moment to choose")
                    )
                    .frame(height: 300)
                    .padding(.top, 4)

                    MoriResetPrimaryButton(
                        title: MoriL10n.display("Begin quiet pause"),
                        icon: .play,
                        action: onBeginPause
                    )

                    Button(action: onContinueNow) {
                        Text(MoriL10n.display("Continue now"))
                            .font(MoriTheme.Typography.control)
                            .foregroundColor(MoriColors.sanctuaryInkSoft)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 18)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 7)
                    .accessibilityHint(MoriL10n.display("Continues without starting the optional pause."))

                    if let secondaryContext {
                        Text(secondaryContext)
                            .font(MoriTypography.caption)
                            .foregroundColor(MoriColors.sanctuaryMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                            .padding(.top, 12)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.horizontal, 26)
                .padding(.bottom, 28)
            }
        }
    }
}

struct MoriBeforeFeedPauseContent: View {
    let showsBreathingOrb: Bool
    let breathingVisualState: MoriBreathingCycleVisualState
    let isRunning: Bool
    let timeText: String
    let cueText: String
    let secondaryContext: String?
    let onToggleBreathing: () -> Void
    let onBack: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    MoriBeforeFeedBackAction(action: onBack)

                    VStack(spacing: 7) {
                        Text(MoriL10n.display("Stay with the pause"))
                            .font(MoriTypography.sanctuaryDisplay)
                            .foregroundColor(MoriColors.sanctuaryInk)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)

                        Text(MoriL10n.display("Let one breath follow the next."))
                            .font(MoriTheme.Typography.supporting)
                            .foregroundColor(MoriColors.sanctuaryMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    MoriResetBreathingComposition(
                        context: .beforeFeed,
                        visualState: breathingVisualState,
                        isRunning: isRunning,
                        showsBreathingOrb: showsBreathingOrb,
                        timeText: timeText,
                        cueText: cueText
                    )
                    .frame(height: 340)
                    .padding(.top, 2)

                    MoriResetCompactButton(
                        title: MoriL10n.display(isRunning ? "Pause" : "Resume"),
                        icon: isRunning ? .pause : .play,
                        action: onToggleBreathing
                    )

                    if let secondaryContext {
                        Text(secondaryContext)
                            .font(MoriTypography.caption)
                            .foregroundColor(MoriColors.sanctuaryMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                            .padding(.top, 20)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.horizontal, 26)
                .padding(.bottom, 30)
            }
        }
    }
}

struct MoriBeforeFeedCompletionContent: View {
    let secondaryContext: String?
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    MoriBeforeFeedBackAction(action: onBack)

                    VStack(spacing: 8) {
                        Text(MoriL10n.display("Pause complete"))
                            .font(MoriTypography.sanctuaryDisplay)
                            .foregroundColor(MoriColors.sanctuaryInk)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Text(MoriL10n.display("Continue only if the feed still feels intentional."))
                            .font(MoriTheme.Typography.supporting)
                            .foregroundColor(MoriColors.sanctuaryMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 310)
                    }
                    .padding(.top, 12)

                    MoriResetBreathingComposition(
                        context: .beforeFeed,
                        visualState: .idle,
                        isRunning: false,
                        showsBreathingOrb: true,
                        timeText: "00:00",
                        cueText: MoriL10n.display("A little room to choose")
                    )
                    .frame(height: 310)
                    .padding(.top, 2)

                    MoriResetPrimaryButton(
                        title: MoriL10n.display("Continue now"),
                        action: onContinue
                    )

                    if let secondaryContext {
                        Text(secondaryContext)
                            .font(MoriTypography.caption)
                            .foregroundColor(MoriColors.sanctuaryMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 320)
                            .padding(.top, 18)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.horizontal, 26)
                .padding(.bottom, 30)
            }
        }
    }
}

private struct MoriResetBreathingComposition: View {
    let context: MoriAttentionResetContext
    let visualState: MoriBreathingCycleVisualState
    let isRunning: Bool
    let showsBreathingOrb: Bool
    let timeText: String
    let cueText: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            MoriBreathingInkBloomView(
                visualState: visualState,
                isSessionActive: isRunning && showsBreathingOrb,
                animationEnabled: isRunning && showsBreathingOrb
            )
            .frame(
                width: dynamicTypeSize.isAccessibilitySize ? 252 : 310,
                height: dynamicTypeSize.isAccessibilitySize ? 252 : 310
            )

            VStack(spacing: 7) {
                Text(cueText)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(MoriColors.sanctuaryInkSoft.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                Text(timeText)
                    .font(.system(size: 58, weight: .light, design: .serif))
                    .foregroundColor(MoriColors.sanctuaryInk)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let remainingDescription = MoriL10n.string(
            "before_feed.breath.time_remaining_accessibility",
            defaultValue: "%@ remaining. %@",
            arguments: [timeText, cueText]
        )
        return "\(context.navigationTitle). \(remainingDescription)"
    }
}

private struct MoriBeforeFeedBackAction: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                MoriBitmapIconImage(icon: .chevron, size: 12, opacity: 0.80)
                    .rotationEffect(.degrees(180))

                Text(MoriL10n.display("Choose another reason"))
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(MoriColors.sanctuaryMuted)
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MoriResetPrimaryButton: View {
    let title: String
    var icon: MoriBitmapIcon?
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    MoriBitmapIconImage(icon: icon, size: 15, opacity: 0.92)
                        .frame(width: 28, height: 28)
                        .background(MoriColors.sanctuarySurface.opacity(0.90))
                        .clipShape(Circle())
                }

                Text(title)
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(MoriColors.sanctuarySurface)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(MoriColors.sanctuaryInk)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: MoriColors.sanctuaryShadow.opacity(0.30), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.34)
        .frame(maxWidth: 320)
    }
}

private struct MoriResetCompactButton: View {
    let title: String
    let icon: MoriBitmapIcon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                MoriBitmapIconImage(
                    icon: icon,
                    size: 13,
                    opacity: 0.78
                )

                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(MoriColors.sanctuaryInkSoft)
            .padding(.horizontal, 20)
            .frame(minHeight: 46)
            .background(MoriColors.sanctuarySurface.opacity(0.72))
            .clipShape(Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(MoriColors.sanctuaryHairline, lineWidth: 0.8)
            }
            .shadow(color: MoriColors.sanctuaryShadow.opacity(0.18), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

struct MoriMorningResetContent: View {
    let context: MoriAttentionResetContext
    let resetDurationText: String
    let headerSubtitle: String
    let showsBreathingOrb: Bool
    let breathingVisualState: MoriBreathingCycleVisualState
    let isRunning: Bool
    let hasStarted: Bool
    let secondsRemaining: Int
    let timeText: String
    let cueText: String
    let limitText: String
    let openWindowText: String
    let onPrimaryAction: () -> Void
    let onReset: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isComplete: Bool {
        secondsRemaining == 0
    }

    private var isPaused: Bool {
        hasStarted && !isRunning && !isComplete
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 7) {
                        Text(context.eyebrow.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.1)
                            .foregroundColor(MoriColors.sanctuarySage)

                        Text(context.title(durationText: resetDurationText))
                            .font(MoriTypography.sanctuaryDisplay)
                            .foregroundColor(MoriColors.sanctuaryInk)
                            .multilineTextAlignment(.center)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                            .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 0.78 : 0.64)

                        Text(headerSubtitle)
                            .font(MoriTheme.Typography.supporting)
                            .foregroundColor(MoriColors.sanctuaryMuted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 330)
                    }
                    .padding(.top, dynamicTypeSize.isAccessibilitySize ? 16 : 26)

                    MoriResetBreathingComposition(
                        context: context,
                        visualState: breathingVisualState,
                        isRunning: isRunning,
                        showsBreathingOrb: showsBreathingOrb,
                        timeText: timeText,
                        cueText: cueText
                    )
                    .frame(height: dynamicTypeSize.isAccessibilitySize ? 286 : 326)
                    .padding(.top, dynamicTypeSize.isAccessibilitySize ? 0 : 8)

                    controlContent
                        .padding(.top, dynamicTypeSize.isAccessibilitySize ? 6 : 12)

                    MoriResetAppLimitNote(
                        limitText: limitText,
                        openWindowText: openWindowText
                    )
                    .padding(.top, 22)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.horizontal, 26)
                .padding(.bottom, 32)
            }
        }
    }

    @ViewBuilder
    private var controlContent: some View {
        if isRunning || isPaused {
            HStack(spacing: 14) {
                MoriResetCompactButton(
                    title: MoriL10n.display(isRunning ? "Pause" : "Resume"),
                    icon: isRunning ? .pause : .play,
                    action: onPrimaryAction
                )

                MoriResetLightweightAction(
                    title: MoriL10n.display("Reset"),
                    icon: .refresh,
                    action: onReset
                )
                .accessibilityLabel(MoriL10n.string(
                    "attention_reset.timer.reset_accessibility",
                    defaultValue: "Reset %@ timer",
                    arguments: [context.navigationTitle]
                ))
            }
        } else {
            MoriResetPrimaryButton(
                title: MoriL10n.display(isComplete ? "Restart" : "Start"),
                icon: isComplete ? .refresh : .play,
                action: onPrimaryAction
            )
        }
    }
}

private struct MoriResetAppLimitNote: View {
    let limitText: String
    let openWindowText: String

    var body: some View {
        VStack(spacing: 7) {
            Text(limitText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MoriColors.sanctuaryInkSoft.opacity(0.86))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(openWindowText)
                .font(MoriTypography.caption)
                .foregroundColor(MoriColors.sanctuaryMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 330)
        .accessibilityElement(children: .combine)
    }
}

private struct MoriResetLightweightAction: View {
    let title: String
    let icon: MoriBitmapIcon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                MoriBitmapIconImage(icon: icon, size: 12, opacity: 0.68)

                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(MoriColors.sanctuaryMuted)
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}
