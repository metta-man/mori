import SwiftUI
import UIKit

struct ScreenTimeSettingsPINSetupView: View {
    let onUnlocked: () -> Void

    @StateObject private var lockStore = ScreenTimeSettingsLockStore.shared
    @State private var selectedMode: ScreenTimeSettingsLockMode = .selfPIN
    @State private var pin = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?
    @State private var accountabilityDraft: ScreenTimeSettingsAccountabilityPINDraft?

    @ViewBuilder
    var body: some View {
        if let accountabilityDraft {
            ScreenTimeSettingsAccountabilityPINConfirmationView(
                draft: accountabilityDraft,
                commitIntent: .initialSetup,
                onCancel: { self.accountabilityDraft = nil },
                onCommitted: onUnlocked
            )
        } else {
            setupForm
        }
    }

    private var setupForm: some View {
        Form {
            Section {
                Picker(MoriL10n.display("Lock mode"), selection: $selectedMode) {
                    ForEach(ScreenTimeSettingsLockMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(MoriL10n.display(selectedMode.detail))
                    .font(.footnote)
                    .foregroundColor(MoriColors.botanicalMuted)
            } header: {
                Text(MoriL10n.display("Lock App Limits"))
            } footer: {
                Text(MoriL10n.display("This PIN is required before anyone can open Screen Time & App Limits."))
            }

            if selectedMode == .selfPIN {
                Section {
                    SecureField(MoriL10n.display("6-digit PIN"), text: $pin)
                        .screenTimePINInput($pin)

                    SecureField(MoriL10n.display("Confirm PIN"), text: $confirmation)
                        .screenTimePINInput($confirmation)

                    Button {
                        createSelfPIN()
                    } label: {
                        screenTimeLockLabel("Save PIN", icon: .lockShield)
                    }
                    .disabled(pin.count != ScreenTimeSettingsLockStore.pinLength || confirmation.count != ScreenTimeSettingsLockStore.pinLength)
                } header: {
                    Text(MoriL10n.display("Self PIN"))
                }
            } else {
                Section {
                    Text(MoriL10n.display("A 6-digit PIN will open in the iOS share sheet. Send it to 1-3 trusted friends and do not save it for yourself."))
                        .font(.footnote)
                        .foregroundColor(MoriColors.botanicalMuted)

                    Button {
                        prepareAccountabilityPIN()
                    } label: {
                        screenTimeLockLabel("Generate and Share PIN", icon: .lockShield)
                    }
                } header: {
                    Text(MoriL10n.display("Accountability PIN"))
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(MoriColors.botanicalClay)
                }
            }
        }
        .moriSettingsForm()
        .navigationTitle(MoriL10n.display("App Limits Lock"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private func createSelfPIN() {
        do {
            try lockStore.createSelfPIN(pin, confirmation: confirmation)
            errorMessage = nil
            onUnlocked()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func prepareAccountabilityPIN() {
        errorMessage = nil
        accountabilityDraft = lockStore.makeAccountabilityPINDraft()
    }
}

struct ScreenTimeSettingsUnlockView: View {
    let onUnlocked: () -> Void

    @StateObject private var lockStore = ScreenTimeSettingsLockStore.shared
    @State private var pin = ""
    @State private var errorMessage: String?
    @State private var cooldownRemaining = 0

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    MoriBitmapIconImage(icon: .lockShield, size: 17, opacity: 0.74)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(MoriL10n.display("App Limits are locked"))
                            .font(.system(size: 15, weight: .semibold))
                        Text(MoriL10n.display(lockStore.mode?.detail ?? "Enter the PIN to edit Screen Time settings."))
                            .font(.footnote)
                            .foregroundColor(MoriColors.botanicalMuted)
                    }
                }

                SecureField(MoriL10n.display("6-digit PIN"), text: $pin)
                    .screenTimePINInput($pin)

                Button {
                    unlock()
                } label: {
                    screenTimeLockLabel("Unlock App Limits", icon: .lockShield)
                }
                .disabled(pin.count != ScreenTimeSettingsLockStore.pinLength || cooldownRemaining > 0)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(MoriColors.botanicalClay)
                }
            } footer: {
                if cooldownRemaining > 0 {
                    Text(MoriL10n.string("screen_time.lock.retry_seconds", defaultValue: "Try again in %ds.", arguments: [cooldownRemaining]))
                } else {
                    Text(MoriL10n.display("There is no in-app forgotten-PIN reset in this version."))
                }
            }
        }
        .moriSettingsForm()
        .navigationTitle(MoriL10n.display("Unlock App Limits"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .screenTimeSettingsUnlockLifecycle(onRefreshCooldown: refreshCooldown)
    }

    private func unlock() {
        do {
            if try lockStore.verify(pin) {
                errorMessage = nil
                onUnlocked()
            }
        } catch {
            errorMessage = error.localizedDescription
            cooldownRemaining = lockStore.cooldownRemainingSeconds()
        }
    }

    private func refreshCooldown() {
        cooldownRemaining = lockStore.cooldownRemainingSeconds()
    }
}

private func screenTimeLockLabel(_ title: String, icon: MoriBitmapIcon) -> some View {
    HStack(spacing: 8) {
        MoriBitmapIconImage(icon: icon, size: 16, opacity: 0.84)

        Text(MoriL10n.display(title))
    }
}

struct ScreenTimeSettingsAccountabilityPINConfirmationView: View {
    let draft: ScreenTimeSettingsAccountabilityPINDraft
    let commitIntent: ScreenTimeSettingsAccountabilityPINCommitIntent
    let onCancel: () -> Void
    let onCommitted: () -> Void

    @StateObject private var lockStore = ScreenTimeSettingsLockStore.shared
    @State private var sharePayload: ScreenTimeSettingsPINSharePayload?
    @State private var didCompleteShare = false
    @State private var friendReceivedPIN = false
    @State private var errorMessage: String?

    private var canConfirm: Bool {
        didCompleteShare && friendReceivedPIN
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    MoriBitmapIconImage(icon: .lockShield, size: 19, opacity: 0.78)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(MoriL10n.display("PIN ready to share"))
                            .font(.system(size: 16, weight: .semibold))

                        Text(MoriL10n.display("Mori keeps the PIN private and sends it only through the iOS share sheet."))
                            .font(.footnote)
                            .foregroundColor(MoriColors.botanicalMuted)
                    }
                }
            } header: {
                Text(MoriL10n.display("Accountability PIN"))
            }

            Section {
                if didCompleteShare {
                    MoriSecondaryButton(title: "Share PIN again") {
                        beginShare()
                    }
                    .accessibilityIdentifier("screen_time_accountability_pin_share")
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                } else {
                    MoriPrimaryButton(
                        title: "Share PIN",
                        style: .v2Compatibility,
                        action: beginShare
                    )
                    .accessibilityIdentifier("screen_time_accountability_pin_share")
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                if didCompleteShare {
                    HStack(spacing: 10) {
                        MoriBitmapIconImage(icon: .leaf, size: 16, opacity: 0.78)
                            .frame(width: 24, height: 24)

                        Text(MoriL10n.display("Share completed"))
                            .font(.footnote.weight(.medium))
                            .foregroundColor(MoriColors.botanicalMuted)
                    }
                    .accessibilityElement(children: .combine)
                }
            } footer: {
                Text(MoriL10n.display("Send the PIN to 1-3 trusted friends. Cancelling the share sheet will not turn on the lock."))
            }

            if didCompleteShare {
                Section {
                    Toggle(isOn: $friendReceivedPIN) {
                        Text(MoriL10n.display("I confirm a trusted friend received and saved the PIN."))
                    }
                    .accessibilityIdentifier("screen_time_accountability_pin_received_acknowledgement")
                } header: {
                    Text(MoriL10n.display("Confirm receipt"))
                }

                Section {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(MoriColors.botanicalClay)
                    }

                    MoriPrimaryButton(
                        title: "Confirm & Lock",
                        icon: .lockShield,
                        isEnabled: canConfirm,
                        style: .v2Compatibility,
                        action: commit
                    )
                    .accessibilityIdentifier("screen_time_accountability_pin_confirm_lock")
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                } footer: {
                    Text(MoriL10n.display("The PIN is saved only after you complete both confirmations."))
                }
            }
        }
        .moriSettingsForm()
        .navigationTitle(MoriL10n.display("Confirm PIN"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(MoriL10n.display("Cancel"), action: onCancel)
                    .accessibilityIdentifier("screen_time_accountability_pin_cancel")
            }
        }
        .sheet(item: $sharePayload) { payload in
            ScreenTimeSettingsPINShareSheet(
                activityItems: [payload.message],
                onCompletion: handleShareCompletion
            )
        }
        .accessibilityIdentifier("screen_time_accountability_pin_confirmation")
    }

    private func handleShareCompletion(_ completed: Bool) {
        sharePayload = nil
        guard completed else { return }
        didCompleteShare = true
    }

    private func beginShare() {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-MoriCompletePINShareForUITest") {
            handleShareCompletion(true)
            return
        }
#endif
        sharePayload = ScreenTimeSettingsPINSharePayload(pin: draft.pin)
    }

    private func commit() {
        do {
            try lockStore.commitAccountabilityPIN(draft, intent: commitIntent)
            errorMessage = nil
            onCommitted()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ScreenTimeSettingsPINSharePayload: Identifiable {
    let id = UUID()
    let pin: String

    var message: String {
        """
        \(MoriL10n.string("screen_time.lock.share.title", defaultValue: "App Limits accountability PIN: %@", arguments: [pin]))

        \(MoriL10n.display("Please keep this PIN for me. If I need to edit my Screen Time settings, I may ask you for it."))
        """
    }
}

struct ScreenTimeSettingsPINShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let onCompletion: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, completed, _, _ in
            DispatchQueue.main.async {
                onCompletion(completed)
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
