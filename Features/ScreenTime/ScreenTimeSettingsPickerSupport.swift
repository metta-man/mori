import SwiftUI
import FamilyControls

struct ScreenTimeSettingsPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    @Binding var selection: FamilyActivitySelection
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            FamilyActivityPicker(selection: $selection)
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
                    }
                }
        }
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
