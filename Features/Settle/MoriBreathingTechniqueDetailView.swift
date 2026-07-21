import SwiftUI

struct MoriBreathingTechniqueDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.moriOpenSettleRoute) private var openSettleRoute

    let technique: MoriBreathingTechnique

    @State private var selectedDuration = 10
    @State private var techniqueForDurationSelection: MoriBreathingTechnique?
    @AppStorage("mori_settle_breathing_custom_inhale") private var customInhaleSeconds: Double = 4
    @AppStorage("mori_settle_breathing_custom_hold") private var customHoldSeconds: Double = 0
    @AppStorage("mori_settle_breathing_custom_exhale") private var customExhaleSeconds: Double = 6
    @AppStorage("mori_settle_breathing_custom_uses_hold") private var customUsesHold: Bool = false

    private var displayedPattern: MoriBreathPattern {
        technique.id == MoriBreathingTechniqueID.custom.rawValue
            ? MoriBreathPattern(
                inhale: max(1, customInhaleSeconds),
                inhaleHold: customUsesHold ? max(1, customHoldSeconds) : nil,
                exhale: max(1, customExhaleSeconds),
                exhaleHold: nil
            )
            : technique.breathPattern
    }

    var body: some View {
        MoriPaperBackground(variant: .breath) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    detailHero
                    patternMetrics
                    detailSection(title: "What It Is", icon: .leaf, body: technique.longDescription, tint: MoriColors.botanicalMoss)
                    benefitsSection
                    detailSection(title: "The Science", icon: .pulse, body: technique.scienceExplanation, tint: MoriColors.botanicalMist)
                    stepsSection
                    bestForSection
                    startButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Technique")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    MoriBitmapIconImage(icon: .chevron, size: 15, opacity: 0.88)
                        .rotationEffect(.degrees(180))
                }
                .accessibilityLabel("Back")
            }
        }
        .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .moriHidesMainTabBar()
        .sheet(item: $techniqueForDurationSelection) { selectedTechnique in
            MoriBreathingDurationPickerSheet(
                techniqueName: selectedTechnique.name,
                selectedDuration: $selectedDuration,
                onStart: {
                    techniqueForDurationSelection = nil
                    openBreathingSession(
                        techniqueID: selectedTechnique.id,
                        durationMinutes: selectedDuration
                    )
                }
            )
            .presentationDetents([.height(560), .large])
            .moriBotanicalSheetPresentation()
        }
    }

    private var detailHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                MoriBitmapIconBadge(
                    icon: technique.icon,
                    size: 52,
                    iconScale: 0.58,
                    fill: MoriColors.sanctuarySurface.opacity(0.76),
                    stroke: Color.white.opacity(0.88),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.18)
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(MoriL10n.display("BREATHING TECHNIQUE"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalMoss)

                    Text(MoriL10n.display(technique.name))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(MoriL10n.display(technique.shortDescription))
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var patternMetrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MoriMetricTile(
                title: "Pattern",
                value: MoriBreathingTechnique.patternDisplay(for: displayedPattern),
                detail: "breath rhythm",
                icon: .timer,
                tint: MoriColors.botanicalMoss
            )

            MoriMetricTile(
                title: "Frequency",
                value: String(format: "%.1f", displayedPattern.breathsPerMinute),
                detail: "breaths/min",
                icon: .pulse,
                tint: MoriColors.botanicalMist
            )
        }
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "Benefits", subtitle: "What this rhythm is commonly used for.")
            ForEach(technique.benefits, id: \.self) { benefit in
                HStack(alignment: .top, spacing: 8) {
                    MoriBitmapIconImage(icon: .leaf, size: 14, opacity: 0.72)
                        .padding(.top, 2)

                    Text(MoriL10n.display(benefit))
                }
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
            }
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "How To Breathe", subtitle: "Follow the reference sequence without forcing the breath.")
            ForEach(Array(technique.howToSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalSurface)
                        .frame(width: 24, height: 24)
                        .background(MoriColors.botanicalInk)
                        .clipShape(Circle())

                    Text(MoriL10n.display(step))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.botanicalInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }

    private var bestForSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "Best For", subtitle: "A quick match guide from the breathing library.")
            FlowLayout(spacing: 8) {
                ForEach(technique.bestFor, id: \.self) { item in
                    MoriPill(title: item, isSelected: false, tint: MoriColors.botanicalMist)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }

    private var startButton: some View {
        Button {
            techniqueForDurationSelection = technique
        } label: {
            HStack(spacing: 8) {
                MoriBitmapIconImage(icon: .play, size: 16, opacity: 0.94)
                    .frame(width: 24, height: 24)
                    .background(MoriColors.sanctuarySurface.opacity(0.86))
                    .clipShape(Circle())

                Text(MoriL10n.display("Choose Duration"))
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(MoriColors.botanicalSurface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(MoriColors.botanicalInk)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func openBreathingSession(techniqueID: String, durationMinutes: Int) {
        openSettleRoute(.breathingSession(
            techniqueID: techniqueID,
            durationMinutes: durationMinutes,
            autoStart: true
        ))
    }

    private func detailSection(title: String, icon: MoriBitmapIcon, body: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                MoriBitmapIconImage(icon: icon, size: 16, opacity: 0.82)

                Text(MoriL10n.display(title))
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(tint)

            Text(MoriL10n.display(body))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }
}
