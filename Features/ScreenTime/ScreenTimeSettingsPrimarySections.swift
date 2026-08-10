import SwiftUI

struct AppLimitsSectionHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(MoriL10n.display(title))
                .font(.system(size: 19, weight: .medium, design: .serif))
                .foregroundColor(MoriColors.botanicalInk)

            Text(MoriL10n.display(subtitle))
                .font(MoriTypography.caption)
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct AppLimitsReadinessCard: View {
    let isAuthorized: Bool
    let beforeFeedSummary: MoriScreenTimeProfileSummary
    let nativeGateEnabled: Bool
    let primaryActionTitle: String?
    let onPrimaryAction: () -> Void

    private var isReady: Bool {
        isAuthorized && beforeFeedSummary.isEnabled && beforeFeedSummary.hasEffectiveSelection && nativeGateEnabled
    }

    private var title: String {
        if isReady { return "Your pause is ready" }
        if !isAuthorized { return "Start with one permission" }
        if !beforeFeedSummary.hasEffectiveSelection { return "Choose what deserves a pause" }
        return "One step from ready"
    }

    private var detail: String {
        if isReady {
            return "Selected feeds will meet Mori before they open."
        }
        if !isAuthorized {
            return "Screen Time lets Mori protect selected apps without reading what you do inside them."
        }
        if !beforeFeedSummary.hasEffectiveSelection {
            return "Pick one feed, video, news, or shopping app to begin."
        }
        return "Turn on Before Feed to apply the pause to your selected apps."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 13) {
                MoriProductSymbolView(
                    symbol: isReady ? .focusPoint : .appLimit,
                    size: 23,
                    tint: MoriColors.botanicalInk,
                    opacity: 0.95
                )
                .frame(width: 44, height: 44)
                .background(MoriColors.botanicalInk.opacity(0.09))
                .clipShape(Circle())
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(MoriL10n.display(title))
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display(detail))
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let primaryActionTitle {
                Button(action: onPrimaryAction) {
                    Text(primaryActionTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(MoriPrimaryButtonStyle())
                .frame(minHeight: 50)
            } else {
                HStack(spacing: 8) {
                    MoriBitmapIconImage(icon: .leaf, size: 15, opacity: 0.88)
                        .accessibilityHidden(true)
                    Text(MoriL10n.display("Before Feed is active"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)
                    Spacer()
                    Text(MoriL10n.display(beforeFeedSummary.statusText))
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.botanicalMuted)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 46)
                .background(MoriColors.botanicalMoss.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
        .moriSanctuaryBox(cornerRadius: 22, padding: 16, tone: .paper, castsShadow: true)
    }
}

struct AppLimitsProtectedAppsCard: View {
    let summary: MoriScreenTimeProfileSummary
    let onEdit: () -> Void

    private var detail: String {
        summary.hasEffectiveSelection
            ? summary.statusText
            : MoriL10n.display("No apps selected yet")
    }

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 13) {
                MoriBitmapIconImage(icon: .lockShield, size: 18, opacity: 0.86)
                    .frame(width: 36, height: 36)
                    .background(MoriColors.botanicalInk.opacity(0.07))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(MoriL10n.display("Protected Apps"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display(detail))
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.botanicalMuted)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Text(MoriL10n.display(summary.hasEffectiveSelection ? "Edit" : "Choose"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
            }
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(MoriColors.botanicalSurface.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MoriColors.botanicalLine.opacity(0.45), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

struct AppLimitsModeRow: View {
    let title: String
    let subtitle: String
    let status: String
    let icon: MoriBitmapIcon
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            MoriBitmapIconImage(icon: icon, size: 17, opacity: 0.82)
                .frame(width: 34, height: 34)
                .background(MoriColors.botanicalInk.opacity(0.065))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(MoriL10n.display(subtitle))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Text(status)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isActive ? MoriColors.botanicalMoss : MoriColors.botanicalMuted)

            MoriBitmapIconImage(icon: .chevron, size: 12, opacity: 0.46)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct AppLimitsRowDivider: View {
    var body: some View {
        Divider()
            .overlay(MoriColors.botanicalLine.opacity(0.54))
            .padding(.leading, 60)
    }
}

struct AppLimitsPINOfferCard: View {
    let onProtect: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 11) {
                MoriBitmapIconImage(icon: .lockShield, size: 17, opacity: 0.84)
                    .frame(width: 34, height: 34)
                    .background(MoriColors.botanicalInk.opacity(0.07))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(MoriL10n.display("Prevent quick changes?"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display("Add a PIN after setup so App Limits are harder to change in the moment."))
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button(MoriL10n.display("Not Now"), action: onNotNow)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .frame(maxWidth: .infinity, minHeight: 44)

                Button(MoriL10n.display("Prevent Changes"), action: onProtect)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalSurface)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(MoriColors.botanicalInk)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
        }
        .moriSanctuaryBox(cornerRadius: 20, padding: 16, tone: .sage, castsShadow: false)
    }
}

struct AppLimitsAdvancedLink: View {
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            MoriBitmapIconImage(icon: .settings, size: 17, opacity: 0.76)
                .frame(width: 34, height: 34)
                .background(MoriColors.botanicalInk.opacity(0.06))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display("Advanced"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(detail)
                    .font(MoriTypography.caption)
                    .foregroundColor(MoriColors.botanicalMuted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            MoriBitmapIconImage(icon: .chevron, size: 12, opacity: 0.48)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(MoriColors.botanicalSurface.opacity(0.66))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MoriColors.botanicalLine.opacity(0.4), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

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
