import SwiftUI

struct MoriBreathingLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.moriOpenSettleRoute) private var openSettleRoute
    @State private var searchText = ""
    @State private var selectedMood: MoriBreathMood = .all
    @State private var selectedDuration = 10
    @State private var techniqueForDurationSelection: MoriBreathingTechnique?

    private var filteredTechniques: [MoriBreathingTechnique] {
        MoriBreathingTechniqueRepository.search(query: searchText, mood: selectedMood)
    }

    var body: some View {
        MoriPaperBackground(variant: .breath) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    MoriPageHeader(
                        eyebrow: "Breathing",
                        title: "Breathing Library",
                        subtitle: "Choose a full guided pattern from the mindfulness-timer library, then run it here."
                    )

                    searchField
                    moodFilterRow

                    LazyVStack(spacing: 14) {
                        ForEach(filteredTechniques) { technique in
                            MoriBreathingTechniqueCard(
                                technique: technique,
                                onStart: { selectDuration(for: technique) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Breathing")
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
        .navigationDestination(for: MoriBreathingLibraryRoute.self) { route in
            switch route {
            case .techniqueDetail(let techniqueID):
                if let technique = MoriBreathingTechniqueRepository.getTechnique(id: techniqueID) {
                    MoriBreathingTechniqueDetailView(technique: technique)
                } else {
                    MoriBreathingMissingTechniqueView()
                }
            }
        }
        .moriKeyboardDoneToolbar()
        .moriHidesMainTabBar()
        .sheet(item: $techniqueForDurationSelection) { technique in
            MoriBreathingDurationPickerSheet(
                techniqueName: technique.name,
                selectedDuration: $selectedDuration,
                onStart: {
                    techniqueForDurationSelection = nil
                    openBreathingSession(
                        techniqueID: technique.id,
                        durationMinutes: selectedDuration
                    )
                }
            )
            .presentationDetents([.height(560), .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            MoriBitmapIconImage(icon: .focus, size: 16, opacity: 0.58)

            TextField(MoriL10n.display("Search techniques, benefits, or categories"), text: $searchText)
                .font(.system(size: 15, weight: .regular))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    MoriBitmapIconImage(icon: .minus, size: 15, opacity: 0.62)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(MoriColors.botanicalSurface.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.botanicalLine.opacity(0.62), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var moodFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MoriBreathMood.allCases) { mood in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMood = mood
                        }
                    } label: {
                        MoriPill(
                            title: MoriL10n.display(mood.rawValue),
                            icon: mood.icon,
                            isSelected: selectedMood == mood,
                            tint: mood == .sleep ? MoriColors.botanicalMist : MoriColors.botanicalMoss
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func selectDuration(for technique: MoriBreathingTechnique) {
        selectedDuration = 10
        techniqueForDurationSelection = technique
    }

    private func openBreathingSession(techniqueID: String, durationMinutes: Int) {
        openSettleRoute(.breathingSession(
            techniqueID: techniqueID,
            durationMinutes: durationMinutes,
            autoStart: true
        ))
    }
}

private struct MoriBreathingMissingTechniqueView: View {
    var body: some View {
        MoriPaperBackground(variant: .breath) {
            VStack(spacing: 12) {
                MoriBitmapIconBadge(
                    icon: .breathe,
                    size: 58,
                    iconScale: 0.58,
                    fill: MoriColors.sanctuarySurface.opacity(0.76),
                    stroke: Color.white.opacity(0.88),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.16)
                )

                Text(MoriL10n.display("Technique unavailable"))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(MoriL10n.display("This breathing technique could not be loaded."))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .navigationTitle("Breathing")
        .navigationBarTitleDisplayMode(.inline)
    }
}
