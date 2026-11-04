import SwiftUI

struct MoriLegacyTrialRecoveryView: View {
    @State private var outcome: MoriLegacyTrialRecovery.Outcome?

    var body: some View {
        Form {
            Section {
                Text(MoriL10n.display("Remove restrictions left by a previous Mori test. Your regular app limits, saved data and Screen Time permission stay as they are."))
                    .fixedSize(horizontal: false, vertical: true)
                Button(MoriL10n.display("Remove previous test restrictions")) {
                    outcome = MoriLegacyTrialRecoveryNative.recover()
                }
                .frame(minHeight: MoriHitTarget.minimum)
                .accessibilityIdentifier("legacy-trial-recover")
            }
            if let outcome {
                Section {
                    Text(MoriL10n.display(message(for: outcome)))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("legacy-trial-recovery-status")
                }
            }
        }
        .moriSettingsForm()
        .navigationTitle(MoriL10n.display("Previous test restrictions"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func message(for outcome: MoriLegacyTrialRecovery.Outcome) -> String {
        switch outcome {
        case .acknowledged:
            return "Known test restrictions were cleared. Try the app again. Other app limits may still apply."
        case .noKnownOwnership:
            return "No recoverable test restrictions were found. If an app is still blocked, its restriction has not been confirmed cleared."
        case .pending:
            return "Recovery is still pending. You can retry. Keep your saved data and Screen Time permission in place; contact support if the app remains blocked."
        }
    }
}
