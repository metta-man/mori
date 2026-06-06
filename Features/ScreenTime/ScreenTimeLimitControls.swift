import SwiftUI
import FamilyControls

struct ScreenTimeLimitControls: View {
    let contextTitle: String

    @StateObject private var shieldManager = FocusShieldManager.shared
    @State private var isShowingPicker = false
    @State private var selection = FamilyActivitySelection()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: shieldManager.isAuthorized ? "lock.shield" : "lock.shield.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MoriColors.forestMoss)
                    .frame(width: 36, height: 36)
                    .background(MoriColors.forestMoss.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Blocked Apps")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)

                    Text(statusText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if !shieldManager.isAuthorized {
                Button {
                    Task { await shieldManager.requestAuthorization() }
                } label: {
                    Label("Allow Screen Time", systemImage: "faceid")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(MoriColors.forestCanopy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    selection = shieldManager.currentSelection()
                    isShowingPicker = true
                } label: {
                    Label(
                        shieldManager.hasSelection ? "Edit Blocked Apps" : "Choose Apps",
                        systemImage: shieldManager.hasSelection ? "pencil.circle" : "plus.circle"
                    )
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.forestCard)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(MoriColors.forestCanopy)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Stepper(
                    "Daily limit \(shieldManager.dailyThresholdMinutes)m",
                    value: $shieldManager.dailyThresholdMinutes,
                    in: 5...240,
                    step: 5
                )
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MoriColors.forestCanopy)
            }

            if let message = shieldManager.lastErrorMessage {
                Text(message)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.forestClay)
            }
        }
        .padding(14)
        .background(MoriColors.forestPaperDeep.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task {
            shieldManager.restoreActiveShieldIfNeeded()
        }
        .sheet(isPresented: $isShowingPicker) {
            NavigationStack {
                FamilyActivityPicker(selection: $selection)
                    .navigationTitle("Blocked Apps")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isShowingPicker = false
                            }
                        }

                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                shieldManager.saveSelection(selection)
                                isShowingPicker = false
                            }
                        }
                    }
            }
        }
    }

    private var statusText: String {
        guard shieldManager.isAuthorized else {
            return "\(contextTitle) can limit selected apps after Screen Time permission is granted."
        }

        guard shieldManager.hasSelection else {
            return "Choose apps or categories to protect this timer. Mori only sees private tokens and counts."
        }

        return "\(shieldManager.selectedCount) selected. Names stay private; limits apply during protected focus."
    }
}
