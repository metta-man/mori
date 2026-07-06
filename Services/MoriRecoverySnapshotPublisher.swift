import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct MoriRecoverySnapshotPublisher {
    @MainActor
    func publish(_ snapshot: MoriRecoverySnapshot) {
        MoriRecoveryHistoryStore.shared.record(snapshot)

        let updated = MoriWidgetContextSnapshot.load().updatingRecovery(
            score: snapshot.score,
            stateTitle: snapshot.state.compactTitle,
            stateDetail: snapshot.primaryMessage,
            recoverySuggestedPracticeTitle: snapshot.suggestedPractice.title,
            recoverySuggestedPracticeIcon: snapshot.suggestedPractice.icon,
            updatedAt: snapshot.date
        )
        updated.save()
        MoriWatchSettingsSync.shared.sendWidgetContext(updated)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "MoriWidgets")
        WidgetCenter.shared.reloadTimelines(ofKind: "MoriPulseWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "MoriJournalQuickStartWidget")
        #endif
    }
}
