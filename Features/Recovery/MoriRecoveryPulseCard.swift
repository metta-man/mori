import SwiftUI

struct MoriRecoveryPulseCard: View {
    let snapshot: MoriRecoverySnapshot
    let isLoading: Bool
    let errorMessage: String?
    var title: String = MoriL10n.display("Today's Pulse")
    var subtitle: String = MoriL10n.display("Recovery, nervous system, body load, and one next reset.")
    var showsDetailLink: Bool = true
    var showsRefreshButton: Bool = true
    var onOpenDetails: () -> Void = {}
    let onRefresh: () -> Void
    let onStartPractice: (MoriPractice) -> Void
    let onQuickComplete: (MoriPractice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MoriRecoveryPulseCardHeader(
                title: title,
                subtitle: subtitle,
                status: snapshot.status,
                isLoading: isLoading,
                showsRefreshButton: showsRefreshButton,
                onRefresh: onRefresh
            )
            MoriRecoveryScoreSummary(snapshot: snapshot)
            if snapshot.status == .needsPermission {
                MoriRecoveryPulseFooterActions(
                    snapshot: snapshot,
                    showsDetailLink: false,
                    onOpenDetails: onOpenDetails,
                    onRefresh: onRefresh
                )
            }
            MoriRecoveryPulseMessage(primaryMessage: snapshot.primaryMessage, errorMessage: errorMessage)
            if snapshot.status == .ready || snapshot.status == .missingData {
                MoriRecoveryPulseSignalStrip(snapshot: snapshot)
                MoriRecoveryPracticeLink(
                    practice: snapshot.suggestedPractice,
                    label: MoriL10n.string(
                        "recovery.practice.start_duration",
                        defaultValue: "Start %@",
                        arguments: [snapshot.suggestedPractice.durationText]
                    ),
                    onStartPractice: onStartPractice,
                    onQuickComplete: onQuickComplete
                )
            }
            if snapshot.status != .needsPermission {
                MoriRecoveryPulseFooterActions(
                    snapshot: snapshot,
                    showsDetailLink: showsDetailLink,
                    onOpenDetails: onOpenDetails,
                    onRefresh: onRefresh
                )
            }
        }
        .padding(.bottom, snapshot.status == .needsPermission ? 32 : 0)
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }
}
