import SwiftUI

struct MoriBreathingCueToggleRow: View {
    let soundEnabled: Bool
    let hapticsEnabled: Bool
    let animationEnabled: Bool
    let darkRoomEnabled: Bool
    let isDarkRoomActive: Bool
    let onToggleSound: () -> Void
    let onToggleHaptics: () -> Void
    let onToggleAnimation: () -> Void
    let onToggleDarkRoom: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            MoriBreathingCueToggleButton(
                isOn: soundEnabled,
                onIcon: .sound,
                offIcon: .quiet,
                label: soundEnabled ? "Sound cues on" : "Sound cues off",
                isDarkRoomActive: isDarkRoomActive,
                action: onToggleSound
            )
            MoriBreathingCueToggleButton(
                isOn: hapticsEnabled,
                onIcon: .haptics,
                offIcon: .minus,
                label: hapticsEnabled ? "Haptics on" : "Haptics off",
                isDarkRoomActive: isDarkRoomActive,
                action: onToggleHaptics
            )
            MoriBreathingCueToggleButton(
                isOn: animationEnabled,
                onIcon: .roots,
                offIcon: .focus,
                label: animationEnabled ? "Animation on" : "Animation off",
                isDarkRoomActive: isDarkRoomActive,
                action: onToggleAnimation
            )
            MoriBreathingCueToggleButton(
                isOn: darkRoomEnabled,
                onIcon: .quiet,
                offIcon: .leaf,
                label: darkRoomEnabled ? "Dark room on" : "Dark room off",
                isDarkRoomActive: isDarkRoomActive,
                action: onToggleDarkRoom
            )
        }
    }
}

struct MoriBreathingControlRow: View {
    let runState: MoriBreathingRunState
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            switch runState {
            case .idle, .completed:
                primaryButton(
                    title: runState == .completed ? "Breathe again" : "Start",
                    icon: .play,
                    action: onStart
                )

            case .running:
                primaryButton(title: "Pause", icon: .pause, action: onPause)
                endButton

            case .paused:
                primaryButton(title: "Resume", icon: .play, action: onResume)
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
            .frame(width: 92)
            .padding(.vertical, 13)
            .background(MoriColors.botanicalInk.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func primaryButton(title: String, icon: MoriBitmapIcon, action: @escaping () -> Void) -> some View {
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
            .padding(.vertical, 13)
            .background(MoriColors.botanicalInk)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct MoriBreathingCueToggleButton: View {
    let isOn: Bool
    let onIcon: MoriBitmapIcon
    let offIcon: MoriBitmapIcon
    let label: String
    let isDarkRoomActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MoriBitmapIconImage(icon: isOn ? onIcon : offIcon, size: 16, opacity: isOn ? 0.88 : 0.48)
                .frame(width: 36, height: 36)
                .background(isDarkRoomActive ? Color.white.opacity(0.10) : MoriColors.botanicalInk.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display(label))
    }
}

struct MoriBreathingCompletionBanner: View {
    let summary: MoriBreathingCompletionSummary

    var body: some View {
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
}
