import SwiftUI

struct ScreenTimeSettingsOverviewSection: View {
    let state: ScreenTimeSettingsOverviewState

    var body: some View {
        Section {
            ScreenTimeSettingsOverviewRow(
                title: "Access",
                value: state.permissionStatus,
                icon: state.permissionIcon
            )
            ScreenTimeSettingsOverviewRow(
                title: "PIN",
                value: state.lockStatus,
                icon: .lockShield
            )
            ScreenTimeSettingsOverviewRow(
                title: "Default Apps",
                value: state.defaultSelectionText,
                icon: .lockShield
            )
            ScreenTimeSettingsOverviewRow(
                title: "Daily Signal",
                value: state.dailySignalText,
                icon: .pulse
            )

            HStack(spacing: 10) {
                MoriBitmapIconImage(icon: .settings, size: 15, opacity: 0.58)
                    .frame(width: 22)

                Text(MoriL10n.display(state.enabledFeaturesText))
                    .font(.footnote)
                    .foregroundColor(MoriColors.botanicalMuted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(minHeight: MoriHitTarget.minimum)
            .accessibilityElement(children: .combine)
        } header: {
            Text(MoriL10n.display("Control Status"))
        }
    }
}

private struct ScreenTimeSettingsOverviewRow: View {
    let title: String
    let value: String
    let icon: MoriBitmapIcon

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            MoriBitmapIconImage(icon: icon, size: 15, opacity: 0.72)
                .frame(width: 22)

            Text(MoriL10n.display(title))
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)

            Spacer(minLength: 12)

            Text(MoriL10n.display(value))
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: MoriHitTarget.minimum, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct ScreenTimeSetupSection: View {
    let state: ScreenTimeSettingsSetupState
    let onRequestAuthorization: () -> Void
    let onSetupPINLock: () -> Void
    let onChangeSelfPIN: () -> Void
    let onGenerateAccountabilityPIN: () -> Void
    let onRemoveLock: () -> Void
    let onEditDefaultList: () -> Void

    var body: some View {
        Section {
            ScreenTimeSetupStatusRow(
                title: state.isAuthorized ? "Screen Time Allowed" : "Screen Time Permission Needed",
                detail: state.permissionDetail,
                icon: state.isAuthorized ? .leaf : .lockShield,
                tint: state.isAuthorized ? MoriColors.botanicalMoss : MoriColors.botanicalClay
            )

            if !state.isAuthorized {
                Button {
                    onRequestAuthorization()
                } label: {
                    screenTimeSettingsLabel("Allow Screen Time", icon: .lockShield)
                }
            }

            ScreenTimeSetupStatusRow(
                title: "App Limits PIN",
                detail: state.lockModeTitle,
                icon: .lockShield,
                tint: MoriColors.botanicalInk
            )

            if state.isLockConfigured {
                Button {
                    onChangeSelfPIN()
                } label: {
                    screenTimeSettingsLabel("Change to Self PIN", icon: .lockShield)
                }

                Button {
                    onGenerateAccountabilityPIN()
                } label: {
                    screenTimeSettingsLabel("Generate Accountability PIN", icon: .lockShield)
                }

                Button(role: .destructive) {
                    onRemoveLock()
                } label: {
                    screenTimeSettingsLabel("Remove PIN Lock", icon: .minus)
                        .foregroundStyle(MoriColors.botanicalClay)
                }
            } else {
                Button {
                    onSetupPINLock()
                } label: {
                    screenTimeSettingsLabel("Lock App Limits", icon: .lockShield)
                }
            }

            Button {
                onEditDefaultList()
            } label: {
                HStack {
                    screenTimeSettingsLabel("Default App List", icon: .timer)
                    Spacer()
                    Text(state.defaultSelectionText)
                        .font(.footnote)
                        .foregroundColor(MoriColors.botanicalMuted)
                }
            }

            if let lastErrorMessage = state.lastErrorMessage {
                Text(MoriL10n.display(lastErrorMessage))
                    .font(.footnote)
                    .foregroundColor(MoriColors.botanicalClay)
            }
        } header: {
            Text(MoriL10n.display("Setup"))
        } footer: {
            Text(MoriL10n.display("Configure permission, the PIN gate, and the default app list once. Reset App Limits below can reuse this base setup."))
        }
    }
}

private struct ScreenTimeSetupStatusRow: View {
    let title: String
    let detail: String
    let icon: MoriBitmapIcon
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            MoriBitmapIconImage(icon: icon, size: 17, opacity: 0.82)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 15, weight: .semibold))
                Text(MoriL10n.display(detail))
                    .font(.footnote)
                    .foregroundColor(MoriColors.botanicalMuted)
            }
        }
    }
}

private func screenTimeSettingsLabel(_ title: String, icon: MoriBitmapIcon) -> some View {
    HStack(spacing: 8) {
        MoriBitmapIconImage(icon: icon, size: 16, opacity: 0.84)

        Text(MoriL10n.display(title))
    }
}

struct ScreenTimeFeatureSettingsSection: View {
    let summaries: [MoriScreenTimeProfileSummary]
    let onEnabledChange: (Bool, MoriScreenTimeFeature) -> Void
    let onUsesDefaultSelectionChange: (Bool, MoriScreenTimeFeature) -> Void
    let onEditDefaultList: () -> Void
    let onEditCustomList: (MoriScreenTimeFeature) -> Void

    var body: some View {
        Section {
            ForEach(summaries) { summary in
                ScreenTimeFeatureSettingsRow(
                    summary: summary,
                    onEnabledChange: { isEnabled in
                        onEnabledChange(isEnabled, summary.feature)
                    },
                    onUsesDefaultSelectionChange: { usesDefaultSelection in
                        onUsesDefaultSelectionChange(usesDefaultSelection, summary.feature)
                    },
                    onEditDefaultList: onEditDefaultList,
                    onEditCustomList: {
                        onEditCustomList(summary.feature)
                    }
                )
            }
        } header: {
            Text(MoriL10n.display("Reset App Limits"))
        }
    }
}

struct ScreenTimeDailySignalSection: View {
    let state: ScreenTimeSettingsDailySignalState
    let onThresholdMinutesChange: (Int) -> Void

    var body: some View {
        Section {
            Stepper(
                MoriL10n.string(
                    "screen_time.daily_signal_minutes",
                    defaultValue: "Daily selected-app signal %dm",
                    arguments: [state.thresholdMinutes]
                ),
                value: thresholdBinding,
                in: 5...240,
                step: 5
            )
        } header: {
            Text(MoriL10n.display("Daily Signal"))
        } footer: {
            Text(MoriL10n.display("This remains a usage signal for the default app list. It does not create an all-day hard App Limit."))
        }
    }

    private var thresholdBinding: Binding<Int> {
        Binding(
            get: { state.thresholdMinutes },
            set: onThresholdMinutesChange
        )
    }
}
