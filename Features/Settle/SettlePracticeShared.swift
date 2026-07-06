import SwiftUI

struct MindfulCompletionSummary {
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

func mindfulCompletionBanner(_ summary: MindfulCompletionSummary) -> some View {
    HStack(alignment: .center, spacing: 12) {
        MoriBitmapIconImage(icon: summary.icon, size: 21, opacity: 0.88)
            .frame(width: 36, height: 36)
            .background(MoriColors.sanctuarySurface.opacity(0.74))
            .clipShape(Circle())

        VStack(alignment: .leading, spacing: 3) {
            Text(MoriL10n.display(summary.title))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.botanicalInk)

            Text(MoriL10n.string(
                "settle.completion.minutes_seed",
                defaultValue: "%dm completed · %d Seeds",
                arguments: [summary.minutes, summary.seeds]
            ))
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
        }

        Spacer()
    }
    .padding(14)
    .background(summary.tint.opacity(0.10))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
}

func settleControlButton(
    title: String,
    icon: MoriBitmapIcon,
    tint: Color,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        HStack(spacing: 8) {
            MoriBitmapIconImage(icon: icon, size: 16, opacity: 0.94)
                .frame(width: 24, height: 24)
                .background(MoriColors.sanctuarySurface.opacity(0.86))
                .clipShape(Circle())

            Text(MoriL10n.display(title))
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(MoriColors.botanicalSurface)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(tint)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    .buttonStyle(.plain)
}

func formatTime(_ seconds: Int) -> String {
    let minutes = max(0, seconds) / 60
    let seconds = max(0, seconds) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

enum SettleTimerState: Equatable {
    case idle
    case running
    case paused
    case completed

    var label: String {
        switch self {
        case .idle: return MoriL10n.string("settle.timer.state.ready", defaultValue: "ready")
        case .running: return MoriL10n.string("settle.timer.state.settling", defaultValue: "settling")
        case .paused: return MoriL10n.string("settle.timer.state.paused", defaultValue: "paused")
        case .completed: return MoriL10n.string("settle.timer.state.complete", defaultValue: "complete")
        }
    }

    var subtitle: String {
        switch self {
        case .idle: return MoriL10n.string("settle.timer.state.ready.subtitle", defaultValue: "Choose a duration and let the room get quiet.")
        case .running: return MoriL10n.string("settle.timer.state.settling.subtitle", defaultValue: "Stay with the bell and the breath.")
        case .paused: return MoriL10n.string("settle.timer.state.paused.subtitle", defaultValue: "The reset is waiting.")
        case .completed: return MoriL10n.string("settle.timer.state.complete.subtitle", defaultValue: "A mindful action has become a Seed.")
        }
    }

    var icon: MoriBitmapIcon {
        switch self {
        case .idle: return .leaf
        case .running: return .breathe
        case .paused: return .pause
        case .completed: return .leaf
        }
    }

    var symbolName: String { icon.legacySystemName }

    var canChangeDuration: Bool {
        self == .idle || self == .completed
    }

    var isActive: Bool {
        self == .running || self == .paused
    }
}
