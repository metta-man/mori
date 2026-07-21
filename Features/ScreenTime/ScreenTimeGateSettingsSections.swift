import SwiftUI
import UIKit

struct BeforeFeedSettingsSection: View {
    @Binding var nativeGateEnabled: Bool
    @Binding var hiddenAppLockEnabled: Bool
    @Binding var durationSeconds: Int
    @Binding var graceWindowSeconds: Int
    @Binding var breathingTechniqueID: String

    let isScreenTimeAuthorized: Bool
    let feedAppSummary: MoriScreenTimeProfileSummary
    let breathingSummary: String
    let feedAppsStatusText: String
    let onEditFeedApps: () -> Void
    let onUseDefaultFeedAppsChange: (Bool) -> Void
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

            Toggle(isOn: $hiddenAppLockEnabled) {
                screenTimeLabel("Hide feed app icons", icon: .lockShield)
            }

            Toggle(
                isOn: Binding(
                    get: { feedAppSummary.usesDefaultSelection },
                    set: onUseDefaultFeedAppsChange
                )
            ) {
                screenTimeLabel("Use default block list", icon: .timer)
            }

            Text(MoriL10n.display("Selected feed apps show Mori's iOS Screen Time shield before they open. Category selections are ignored so apps like WhatsApp are not caught accidentally."))
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)

            if hiddenAppLockEnabled {
                Text(MoriL10n.display("Selected feed apps disappear outside the open window. Turn this off to restore app icons."))
                    .font(.footnote)
                    .foregroundColor(MoriColors.botanicalMuted)
            }

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

struct ScreenTimeMonitorHealthSection: View {
    let events: [MoriScreenTimeMonitorHealthEvent]
    let onRefresh: () -> Void

