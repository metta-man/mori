import SwiftUI

enum MoriBreathingLibraryRoute: Hashable {
    case techniqueDetail(String)
}

struct MoriBreathingTechniqueCard: View {
    let technique: MoriBreathingTechnique
    let onStart: () -> Void

    private var accent: Color {
        Color(hex: technique.gradientColors.first ?? "#687E5E")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                MoriBitmapIconBadge(
                    icon: technique.icon,
                    size: 42,
                    iconScale: 0.58,
                    fill: MoriColors.sanctuarySurface.opacity(0.76),
                    stroke: Color.white.opacity(0.88),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.18)
                )

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(MoriL10n.display(technique.name))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.botanicalInk)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 4)
                    }

                    Text(MoriL10n.display(technique.shortDescription))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                MoriMiniBadge(title: technique.category, icon: .journal, tint: accent)
                MoriMiniBadge(title: technique.patternDisplay, icon: .timer, tint: MoriColors.botanicalMist)
            }

            HStack(spacing: 10) {
                Button(action: onStart) {
                    HStack(spacing: 6) {
                        MoriBitmapIconImage(icon: .play, size: 15, opacity: 0.94)
                            .frame(width: 22, height: 22)
                            .background(MoriColors.sanctuarySurface.opacity(0.86))
                            .clipShape(Circle())

                        Text(MoriL10n.display("Start"))
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(MoriColors.botanicalInk)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                NavigationLink(value: MoriBreathingLibraryRoute.techniqueDetail(technique.id)) {
                    HStack(spacing: 6) {
                        MoriBitmapIconImage(icon: .journal, size: 15, opacity: 0.84)

                        Text(MoriL10n.display("Details"))
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }
}

struct MoriMiniBadge: View {
    let title: String
    let icon: MoriBitmapIcon
    let tint: Color

    init(title: String, icon: MoriBitmapIcon, tint: Color) {
        self.title = title
        self.icon = icon
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 5) {
            MoriBitmapIconImage(icon: icon, size: 12, opacity: 0.78)

            Text(MoriL10n.display(title))
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundColor(tint)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tint.opacity(0.11))
        .clipShape(Capsule())
    }
}

struct MoriBreathingDurationPickerSheet: View {
    let techniqueName: String
    @Binding var selectedDuration: Int
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        MoriPaperBackground(variant: .breath) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Text(MoriL10n.display("Choose Duration"))
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.botanicalInk)

                        Text(MoriL10n.display(techniqueName))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MoriColors.botanicalMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(MoriL10n.display("The reference library supports short resets through long practice blocks."))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(MoriColors.botanicalMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 22)

                    Picker(MoriL10n.display("Duration"), selection: $selectedDuration) {
                        ForEach(MoriBreathingSessionDurationOptions.pickerOptions, id: \.self) { minutes in
                            Text(MoriL10n.string("duration.minutes_short", defaultValue: "%dm", arguments: [minutes])).tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(MoriBreathingSessionDurationOptions.presets, id: \.self) { minutes in
                            Button {
                                selectedDuration = minutes
                            } label: {
                                Text(MoriL10n.string("duration.minutes_short", defaultValue: "%dm", arguments: [minutes]))
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedDuration == minutes ? MoriColors.botanicalSurface : MoriColors.botanicalInk)
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(selectedDuration == minutes ? MoriColors.botanicalInk : MoriColors.botanicalInk.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(MoriL10n.display("Custom length"))
                            Spacer()
                            Text(MoriL10n.string("duration.minutes_short", defaultValue: "%dm", arguments: [selectedDuration]))
                                .monospacedDigit()
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)

                        Slider(value: Binding(
                            get: { Double(selectedDuration) },
                            set: { selectedDuration = Int($0.rounded()) }
                        ), in: 1...180, step: 1)
                        .tint(MoriColors.botanicalMoss)
                    }

                    HStack(spacing: 10) {
                        Button {
                            dismiss()
                        } label: {
                            Text(MoriL10n.display("Cancel"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(MoriColors.botanicalInk)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(MoriColors.botanicalInk.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button(action: onStart) {
                            HStack(spacing: 8) {
                                MoriBitmapIconImage(icon: .play, size: 16, opacity: 0.94)
                                    .frame(width: 24, height: 24)
                                    .background(MoriColors.sanctuarySurface.opacity(0.86))
                                    .clipShape(Circle())

                                Text(MoriL10n.display("Start Session"))
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(MoriColors.botanicalSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(MoriColors.botanicalInk)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 22)
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
