import SwiftUI

struct MindfulnessBellHeroVisual: View {
    var body: some View {
        ZStack {
            MoriWatercolorHeroWash(variant: .practice, placement: .corner)
                .clipShape(Circle())
                .frame(width: 148, height: 148)
                .opacity(0.72)
                .shadow(color: MoriColors.sanctuaryShadow.opacity(0.14), radius: 20, x: 0, y: 12)

            MoriBitmapIconBadge(
                icon: .bell,
                size: 50,
                iconScale: 0.50,
                fill: MoriColors.sanctuarySurface.opacity(0.62),
                stroke: Color.white.opacity(0.82),
                shadow: .clear
            )
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
    }
}

struct MindfulnessBellStatusCard: View {
    let isActive: Bool
    let nextFireTimestamp: Double
    let authorizationStatus: String
    let authorizationDenied: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                MoriBitmapIconBadge(icon: .bell, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(MindfulnessBellStatusFormatter.nextBellText(isActive: isActive, nextFireTimestamp: nextFireTimestamp))
                        .font(.system(size: 19, weight: .regular, design: .serif))
                        .foregroundColor(MoriColors.sanctuaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(MoriL10n.string("status.with_value", defaultValue: "Status: %@", arguments: [authorizationStatus]))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MoriColors.botanicalMuted)
                }
            }

