import SwiftUI

enum ScreenTimeSettingsLockManagementSheet: Identifiable {
    case changeSelfPIN
    case accountabilityPIN
    case removeLock

    var id: String {
        switch self {
        case .changeSelfPIN: return "change-self-pin"
        case .accountabilityPIN: return "accountability-pin"
        case .removeLock: return "remove-lock"
        }
    }
}

struct ScreenTimeSettingsLockManagementView: View {
    @Environment(\.dismiss) private var dismiss

    let mode: ScreenTimeSettingsLockManagementSheet

    @StateObject private var lockStore = ScreenTimeSettingsLockStore.shared
    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?
    @State private var sharePayload: ScreenTimeSettingsPINSharePayload?

    private var title: String {
        switch mode {
        case .changeSelfPIN: return MoriL10n.display("Change PIN")
        case .accountabilityPIN: return MoriL10n.display("Accountability PIN")
        case .removeLock: return MoriL10n.display("Remove Lock")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField(MoriL10n.display("Current PIN"), text: $currentPIN)
                        .screenTimePINInput($currentPIN)
                }

                switch mode {
                case .changeSelfPIN:
                    selfPINFields
                case .accountabilityPIN:
                    accountabilityFields
                case .removeLock:
                    removeFields
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MoriL10n.display("Cancel")) {
                        dismiss()
                    }
                }
            }
            .sheet(item: $sharePayload, onDismiss: { dismiss() }) { payload in
                ScreenTimeSettingsPINShareSheet(activityItems: [payload.message])
            }
        }
    }

    private var selfPINFields: some View {
        Section {
            SecureField(MoriL10n.display("New 6-digit PIN"), text: $newPIN)
                .screenTimePINInput($newPIN)

            SecureField(MoriL10n.display("Confirm new PIN"), text: $confirmation)
                .screenTimePINInput($confirmation)

            Button {
                changeSelfPIN()
            } label: {
                screenTimeLockManagementLabel("Save Self PIN", icon: .lockShield)
            }
            .disabled(currentPIN.count != ScreenTimeSettingsLockStore.pinLength ||
                      newPIN.count != ScreenTimeSettingsLockStore.pinLength ||
                      confirmation.count != ScreenTimeSettingsLockStore.pinLength)
        } header: {
            Text(MoriL10n.display("New PIN"))
        }
    }

    private var accountabilityFields: some View {
        Section {
            Text(MoriL10n.display("A new PIN will open in the iOS share sheet. Send it to 1-3 trusted friends."))
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)

            Button {
                changeToAccountabilityPIN()
            } label: {
                screenTimeLockManagementLabel("Generate and Share New PIN", icon: .lockShield)
            }
            .disabled(currentPIN.count != ScreenTimeSettingsLockStore.pinLength)
        } header: {
            Text(MoriL10n.display("Accountability PIN"))
        }
    }

    private var removeFields: some View {
        Section {
            Text(MoriL10n.display("This removes the App Limits PIN gate. Anyone using this device can edit Screen Time settings afterward."))
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)

            Button(role: .destructive) {
                removeLock()
            } label: {
                screenTimeLockManagementLabel("Remove PIN Lock", icon: .minus)
                    .foregroundStyle(MoriColors.botanicalClay)
            }
            .disabled(currentPIN.count != ScreenTimeSettingsLockStore.pinLength)
        }
    }

    private func changeSelfPIN() {
        do {
            try lockStore.changeSelfPIN(currentPIN: currentPIN, newPIN: newPIN, confirmation: confirmation)
            errorMessage = nil
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func changeToAccountabilityPIN() {
        do {
            let generatedPIN = try lockStore.changeToAccountabilityPIN(currentPIN: currentPIN)
            errorMessage = nil
            sharePayload = ScreenTimeSettingsPINSharePayload(pin: generatedPIN)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeLock() {
        do {
            try lockStore.clearAfterVerification(currentPIN: currentPIN)
            errorMessage = nil
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

}

private func screenTimeLockManagementLabel(_ title: String, icon: MoriBitmapIcon) -> some View {
    HStack(spacing: 8) {
        MoriBitmapIconImage(icon: icon, size: 16, opacity: 0.84)

        Text(MoriL10n.display(title))
    }
}
