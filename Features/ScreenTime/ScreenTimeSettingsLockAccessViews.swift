import SwiftUI
import UIKit

struct ScreenTimeSettingsPINSetupView: View {
    let onUnlocked: () -> Void

    @StateObject private var lockStore = ScreenTimeSettingsLockStore.shared
    @State private var selectedMode: ScreenTimeSettingsLockMode = .selfPIN
    @State private var pin = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?
    @State private var sharePayload: ScreenTimeSettingsPINSharePayload?

    var body: some View {
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
                        createAccountabilityPIN()
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
        .sheet(item: $sharePayload, onDismiss: onUnlocked) { payload in
            ScreenTimeSettingsPINShareSheet(activityItems: [payload.message])
        }
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

    private func createAccountabilityPIN() {
        do {
            let generatedPIN = try lockStore.createAccountabilityPIN()
            errorMessage = nil
            sharePayload = ScreenTimeSettingsPINSharePayload(pin: generatedPIN)
        } catch {
            errorMessage = error.localizedDescription
        }
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
                    MoriBitmapIconImage(icon: .lockShield, size: 21, opacity: 0.86)
                        .frame(width: 38, height: 38)
                        .background(MoriColors.botanicalInk.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(MoriL10n.display("App Limits are locked"))
                            .font(.system(size: 15, weight: .semibold))
                        Text(MoriL10n.display(lockStore.mode?.detail ?? "Enter the PIN to edit Screen Time settings."))
                            .font(.footnote)
                            .foregroundColor(MoriColors.botanicalMuted)
                    }
                }
            }

            Section {
                SecureField(MoriL10n.display("6-digit PIN"), text: $pin)
                    .screenTimePINInput($pin)

                Button {
                    unlock()
                } label: {
                    screenTimeLockLabel("Unlock App Limits", icon: .lockShield)
                }
                .disabled(pin.count != ScreenTimeSettingsLockStore.pinLength || cooldownRemaining > 0)
            } footer: {
                if cooldownRemaining > 0 {
                    Text(MoriL10n.string("screen_time.lock.retry_seconds", defaultValue: "Try again in %ds.", arguments: [cooldownRemaining]))
                } else {
                    Text(MoriL10n.display("There is no in-app forgotten-PIN reset in this version."))
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

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
