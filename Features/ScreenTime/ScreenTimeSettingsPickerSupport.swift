import SwiftUI
import FamilyControls

struct ScreenTimeSettingsPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    @Binding var selection: FamilyActivitySelection
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                selectionContext

                Divider()
                    .overlay(MoriColors.sanctuaryHairline)

                FamilyActivityPicker(selection: $selection)
                    .background(MoriColors.sanctuaryPaper)
            }
            .background(MoriColors.sanctuaryPaper.ignoresSafeArea())
            .navigationTitle(MoriL10n.display(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MoriL10n.display("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(MoriL10n.display("Done")) {
                        onDone()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(MoriColors.sanctuaryPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .tint(MoriColors.botanicalInk)
    }

    private var selectionContext: some View {
        HStack(alignment: .top, spacing: 11) {
            MoriBitmapIconImage(icon: .appLimit, size: 17, opacity: 0.88)
                .frame(width: 34, height: 34)
                .background(MoriColors.botanicalInk.opacity(0.08))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display("Your selection"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(MoriL10n.display(selectionDetail))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(MoriColors.sanctuaryPaper)
        .accessibilityElement(children: .combine)
    }

    private var selectionDetail: String {
        switch selectionCount {
        case 0:
            return "Choose apps, categories, or websites. You can change this later."
        case 1:
            return "1 selection"
        default:
            return "\(selectionCount) selections"
        }
    }

    private var selectionCount: Int {
        selection.applicationTokens.count +
        selection.categoryTokens.count +
        selection.webDomainTokens.count
    }
}

extension AttentionShieldSelectionTarget {
    var settingsTitle: String {
        switch self {
        case .defaultList:
            return MoriL10n.string("Default Apps", defaultValue: "Default Apps")
        case .feature(let feature):
            return feature.title
        }
    }

    var inlineTitle: String {
        switch self {
        case .defaultList:
            return settingsTitle
        case .feature(let feature):
            return MoriL10n.string(
                "screen_time.picker.feature_apps",
                defaultValue: "%@ Apps",
                arguments: [feature.title]
            )
        }
    }
}

enum ScreenTimeSettingsBreathingSummary {
    static func text(
        techniqueID: String,
        defaultTechniqueID: String
    ) -> String {
        guard techniqueID != MoriScreenTimeShared.beforeFeedBreathingNoneID else {
            return MoriL10n.string("screen_time.breathing_summary.plain_timer", defaultValue: "Plain timer with no breathing cues.")
        }

        let technique = MoriBreathingTechniqueRepository.getTechnique(id: techniqueID)
            ?? MoriBreathingTechniqueRepository.getTechnique(id: defaultTechniqueID)

        guard let technique else {
            return MoriL10n.string("screen_time.breathing_summary.guided_on", defaultValue: "Guided breathing is on.")
        }

        return "\(technique.patternDisplay) · \(technique.shortDescription)"
    }
}
