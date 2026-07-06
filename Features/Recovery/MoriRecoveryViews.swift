import SwiftUI

struct MoriRecoveryInsightOptInCard: View {
    @Binding var isEnabled: Bool

    var body: some View {
        Toggle(isOn: $isEnabled) {
            VStack(alignment: .leading, spacing: 4) {
                Text(MoriL10n.display("Use Recovery in Pulse insight"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(MoriL10n.display("When on, coarse recovery labels are sent to the Pulse proxy. Raw HealthKit samples stay local."))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(.switch)
        .tint(MoriColors.botanicalMoss)
        .moriSanctuaryCard(cornerRadius: 18, padding: 14)
    }
}
