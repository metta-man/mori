import SwiftUI

struct MoriAppSheetContent: View {
    let sheet: MoriAppSheet
    let routeSource: MoriAppRouteSource?
    let selectionTitle: String
    let selectionSubtitle: String
    let beforeFeedDurationSeconds: Int
    let morningGateDurationSeconds: Int
    var onStartPractice: (MoriPractice) -> Void = { _ in }
    var onCompletePractice: (MoriPractice) -> Void = { _ in }
    var pulseShowsDismissButton = false

    var body: some View {
        switch sheet {
        case .practice(let practiceSheet):
            MoriPracticeSheetContent(
                sheet: practiceSheet,
                routeSource: routeSource,
                selectionTitle: selectionTitle,
                selectionSubtitle: selectionSubtitle,
                beforeFeedDurationSeconds: beforeFeedDurationSeconds,
                morningGateDurationSeconds: morningGateDurationSeconds,
                onStartPractice: onStartPractice,
                onCompletePractice: onCompletePractice,
                pulseShowsDismissButton: pulseShowsDismissButton
            )
        case .settings:
            SettingsView()
                .moriKeyboardDoneToolbar()
        case .appLimits:
            NavigationStack {
                LockedScreenTimeSettingsView()
            }
            .moriKeyboardDoneToolbar()
        case .appLimitSetup:
            NavigationStack {
                FirstAppLimitSetupView(routeSource: routeSource)
            }
            .moriKeyboardDoneToolbar()
        }
    }
}

extension View {
    func moriAppSheet(
        item: Binding<MoriAppSheet?>,
        routeSource: MoriAppRouteSource?,
        selectionTitle: String,
        selectionSubtitle: String,
        beforeFeedDurationSeconds: Int,
        morningGateDurationSeconds: Int = MoriScreenTimeShared.defaultMorningGateDurationSeconds,
        onStartPractice: @escaping (MoriPractice) -> Void = { _ in },
        onCompletePractice: @escaping (MoriPractice) -> Void = { _ in },
        pulseShowsDismissButton: Bool = false
    ) -> some View {
        sheet(item: item) { sheet in
            MoriAppSheetContent(
                sheet: sheet,
                routeSource: routeSource,
                selectionTitle: selectionTitle,
                selectionSubtitle: selectionSubtitle,
                beforeFeedDurationSeconds: beforeFeedDurationSeconds,
                morningGateDurationSeconds: morningGateDurationSeconds,
                onStartPractice: onStartPractice,
                onCompletePractice: onCompletePractice,
                pulseShowsDismissButton: pulseShowsDismissButton
            )
        }
    }
}
