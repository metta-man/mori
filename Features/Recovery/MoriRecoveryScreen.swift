import SwiftUI

struct MoriRecoveryScreen: View {
    @Environment(\.moriOpenRoute) private var openRoute
    @StateObject private var store = MoriRecoveryStore.shared

    var body: some View {
        Group {
            switch store.snapshot.status {
            case .needsPermission:
                stateScreen {
                    MoriPermissionState(
                        icon: .heart,
                        title: MoriL10n.display("Connect Apple Health"),
                        message: MoriL10n.display("Recovery is calculated on this iPhone from only the Health data you choose."),
                        buttonTitle: MoriL10n.display("Choose Health Data")
                    ) {
                        Task { await store.requestAuthorizationAndRefresh() }
                    }
                }
            case .healthUnavailable:
                stateScreen {
                    MoriEmptyState(
                        icon: .heart,
                        title: MoriL10n.display("Recovery unavailable"),
                        message: MoriL10n.display("Apple Health data is not available on this device.")
                    )
                }
            case .missingData, .ready:
                MoriRecoveryDetailView(
                    snapshot: store.snapshot,
                    onStartPractice: startPractice,
                    onQuickComplete: completePractice
                )
            }
        }
        .task { await store.refresh() }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private func stateScreen<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        MoriPaperBackground(variant: .today) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MoriTheme.Spacing.large) {
                    MoriRootHeader(
                        title: "Recovery",
                        subtitle: "A private, baseline-based wellness signal. Not medical advice."
                    )
                    content()
                        .moriSanctuaryCard()
                }
                .padding(.horizontal, MoriTheme.Spacing.screenEdge)
                .padding(.top, MoriTheme.Spacing.medium)
                .padding(.bottom, 72)
            }
        }
    }

    private func startPractice(_ practice: MoriPractice) {
        openRoute(.practiceSheet(MoriPracticeSheet.destination(for: practice)))
    }

    private func completePractice(_ practice: MoriPractice) {
        openRoute(.practiceSheet(.verification(practice)))
    }
}