    var body: some View {
        let summary = MonitorHealthSummary(events: events)
        Section {
            HStack {
                screenTimeLabel("Monitor health", icon: .lockShield)

                Spacer()

                Button(MoriL10n.display("Refresh"), action: onRefresh)
                    .font(.footnote.weight(.semibold))
            }

            MonitorHealthSummaryPanel(summary: summary)

            Button {
                UIPasteboard.general.string = summary.debugReport
            } label: {
                HStack {
                    screenTimeLabel("Copy debug report", icon: .timer)
                    Spacer()
                    Text(MoriL10n.display("Copy"))
                        .font(.footnote.weight(.semibold))
                }
            }
            .disabled(events.isEmpty)

            if let latestEvent = events.first {
                MonitorHealthLatestRow(event: latestEvent)
            } else {
                Text(MoriL10n.display("No Screen Time monitor events recorded yet. Complete a Before Feed reset, wait for the open window to end, then refresh."))
                    .font(.footnote)
                    .foregroundColor(MoriColors.botanicalMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(events.prefix(6)) { event in
                MonitorHealthEventRow(event: event)
            }
        } header: {
            Text(MoriL10n.display("Screen Time Monitor"))
        } footer: {
            Text(MoriL10n.display("Use this to confirm whether iOS fired Mori's DeviceActivity monitor and whether the Before Feed shield was applied after the open window."))
        }
    }
}

private struct MonitorHealthSummary {
    let events: [MoriScreenTimeMonitorHealthEvent]

    private var traceID: String? {
        events.first?.traceID
    }

    private var traceEvents: [MoriScreenTimeMonitorHealthEvent] {
        guard let traceID else { return Array(events.prefix(12)) }
        return events.filter { $0.traceID == traceID }
    }

    var title: String {
        if events.isEmpty {
            return MoriL10n.display("No trace yet")
        }
        if hasPass {
            return MoriL10n.display("PASS")
        }
        if hasPartial {
            return MoriL10n.display("PARTIAL")
        }
        if hasFailure {
            return MoriL10n.display("FAIL")
        }
        return MoriL10n.display("WAITING")
    }

    var detail: String {
        if events.isEmpty {
            return MoriL10n.display("Complete one Before Feed reset, wait for the open window to end, then refresh.")
        }
        if hasPass {
            return MoriL10n.display("DeviceActivity fired at the open-window expiry and reapplied the Screen Time shield.")
        }
        if hasStrictLock && hasScheduleFailure {
            return MoriL10n.display("Shield lock was applied by fallback, but DeviceActivity scheduling failed for this trace.")
        }
        if hasStrictLock && !hasMonitorCallback {
            return MoriL10n.display("Shield lock is applied now, but no DeviceActivity expiry callback appeared in this trace.")
        }
        if hasPartial {
            return MoriL10n.display("Mori applied a shield, but the post-window shield lock is missing from this trace.")
        }
        if hasFailure {
            return failureReason ?? MoriL10n.display("Before Feed did not reach strict lock.")
        }
        return MoriL10n.display("Waiting for the open window to expire or for iOS to deliver the monitor callback.")
    }

    var tint: Color {
        if hasPass { return MoriColors.botanicalMoss }
        if hasPartial { return MoriColors.botanicalClay }
        if hasFailure { return .red }
        return MoriColors.botanicalInk
    }

    var debugReport: String {
        var lines: [String] = []
        lines.append("Before Feed monitor health")
        lines.append("verdict: \(title)")
        if let traceID {
            lines.append("trace: \(traceID)")
        }
        lines.append("events:")
        for event in traceEvents.prefix(20) {
            lines.append("- \(MonitorHealthEventFormatter.line(for: event))")
        }
        return lines.joined(separator: "\n")
    }

    private var hasPass: Bool {
        hasMonitorCallback && hasStrictLock && !hasScheduleFailure
    }

    private var hasPartial: Bool {
        (hasStrictLock && hasScheduleFailure) ||
        (hasStrictLock && !hasMonitorCallback) ||
        (traceEvents.contains { $0.kind == .shieldApplied } && !hasStrictLock)
    }

    private var hasStrictLock: Bool {
        traceEvents.contains {
            ($0.kind == .strictLockApplied || $0.kind == .hiddenAppLockApplied) &&
            ($0.applicationTokenCount ?? 0) > 0
        }
    }

    private var hasScheduleFailure: Bool {
        traceEvents.contains { $0.kind == .beforeFeedGraceScheduleFailed }
    }

    private var hasMonitorCallback: Bool {
        traceEvents.contains { event in
            event.kind == .beforeFeedGraceIntervalEnded ||
            event.kind == .beforeFeedGraceIntervalStarted
        }
    }

    private var hasFailure: Bool {
        failureReason != nil
    }

    private var failureReason: String? {
        if hasScheduleFailure && !hasStrictLock {
            return MoriL10n.display("DeviceActivity schedule failed.")
        }
        if traceEvents.contains(where: { $0.beforeFeedNativeGateEnabled == false }) {
            return MoriL10n.display("Before Feed native gate is off.")
        }
        if traceEvents.contains(where: { $0.beforeFeedHasSelection == false }) {
            return MoriL10n.display("No Before Feed app token was selected.")
        }
        if traceEvents.contains(where: { $0.kind == .beforeFeedGraceScheduleSkipped && ($0.message ?? "").contains("authorization") }) {
            return MoriL10n.display("Screen Time authorization is not available.")
        }
        return nil
    }
}

private struct MonitorHealthSummaryPanel: View {
    let summary: MonitorHealthSummary

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(summary.tint.opacity(0.16))
                .frame(width: 28, height: 28)
                .overlay {
                    Circle()
                        .fill(summary.tint)
                        .frame(width: 8, height: 8)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(summary.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(summary.tint)

                Text(summary.detail)
                    .font(.caption)
                    .foregroundColor(MoriColors.botanicalMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MonitorHealthLatestRow: View {
    let event: MoriScreenTimeMonitorHealthEvent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MoriBitmapIconImage(icon: icon, size: 16, opacity: 0.9)
                .frame(width: 26, height: 26)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display(event.kind.title))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(MoriL10n.display("Latest event") + " · " + Self.timeFormatter.string(from: event.recordedAt))
                    .font(.caption)
                    .foregroundColor(MoriColors.botanicalMuted)
            }
        }
    }

    private var icon: MoriBitmapIcon {
        switch event.kind {
        case .shieldApplied, .strictLockApplied, .hiddenAppLockApplied, .beforeFeedGraceIntervalStarted, .beforeFeedGraceExpired:
            return .leaf
        case .beforeFeedGraceScheduleFailed:
            return .lockShield
        default:
            return .timer
        }
    }

    private var color: Color {
        switch event.kind {
        case .beforeFeedGraceScheduleFailed:
            return .red
        case .shieldApplied, .strictLockApplied, .hiddenAppLockApplied, .beforeFeedGraceIntervalStarted, .beforeFeedGraceExpired:
            return MoriColors.botanicalMoss
        default:
            return MoriColors.botanicalInk
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()
}

private struct MonitorHealthEventRow: View {
    let event: MoriScreenTimeMonitorHealthEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(MoriL10n.display(event.kind.title))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                Spacer()

                Text(Self.timeFormatter.string(from: event.recordedAt))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(MoriColors.botanicalMuted)
            }

            Text(detailText)
                .font(.caption)
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    private var detailText: String {
        let details = detailItems
        return details.isEmpty ? MoriL10n.display("No detail") : details.joined(separator: " · ")
    }

    private var detailItems: [String] {
        var items: [String] = []

        if let traceID = event.shortTraceID {
            items.append("trace \(traceID)")
        }
        if let action = event.action {
            items.append(action)
        }
        if let feature = event.featureRawValue {
            items.append("feature \(feature)")
        }
        if let activeSession = event.activeSessionFeatureRawValue {
            items.append("active \(activeSession)")
        }
        if let policy = event.policy {
            items.append("policy \(policy.title)")
        }
        if let tokenCount = event.totalTokenCount {
            items.append("\(tokenCount) tokens")
        }
        if let names = event.displayNames, !names.isEmpty {
            items.append("names \(names.prefix(3).joined(separator: ", "))")
        }
        if let inGraceWindow = event.beforeFeedInGraceWindow {
            items.append(inGraceWindow ? "open window active" : "open window closed")
        }
        if let hasSelection = event.beforeFeedHasSelection {
            items.append(hasSelection ? "feed apps selected" : "no feed app selection")
        }
        if let graceUntil = event.graceUntil {
            items.append("until \(Self.timeFormatter.string(from: graceUntil))")
        }
        if let message = event.message {
            items.append(message)
        }

        return items
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()
}

private enum MonitorHealthEventFormatter {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    static func line(for event: MoriScreenTimeMonitorHealthEvent) -> String {
        var items = [
            timeFormatter.string(from: event.recordedAt),
            event.kind.title
        ]
        if let action = event.action {
            items.append("action=\(action)")
        }
        if let policy = event.policy {
            items.append("policy=\(policy.title)")
        }
        if let tokens = event.totalTokenCount {
            items.append("tokens=\(tokens)")
        }
        if let names = event.displayNames, !names.isEmpty {
            items.append("names=\(names.prefix(5).joined(separator: ","))")
        }
        if let inGrace = event.beforeFeedInGraceWindow {
            items.append("grace=\(inGrace ? "open" : "closed")")
        }
        if let selection = event.beforeFeedHasSelection {
            items.append("selection=\(selection)")
        }
        if let message = event.message {
            items.append("message=\(message)")
        }
        return items.joined(separator: " | ")
    }
}

struct MorningGateSettingsSection: View {
    @Binding var isEnabled: Bool
    @Binding var hiddenAppLockEnabled: Bool
    @Binding var startDate: Date
    @Binding var durationSeconds: Int
    @Binding var breathingTechniqueID: String

    let morningAppSummary: MoriScreenTimeProfileSummary
    let breathingSummary: String
    let morningAppsStatusText: String
    let onEditMorningApps: () -> Void
    let onUseDefaultMorningAppsChange: (Bool) -> Void

    var body: some View {
        Section {
            Toggle(isOn: $isEnabled) {
                screenTimeLabel("Morning Gate", icon: .leaf)
            }

            Toggle(isOn: $hiddenAppLockEnabled) {
                screenTimeLabel("Hide morning app icons", icon: .lockShield)
            }

            Toggle(
                isOn: Binding(
                    get: { morningAppSummary.usesDefaultSelection },
                    set: onUseDefaultMorningAppsChange
                )
            ) {
                screenTimeLabel("Use default block list", icon: .timer)
            }

            if hiddenAppLockEnabled {
                Text(MoriL10n.display("Selected morning apps disappear until Morning Reset is complete or the window ends."))
                    .font(.footnote)
                    .foregroundColor(MoriColors.botanicalMuted)
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
