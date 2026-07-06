import SwiftUI
import UIKit
import UserNotifications

struct MindfulnessBellSettleCard: View {
    let isActive: Bool
    let nextFireTimestamp: Double
    let authorizationDenied: Bool
    let onEnableRecommended: () -> Void

    @Environment(\.moriOpenSettleRoute) private var openSettleRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                MoriBitmapIconBadge(icon: .bell, size: 40)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Mindfulness Bell")
                        .font(MoriTypography.sanctuarySection)
                        .foregroundColor(MoriColors.sanctuaryInk)

                    Text(MoriL10n.display(isActive ? "A soft reminder is carrying Settle into the day." : "Let a soft bell ring through the day so one breath can interrupt autopilot."))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if isActive {
                MindfulnessBellStatusRow(
                    text: MindfulnessBellStatusFormatter.nextBellText(
                        isActive: isActive,
                        nextFireTimestamp: nextFireTimestamp
                    )
                )

                Button(action: openSettings) {
                    HStack(spacing: 8) {
                        MoriBitmapIconImage(icon: .settings, size: 15, opacity: 0.84)

                        Text(MoriL10n.display("Customize bell"))
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.sanctuaryInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(MoriColors.sanctuaryInk.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                if authorizationDenied {
                    Text(MoriL10n.display("Notifications are off. Enable them in iOS Settings to use the bell."))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalClay)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    Button(action: onEnableRecommended) {
                        HStack(spacing: 8) {
                            MoriBitmapIconImage(icon: .bell, size: 18)
                            Text(MoriL10n.display("Use 30m bell"))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.sanctuarySurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            MoriGeneratedArtImage(art: .buttonWash, contentMode: .fill)
                                .overlay(MoriColors.sanctuaryInk.opacity(0.14))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: openSettings) {
                        HStack(spacing: 8) {
                            MoriBitmapIconImage(icon: .settings, size: 15, opacity: 0.84)

                            Text(MoriL10n.display("Customize"))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.sanctuaryInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(MoriColors.sanctuaryInk.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 16)
    }

    private func openSettings() {
        openSettleRoute(.mindfulnessBellSettings)
    }
}

struct MindfulnessBellSettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(MindfulnessBellDefaults.isActiveKey) private var isActive = false
    @AppStorage(MindfulnessBellDefaults.randomModeKey) private var randomMode = false
    @AppStorage(MindfulnessBellDefaults.intervalMinutesKey) private var intervalMinutes = 30
    @AppStorage(MindfulnessBellDefaults.bellsPerHourKey) private var bellsPerHour = 1
    @AppStorage(MindfulnessBellDefaults.startHourKey) private var startHour = 9
    @AppStorage(MindfulnessBellDefaults.endHourKey) private var endHour = 21
    @AppStorage(MindfulnessBellDefaults.nextFireKey) private var nextFireTimestamp: Double = 0
    @AppStorage(MindfulnessBellDefaults.breathingTechniqueIDKey) private var breathingTechniqueID = MindfulnessBellDefaults.defaultBreathingTechniqueID
    @AppStorage(MindfulnessBellDefaults.breathingDurationMinutesKey) private var breathingDurationMinutes = MindfulnessBellDefaults.defaultBreathingDurationMinutes
    @State private var authorizationStatus = MoriL10n.string("status.checking", defaultValue: "Checking")
    @State private var authorizationDenied = false

    var body: some View {
        MoriPaperBackground(variant: .bell) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    MoriPageHeader(
                        eyebrow: "Settle",
                        title: "Mindfulness Bell",
                        subtitle: "A soft recurring bell for one breath before the next thing."
                    )

                    MindfulnessBellHeroVisual()
                    MindfulnessBellStatusToggleCard(
                        isActive: $isActive,
                        nextFireTimestamp: nextFireTimestamp,
                        authorizationStatus: authorizationStatus,
                        authorizationDenied: authorizationDenied
                    )
                    MindfulnessBellRhythmControls(
                        randomMode: $randomMode,
                        intervalMinutes: $intervalMinutes,
                        bellsPerHour: $bellsPerHour
                    )
                    MindfulnessBellTapActionControls(
                        breathingTechniqueID: $breathingTechniqueID,
                        breathingDurationMinutes: $breathingDurationMinutes
                    )
                    MindfulnessBellActiveHoursControls(
                        startHour: $startHour,
                        endHour: $endHour
                    )
                    MindfulnessBellActionButtons(
                        onPreview: previewBell,
                        onRefresh: requestAuthorizationAndSchedule
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, MoriMainTabBarMetrics.scrollBottomInset)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .mindfulnessBellLifecycle(
            scenePhase: scenePhase,
            isActive: isActive,
            randomMode: randomMode,
            intervalMinutes: intervalMinutes,
            bellsPerHour: bellsPerHour,
            startHour: startHour,
            endHour: endHour,
            onPrepare: refreshBellStatus,
            onActiveChange: handleToggle,
            onScheduleSettingsChange: scheduleIfActive,
            onSceneActive: refreshBellStatus
        )
    }

    private func handleToggle(_ enabled: Bool) {
        guard enabled else {
            MindfulnessBellScheduler.shared.cancelAll()
            return
        }

        requestAuthorizationAndSchedule()
    }

    private func previewBell() {
        SettleBellService.shared.playIntervalBell()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func requestAuthorizationAndSchedule() {
        authorizationDenied = false
        MindfulnessBellScheduler.shared.requestAuthorization { granted in
            updateAuthorizationStatus()
            isActive = granted
            authorizationDenied = !granted

            if granted {
                MindfulnessBellScheduler.shared.scheduleUpcomingBells()
            }
        }
    }

    private func scheduleIfActive() {
        guard isActive else { return }
        MindfulnessBellScheduler.shared.scheduleUpcomingBells()
    }

    private func refreshBellStatus() {
        updateAuthorizationStatus()
        MindfulnessBellScheduler.shared.refreshIfNeeded()
    }

    private func updateAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    authorizationStatus = MoriL10n.string("status.allowed", defaultValue: "Allowed")
                    authorizationDenied = false
                case .denied:
                    authorizationStatus = MoriL10n.string("status.denied", defaultValue: "Denied")
                case .notDetermined:
                    authorizationStatus = MoriL10n.string("status.not_asked", defaultValue: "Not asked")
                @unknown default:
                    authorizationStatus = MoriL10n.string("status.unknown", defaultValue: "Unknown")
                }
            }
        }
    }

}

struct MindfulnessBellStatusRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            MoriBitmapIconImage(icon: .bell, size: 18)
            Text(MoriL10n.display(text))
        }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(MoriColors.sanctuaryInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(MoriColors.sanctuarySage.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct MindfulnessBellCompletionNudge: View {
    let authorizationDenied: Bool
    let onSetBell: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 11) {
                MoriBitmapIconImage(icon: .bell, size: 18, opacity: 0.86)
                    .frame(width: 34, height: 34)
                    .background(MoriColors.sanctuarySurface.opacity(0.74))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Carry this calm into the day")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text("Set a soft bell so one breath can meet you later.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if authorizationDenied {
                Text("Notifications are off. Enable them in iOS Settings to use the bell.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalClay)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button(action: onSetBell) {
                    HStack(spacing: 6) {
                        MoriBitmapIconImage(icon: .bell, size: 14, opacity: 0.94)
                            .frame(width: 22, height: 22)
                            .background(MoriColors.sanctuarySurface.opacity(0.86))
                            .clipShape(Circle())

                        Text("Set bell")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(MoriColors.botanicalInk)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onDismiss) {
                    Text("Not now")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(MoriColors.botanicalPaperDeep.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

enum MindfulnessBellStatusFormatter {
    static func nextBellText(isActive: Bool, nextFireTimestamp: Double) -> String {
        guard isActive else { return MoriL10n.string("bell.status.paused", defaultValue: "Bell paused") }
        guard nextFireTimestamp > 0 else { return MoriL10n.string("bell.status.ready_to_schedule", defaultValue: "Ready to schedule") }

        let next = Date(timeIntervalSince1970: nextFireTimestamp)
        guard next > Date() else { return MoriL10n.string("bell.status.refreshing", defaultValue: "Refreshing bell") }

        let minutes = max(1, Int((next.timeIntervalSinceNow / 60.0).rounded(.up)))
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return MoriL10n.string("bell.status.next_hours", defaultValue: "Next bell in %dh", arguments: [hours])
            }
            return MoriL10n.string(
                "bell.status.next_hours_minutes",
                defaultValue: "Next bell in %dh %dm",
                arguments: [hours, remainingMinutes]
            )
        }
        return MoriL10n.string("bell.status.next_minutes", defaultValue: "Next bell in %dm", arguments: [minutes])
    }
}
