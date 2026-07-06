import SwiftUI

struct SettleTimerToggleRow: View {
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @Binding var animationEnabled: Bool
    @Binding var darkRoomEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            SettleTimerMinimalToggleButton(
                isOn: soundEnabled,
                isDarkRoomEnabled: darkRoomEnabled,
                onIcon: .sound,
                offIcon: .quiet,
                label: soundEnabled ? "Sound on" : "Sound off"
            ) {
                soundEnabled.toggle()
            }

            SettleTimerMinimalToggleButton(
                isOn: hapticsEnabled,
                isDarkRoomEnabled: darkRoomEnabled,
                onIcon: .haptics,
                offIcon: .minus,
                label: hapticsEnabled ? "Haptics on" : "Haptics off"
            ) {
                hapticsEnabled.toggle()
            }

            SettleTimerMinimalToggleButton(
                isOn: animationEnabled,
                isDarkRoomEnabled: darkRoomEnabled,
                onIcon: .roots,
                offIcon: .focus,
                label: animationEnabled ? "Animation on" : "Animation off"
            ) {
                animationEnabled.toggle()
            }

            SettleTimerMinimalToggleButton(
                isOn: darkRoomEnabled,
                isDarkRoomEnabled: darkRoomEnabled,
                onIcon: .quiet,
                offIcon: .leaf,
                label: darkRoomEnabled ? "Dark room on" : "Dark room off"
            ) {
                darkRoomEnabled.toggle()
            }
        }
    }
}

struct SettleTimerDurationPicker: View {
    let durationOptions: [Int]
    let recommendedMinutes: Int
    let timerState: SettleTimerState
    @Binding var selectedMinutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Duration")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MoriColors.botanicalMuted)

            FlowLayout(spacing: 8) {
                ForEach(durationOptions, id: \.self) { minutes in
                    Button {
                        guard timerState.canChangeDuration else { return }
                        selectedMinutes = minutes
                    } label: {
                        MoriPill(
                            title: "\(minutes)m",
                            icon: minutes == recommendedMinutes ? .leaf : nil,
                            isSelected: selectedMinutes == minutes,
                            tint: minutes == recommendedMinutes ? MoriColors.botanicalMoss : MoriColors.botanicalInk
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!timerState.canChangeDuration)
                    .accessibilityLabel(MoriL10n.string(
                        "settle.duration.accessibility",
                        defaultValue: "%d minute Settle reset",
                        arguments: [minutes]
                    ))
                }
            }
        }
    }
}

struct SettleTimerControlRow: View {
    let timerState: SettleTimerState
    let onStart: () -> Void
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

            case .running:
                settleControlButton(title: "Pause", icon: .pause, tint: MoriColors.botanicalInk, action: onPause)
                SettleTimerEndButton(action: onEnd)

            case .paused:
                settleControlButton(title: "Resume", icon: .play, tint: MoriColors.botanicalInk, action: onResume)
                SettleTimerEndButton(action: onEnd)
            }
        }
    }
}

struct SettleBellSettingsCard: View {
    @Binding var intervalBellEnabled: Bool
    @Binding var intervalBellMinutes: Int
    let intervalOptions: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Bells",
                subtitle: "Soft sound at the beginning and end, with an optional interval bell."
            )

            Toggle(isOn: $intervalBellEnabled) {
                HStack(spacing: 8) {
                    MoriBitmapIconImage(icon: .bell, size: 17, opacity: 0.84)

                    Text("Interval bell")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.botanicalInk)
            }
            .tint(MoriColors.botanicalMoss)

            if intervalBellEnabled {
                FlowLayout(spacing: 8) {
                    ForEach(intervalOptions, id: \.self) { minutes in
                        Button {
                            intervalBellMinutes = minutes
                        } label: {
                            MoriPill(
                                title: "\(minutes)m",
                                isSelected: intervalBellMinutes == minutes,
                                tint: MoriColors.botanicalMist
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

struct SettleRecommendationCard: View {
    let recommendedMinutes: Int
    let weeklySummary: SettleWeeklySummary
    let onUseRecommendation: () -> Void
    let onStartRecommendation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                MoriBitmapIconBadge(
                    icon: .refresh,
                    size: 38,
                    iconScale: 0.58,
                    fill: MoriColors.sanctuarySurface.opacity(0.76),
                    stroke: Color.white.opacity(0.88),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.18)
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text("Recommended reset")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalMoss)

                    Text(MoriL10n.string("settle.recommended_minutes", defaultValue: "%d minutes to settle", arguments: [recommendedMinutes]))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(recommendationCopy)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button(action: onUseRecommendation) {
                    HStack(spacing: 6) {
                        MoriBitmapIconImage(icon: .timer, size: 15, opacity: 0.84)

                        Text("Set duration")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onStartRecommendation) {
                    HStack(spacing: 6) {
                        MoriBitmapIconImage(icon: .play, size: 15, opacity: 0.94)
                            .frame(width: 22, height: 22)
                            .background(MoriColors.sanctuarySurface.opacity(0.86))
                            .clipShape(Circle())

                        Text("Start")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(MoriColors.botanicalInk)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var recommendationCopy: String {
        if weeklySummary.completedSessions == 0 {
            return MoriL10n.string("settle.recommendation.first_sit", defaultValue: "A small first sit is enough to turn noise into presence.")
        }

        if weeklySummary.consistencyDays >= 4 {
            return MoriL10n.string("settle.recommendation.deeper_sit", defaultValue: "Your roots are steady enough for a slightly deeper sit.")
        }

        return MoriL10n.string("settle.recommendation.repeatable", defaultValue: "Keep the rhythm gentle and repeatable.")
    }
}

private struct SettleTimerMinimalToggleButton: View {
    let isOn: Bool
    let isDarkRoomEnabled: Bool
    let onIcon: MoriBitmapIcon
    let offIcon: MoriBitmapIcon
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MoriBitmapIconImage(icon: isOn ? onIcon : offIcon, size: 17, opacity: isOn ? 0.88 : 0.48)
                .frame(width: 42, height: 42)
                .background(isDarkRoomEnabled ? Color.white.opacity(0.10) : MoriColors.botanicalInk.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display(label))
    }
}

private struct SettleTimerEndButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