            if authorizationDenied {
                Text("Notifications are off. Enable them in iOS Settings to use this bell.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalClay)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

struct MindfulnessBellToggleCard: View {
    @Binding var isActive: Bool

    var body: some View {
        Toggle(isOn: $isActive) {
            HStack(spacing: 9) {
                MoriBitmapIconImage(icon: .bell, size: 20)
                Text("Bell notifications")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(MoriColors.sanctuaryInk)
        }
        .tint(MoriColors.botanicalMoss)
        .moriSanctuaryCard(cornerRadius: 20, padding: 18)
    }
}

struct MindfulnessBellStatusToggleCard: View {
    @Binding var isActive: Bool
    let nextFireTimestamp: Double
    let authorizationStatus: String
    let authorizationDenied: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                MoriBitmapIconBadge(icon: .bell, size: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(MindfulnessBellStatusFormatter.nextBellText(isActive: isActive, nextFireTimestamp: nextFireTimestamp))
                        .font(.system(size: 19, weight: .regular, design: .serif))
                        .foregroundColor(MoriColors.sanctuaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(MoriL10n.string("status.with_value", defaultValue: "Status: %@", arguments: [authorizationStatus]))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MoriColors.botanicalMuted)
                }
            }

            if authorizationDenied {
                Text("Notifications are off. Enable them in iOS Settings to use this bell.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalClay)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .overlay(MoriColors.botanicalLine.opacity(0.72))

            Toggle(isOn: $isActive) {
                HStack(spacing: 9) {
                    MoriBitmapIconImage(icon: .bell, size: 20)
                    Text("Bell notifications")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.sanctuaryInk)
            }
            .tint(MoriColors.botanicalMoss)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

struct MindfulnessBellRhythmControls: View {
    @Binding var randomMode: Bool
    @Binding var intervalMinutes: Int
    @Binding var bellsPerHour: Int

    private let intervalOptions = [5, 10, 15, 30, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Rhythm",
                subtitle: "Use a steady interval, or place a few quiet bells inside each active hour."
            )

            HStack(spacing: 10) {
                MindfulnessBellModeButton(title: "Fixed", isSelected: !randomMode) {
                    randomMode = false
                }

                MindfulnessBellModeButton(title: "Random", isSelected: randomMode) {
                    randomMode = true
                }
            }

            if randomMode {
                MindfulnessBellStepper(
                    title: "Bells per hour",
                    value: "\(bellsPerHour)",
                    decrementDisabled: bellsPerHour <= 1,
                    incrementDisabled: bellsPerHour >= 4,
                    decrement: { bellsPerHour = max(1, bellsPerHour - 1) },
                    increment: { bellsPerHour = min(4, bellsPerHour + 1) }
                )
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(intervalOptions, id: \.self) { minutes in
                        Button {
                            intervalMinutes = minutes
                        } label: {
                            MoriPill(
                                title: "\(minutes)m",
                                isSelected: intervalMinutes == minutes,
                                tint: MoriColors.botanicalMoss
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

struct MindfulnessBellActiveHoursControls: View {
    @Binding var startHour: Int
    @Binding var endHour: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Active Hours",
                subtitle: "Keep the bell inside the part of the day where a pause helps."
            )

            MindfulnessBellStepper(
                title: "Start",
                value: formattedHour(startHour),
                decrementDisabled: startHour <= 0,
                incrementDisabled: startHour >= 23,
                decrement: { startHour = max(0, startHour - 1) },
                increment: { startHour = min(23, startHour + 1) }
            )

            MindfulnessBellStepper(
                title: "End",
                value: formattedHour(endHour),
                decrementDisabled: endHour <= 0,
                incrementDisabled: endHour >= 23,
                decrement: { endHour = max(0, endHour - 1) },
                increment: { endHour = min(23, endHour + 1) }
            )
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private func formattedHour(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }
}

struct MindfulnessBellTapActionControls: View {
    @Binding var breathingTechniqueID: String
    @Binding var breathingDurationMinutes: Int

    private let breathingDurationOptions = [1, 2, 3, 5]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Tap Action",
                subtitle: "Choose the breathing reset that opens from the bell."
            )

            HStack(spacing: 10) {
                HStack(spacing: 7) {
                    MoriBitmapIconImage(icon: .breathe, size: 18)
                    Text("Technique")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.sanctuaryMuted)

                Spacer(minLength: 0)

                Picker("Technique", selection: $breathingTechniqueID) {
                    ForEach(MoriBreathingTechniqueRepository.techniques) { technique in
                        Text(technique.name).tag(technique.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(MoriColors.botanicalInk)
            }
            .padding(12)
            .background(MoriColors.botanicalPaperDeep.opacity(0.48))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            FlowLayout(spacing: 8) {
                ForEach(breathingDurationOptions, id: \.self) { minutes in
                    Button {
                        breathingDurationMinutes = minutes
                    } label: {
                        MoriPill(
                            title: "\(minutes)m",
                            isSelected: breathingDurationMinutes == minutes,
                            tint: MoriColors.botanicalMoss
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

struct MindfulnessBellActionButtons: View {
    let onPreview: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onPreview) {
                HStack(spacing: 8) {
                    MoriBitmapIconImage(icon: .bell, size: 18)
                    Text("Preview")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MoriColors.sanctuaryInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(MoriColors.sanctuaryInk.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onRefresh) {
                HStack(spacing: 8) {
                    MoriBitmapIconImage(icon: .refresh, size: 18)
                    Text("Refresh")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MoriColors.sanctuarySurface)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    MoriGeneratedArtImage(art: .buttonWash, contentMode: .fill)
                        .overlay(MoriColors.sanctuaryInk.opacity(0.15))
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct MindfulnessBellModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(MoriL10n.display(title))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? MoriColors.botanicalSurface : MoriColors.botanicalInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(isSelected ? MoriColors.botanicalInk : MoriColors.botanicalInk.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MindfulnessBellStepper: View {
    let title: String
    let value: String
    let decrementDisabled: Bool
    let incrementDisabled: Bool
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalMuted)

                Text(MoriL10n.display(value))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)

            Button(action: decrement) {
                MoriBitmapIconImage(icon: .minus, size: 16, opacity: decrementDisabled ? 0.36 : 1)
                    .frame(width: 36, height: 36)
            }
            .disabled(decrementDisabled)
            .background(MoriColors.sanctuaryInk.opacity(0.08))
            .clipShape(Circle())
            .buttonStyle(.plain)

            Button(action: increment) {
                MoriBitmapIconImage(icon: .plus, size: 16, opacity: incrementDisabled ? 0.36 : 1)
                    .frame(width: 36, height: 36)
            }
            .disabled(incrementDisabled)
            .background(MoriColors.sanctuaryInk.opacity(0.08))
            .clipShape(Circle())
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(MoriColors.botanicalPaperDeep.opacity(0.48))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
