import SwiftUI

struct BeforeFeedSettingsSection: View {
    @Binding var nativeGateEnabled: Bool
    @Binding var durationSeconds: Int
    @Binding var graceWindowSeconds: Int
    @Binding var breathingTechniqueID: String

    let isScreenTimeAuthorized: Bool
    let feedAppSummary: MoriScreenTimeProfileSummary
    let breathingSummary: String
    let feedAppsStatusText: String
    let onEditFeedApps: () -> Void
    let onShowShortcutGuide: () -> Void

    private var feedAppsReady: Bool {
        feedAppSummary.isEnabled && feedAppSummary.hasEffectiveSelection
    }

    private var isReady: Bool {
        isScreenTimeAuthorized && nativeGateEnabled && feedAppsReady
    }

    private var activationStatusText: String {
        if isReady {
            return "Ready. Open a selected feed app to trigger the reset."
        }
        if !isScreenTimeAuthorized {
            return "Allow Screen Time above before this can work."
        }
        if !feedAppsReady {
            return "Choose the feed apps Mori should slow down."
        }
        return "Turn on feed app protection to activate the shield."
    }

    var body: some View {
        Section {
            BeforeFeedActivationPanel(
                isReady: isReady,
                statusText: activationStatusText,
                isScreenTimeAuthorized: isScreenTimeAuthorized,
                feedAppsReady: feedAppsReady,
                nativeGateEnabled: nativeGateEnabled,
                openWindowText: BeforeFeedGate.formattedDuration(graceWindowSeconds)
            )

            Toggle(isOn: $nativeGateEnabled) {
                screenTimeLabel("Protect feed app launches", icon: .timer)
            }

            Text(MoriL10n.display("Selected feed apps show Mori's iOS Screen Time shield before they open. Category selections are ignored so apps like WhatsApp are not caught accidentally."))
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)

            Picker(MoriL10n.display("Reset length"), selection: $durationSeconds) {
                ForEach(MoriScreenTimeShared.beforeFeedDurationOptions) { option in
                    Text(option.label).tag(option.seconds)
                }
            }

            Picker(MoriL10n.display("Open window"), selection: $graceWindowSeconds) {
                ForEach(MoriScreenTimeShared.beforeFeedGraceWindowOptions) { option in
                    Text(option.label).tag(option.seconds)
                }
            }

            Picker(MoriL10n.display("Breathing"), selection: $breathingTechniqueID) {
                Text(MoriL10n.display("None")).tag(MoriScreenTimeShared.beforeFeedBreathingNoneID)
                ForEach(MoriBreathingTechniqueRepository.techniques) { technique in
                    Text(technique.name).tag(technique.id)
                }
            }

            Text(breathingSummary)
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)

            Button(action: onEditFeedApps) {
                HStack {
                    screenTimeLabel("Feed apps", icon: .timer)
                    Spacer()
                    Text(feedAppsStatusText)
                        .foregroundColor(MoriColors.botanicalMuted)
                }
            }

