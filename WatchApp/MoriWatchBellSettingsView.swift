import SwiftUI
import UserNotifications

struct MoriWatchBellSettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(MoriWatchBellDefaults.isActiveKey) private var isActive = false
    @AppStorage(MoriWatchBellDefaults.randomModeKey) private var randomMode = false
    @AppStorage(MoriWatchBellDefaults.intervalMinutesKey) private var intervalMinutes = 15
    @AppStorage(MoriWatchBellDefaults.bellsPerHourKey) private var bellsPerHour = 1
    @AppStorage(MoriWatchBellDefaults.startHourKey) private var startHour = 9
    @AppStorage(MoriWatchBellDefaults.endHourKey) private var endHour = 21
    @AppStorage(MoriWatchBellDefaults.nextFireKey) private var nextFireTimestamp: Double = 0
    @State private var authorizationStatus = MoriL10n.string("status.checking", defaultValue: "Checking")

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 9) {
                header

                Toggle(isOn: $isActive) {
                    HStack(spacing: 7) {
                        MoriBitmapIconImage(icon: .bell, size: 14, opacity: 0.92)

                        Text(MoriL10n.display("Bell notifications"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                    }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MoriWatchPalette.ink)
                }
                .tint(MoriWatchPalette.moss)
                .padding(9)
                .moriWatchCard(cornerRadius: 14)

                modeControls
                activeHoursControls
                bellActions
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .moriWatchPaperBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateAuthorizationStatus()
            if isActive {
                scheduleBells()
            }
        }
        .onChange(of: isActive) { _, enabled in
            if enabled {
                requestAuthorizationAndSchedule()
            } else {
                MoriWatchBellScheduler.shared.cancelAll()
            }
        }
        .onChange(of: randomMode) { _, _ in scheduleIfActive() }
        .onChange(of: intervalMinutes) { _, _ in scheduleIfActive() }
        .onChange(of: bellsPerHour) { _, _ in scheduleIfActive() }
        .onChange(of: startHour) { _, _ in scheduleIfActive() }
        .onChange(of: endHour) { _, _ in scheduleIfActive() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                updateAuthorizationStatus()
                MoriWatchBellScheduler.shared.refreshIfNeeded()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                MoriBitmapIconImage(icon: .bell, size: 20)
                    .frame(width: 32, height: 32)
                    .background(MoriWatchPalette.seed.opacity(0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(MoriL10n.display("Tap a bell to breathe"))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(MoriWatchPalette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    Text(MoriL10n.string("watch.bell.title", defaultValue: "Mindfulness bell"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MoriWatchPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    Text(nextBellText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MoriWatchPalette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }
            }

            Text(MoriL10n.string(
                "watch.bell.promise",
                defaultValue: "A gentle tap that opens a one breath reset when your day starts drifting."
            ))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(MoriWatchPalette.muted)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: false, vertical: true)

            Text(MoriL10n.string("status.with_value", defaultValue: "Status: %@", arguments: [authorizationStatus]))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(MoriWatchPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .padding(9)
        .moriWatchCard(cornerRadius: 14)
    }

    private var modeControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                bellModeButton(title: "Fixed", isSelected: !randomMode) {
                    randomMode = false
                }

                bellModeButton(title: "Random", isSelected: randomMode) {
                    randomMode = true
                }
            }

            if randomMode {
                bellStepper(
                    title: "Bells / hour",
                    value: bellsPerHour,
                    range: 1...4,
                    decrement: { bellsPerHour = max(1, bellsPerHour - 1) },
                    increment: { bellsPerHour = min(4, bellsPerHour + 1) }
                )
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(MoriL10n.display("Interval"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MoriWatchPalette.muted)

                    LazyVGrid(columns: bellOptionColumns, spacing: 6) {
                        ForEach([5, 10, 15, 30, 60], id: \.self) { minutes in
                            bellOptionButton(
                                title: localizedMinuteTitle(minutes),
                                isSelected: intervalMinutes == minutes
                            ) {
                                intervalMinutes = minutes
                            }
                        }
                    }
                }
            }
        }
        .padding(9)
        .moriWatchCard(cornerRadius: 14)
    }

    private var activeHoursControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(MoriL10n.display("Active Hours"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MoriWatchPalette.muted)

            bellStepper(
                title: MoriL10n.string(
                    "watch.bell.active_start",
                    defaultValue: "Start %@",
                    arguments: [formattedHour(startHour)]
                ),
                value: startHour,
                range: 0...23,
                decrement: { startHour = max(0, startHour - 1) },
                increment: { startHour = min(23, startHour + 1) }
            )

            bellStepper(
                title: MoriL10n.string(
                    "watch.bell.active_end",
                    defaultValue: "End %@",
                    arguments: [formattedHour(endHour)]
                ),
                value: endHour,
                range: 0...23,
                decrement: { endHour = max(0, endHour - 1) },
                increment: { endHour = min(23, endHour + 1) }
            )
        }
        .padding(9)
        .moriWatchCard(cornerRadius: 14)
    }

    private var bellActions: some View {
        HStack(spacing: 7) {
            Button {
                MoriWatchBellScheduler.shared.playBellHaptic()
            } label: {
                bellActionLabel(
                    icon: .bell,
                    title: MoriL10n.string("watch.bell.test", defaultValue: "Test")
                )
            }
            .buttonStyle(MoriWatchSecondaryButtonStyle())

            Button {
                requestAuthorizationAndSchedule()
            } label: {
                bellActionLabel(
                    icon: .refresh,
                    title: MoriL10n.string("watch.bell.schedule", defaultValue: "Schedule")
                )
            }
            .buttonStyle(MoriWatchPrimaryButtonStyle(tint: MoriWatchPalette.moss))
        }
    }

    private func bellActionLabel(icon: MoriBitmapIcon, title: String) -> some View {
        HStack(spacing: 6) {
            MoriBitmapIconImage(icon: icon, size: 16, opacity: 0.94)

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity)
    }

    private var nextBellText: String {
        guard isActive else { return MoriL10n.string("bell.status.paused", defaultValue: "Bell paused") }
        guard nextFireTimestamp > 0 else { return MoriL10n.string("bell.status.ready_to_schedule", defaultValue: "Ready to schedule") }

        let next = Date(timeIntervalSince1970: nextFireTimestamp)
        guard next > Date() else { return MoriL10n.string("bell.status.refreshing", defaultValue: "Refreshing bell") }

        let minutes = max(1, Int((next.timeIntervalSinceNow / 60.0).rounded(.up)))
        return MoriL10n.string("bell.status.next_in_minutes", defaultValue: "Next in %dm", arguments: [minutes])
    }

    private func bellModeButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(MoriL10n.display(title))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? MoriWatchPalette.background : MoriWatchPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MoriWatchPalette.moss.opacity(0.82))
                    } else {
                        MoriWatchCardBackground(cornerRadius: 12)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var bellOptionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }

    private func bellOptionButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(MoriL10n.display(title))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? MoriWatchPalette.background : MoriWatchPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
                .frame(maxWidth: .infinity, minHeight: 38)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MoriWatchPalette.moss.opacity(0.82))
                    } else {
                        MoriWatchCardBackground(cornerRadius: 12)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func bellStepper(
        title: String,
        value: Int,
        range: ClosedRange<Int>,
        decrement: @escaping () -> Void,
        increment: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 7) {
            Text(MoriL10n.display(title))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MoriWatchPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.58)

            Spacer(minLength: 0)

            Button(action: decrement) {
                MoriBitmapIconImage(icon: .minus, size: 13, opacity: value <= range.lowerBound ? 0.36 : 0.88)
                    .frame(width: 26, height: 26)
            }
            .disabled(value <= range.lowerBound)
            .accessibilityLabel(MoriL10n.string(
                "watch.control.decrease_value",
                defaultValue: "Decrease %@",
                arguments: [MoriL10n.display(title)]
            ))
            .buttonStyle(MoriWatchIconButtonStyle())

            Button(action: increment) {
                MoriBitmapIconImage(icon: .plus, size: 13, opacity: value >= range.upperBound ? 0.36 : 0.88)
                    .frame(width: 26, height: 26)
            }
            .disabled(value >= range.upperBound)
            .accessibilityLabel(MoriL10n.string(
                "watch.control.increase_value",
                defaultValue: "Increase %@",
                arguments: [MoriL10n.display(title)]
            ))
            .buttonStyle(MoriWatchIconButtonStyle(tint: MoriWatchPalette.moss))
        }
        .padding(8)
        .background(MoriWatchCardBackground(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formattedHour(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }

    private func localizedMinuteTitle(_ minutes: Int) -> String {
        MoriL10n.string("duration.minutes_short", defaultValue: "%dm", arguments: [minutes])
    }

    private func requestAuthorizationAndSchedule() {
        MoriWatchNotificationCenter.shared.requestAuthorization { granted in
            isActive = granted
            authorizationStatus = granted
                ? MoriL10n.string("status.allowed", defaultValue: "Allowed")
                : MoriL10n.string("status.denied", defaultValue: "Denied")
            if granted {
                scheduleBells()
            }
        }
    }

    private func scheduleIfActive() {
        guard isActive else { return }
        scheduleBells()
    }

    private func scheduleBells() {
        MoriWatchBellScheduler.shared.scheduleUpcomingBells()
    }

    private func updateAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    authorizationStatus = MoriL10n.string("status.allowed", defaultValue: "Allowed")
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
