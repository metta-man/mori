import SwiftUI

struct MoriAnalyticsConsentView: View {
    let onChoose: (AnalyticsConsentState) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MoriTheme.Spacing.large) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display("Help improve Mori?"))
                        .font(.system(.title2, design: .serif, weight: .medium))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display("Share anonymous, coarse usage analytics so we can improve reliability. Journal text, photos, Health data, exact dates, and selected app names are never included. Analytics are kept for no more than 90 days."))
                        .font(.body)
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(MoriL10n.display("Share Anonymous Analytics")) {
                        onChoose(.optedIn)
                    }
                    .buttonStyle(MoriPrimaryButtonStyle())

                    Button(MoriL10n.display("Not Now")) {
                        onChoose(.optedOut)
                    }
                    .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget)
                    .foregroundColor(MoriColors.botanicalInk)
                }
                .padding(MoriTheme.Spacing.screenEdge)
            }
            .background(MoriColors.botanicalPaper.ignoresSafeArea())
            .interactiveDismissDisabled()
        }
    }
}