            Button(action: onShowShortcutGuide) {
                HStack(spacing: 12) {
                    MoriBitmapIconImage(icon: .refresh, size: 18, opacity: 0.84)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(MoriL10n.display("Shortcut automation"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(MoriColors.botanicalInk)
                        Text(MoriL10n.display("Optional fallback. Shortcuts opens this app, but cannot return you to the triggering app."))
                            .font(.footnote)
                            .foregroundColor(MoriColors.botanicalMuted)
                    }

                    Spacer()

                    MoriBitmapIconImage(icon: .chevron, size: 13, opacity: 0.58)
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text(MoriL10n.display("Before Feed"))
        } footer: {
            Text(MoriL10n.display("iOS cannot jump straight from the shield into Mori. Tapping Prepare reset records the request and closes the feed app; open Mori next and the reset appears."))
        }
    }
}

private struct BeforeFeedActivationPanel: View {
    let isReady: Bool
    let statusText: String
    let isScreenTimeAuthorized: Bool
    let feedAppsReady: Bool
    let nativeGateEnabled: Bool
    let openWindowText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                MoriBitmapIconImage(icon: isReady ? .leaf : .lockShield, size: 18, opacity: 0.9)
                    .frame(width: 30, height: 30)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(MoriL10n.display("Activation flow"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display(statusText))
                        .font(.footnote)
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                BeforeFeedReadinessRow(
                    title: "Screen Time allowed",
                    detail: "Required by iOS before Mori can shield another app.",
                    isComplete: isScreenTimeAuthorized
                )
                BeforeFeedReadinessRow(
                    title: "Feed apps selected",
                    detail: "Pick individual apps or websites for this flow.",
                    isComplete: feedAppsReady
                )
                BeforeFeedReadinessRow(
                    title: "Shield handoff clear",
                    detail: MoriL10n.string(
                        "screen_time.before_feed.handoff_detail",
                        defaultValue: "Open feed app -> tap Prepare reset -> finish Mori. Feed apps stay open for %@.",
                        arguments: [openWindowText]
                    ),
                    isComplete: nativeGateEnabled
                )
                BeforeFeedReadinessRow(
                    title: "Window prevents repeats",
                    detail: "Inside the open window, Mori will not launch another Before Feed reset.",
                    isComplete: isReady
                )
            }
        }
        .padding(.vertical, 6)
    }
}

private struct BeforeFeedReadinessRow: View {
    let title: String
    let detail: String
    let isComplete: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MoriBitmapIconImage(
                icon: isComplete ? .leaf : .minus,
                size: 15,
                opacity: isComplete ? 0.9 : 0.45
            )
            .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(MoriL10n.display(detail))
                    .font(.caption)
                    .foregroundColor(MoriColors.botanicalMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct MorningGateSettingsSection: View {
    @Binding var isEnabled: Bool
    @Binding var startDate: Date
    @Binding var durationSeconds: Int
    @Binding var breathingTechniqueID: String

    let breathingSummary: String
    let morningAppsStatusText: String
    let onEditMorningApps: () -> Void

    var body: some View {
        Section {
            Toggle(isOn: $isEnabled) {
                screenTimeLabel("Morning Gate", icon: .leaf)
            }

            DatePicker(
                MoriL10n.display("Start time"),
                selection: $startDate,
                displayedComponents: .hourAndMinute
            )

            Stepper(
                MoriL10n.string(
                    "screen_time.morning.window_duration",
                    defaultValue: "Morning window %@",
                    arguments: [MorningGate.formattedDuration(durationSeconds)]
                ),
                value: $durationSeconds,
                in: (5 * 60)...(2 * 60 * 60),
                step: 5 * 60
            )

            Picker(MoriL10n.display("Breathing"), selection: $breathingTechniqueID) {
                Text(MoriL10n.display("None")).tag(MoriScreenTimeShared.beforeFeedBreathingNoneID)
                ForEach(MoriBreathingTechniqueRepository.techniques) { technique in
                    Text(technique.name).tag(technique.id)
                }
            }

            Text(breathingSummary)
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)

            Button(action: onEditMorningApps) {
                HStack {
                    screenTimeLabel("Morning apps", icon: .timer)
                    Spacer()
                    Text(morningAppsStatusText)
                        .foregroundColor(MoriColors.botanicalMuted)
                }
            }
        } header: {
            Text(MoriL10n.display("Morning Gate"))
        } footer: {
            Text(MoriL10n.display("Starts at your chosen time each day. Completing Morning Reset opens selected apps for that morning window."))
        }
    }
}

private func screenTimeLabel(_ title: String, icon: MoriBitmapIcon) -> some View {
    HStack(spacing: 8) {
        MoriBitmapIconImage(icon: icon, size: 16, opacity: 0.84)

        Text(MoriL10n.display(title))
    }
}
