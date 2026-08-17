import Foundation
import DeviceActivity
import FamilyControls

@MainActor
struct AttentionShieldActivityScheduler {
    private let activityCenter: DeviceActivityCenter
    private let scheduleFactory: AttentionShieldScheduleFactory

    init(
        activityCenter: DeviceActivityCenter = DeviceActivityCenter(),
        scheduleFactory: AttentionShieldScheduleFactory = AttentionShieldScheduleFactory()
    ) {
        self.activityCenter = activityCenter
        self.scheduleFactory = scheduleFactory
    }

    func stopMorningGate() {
        activityCenter.stopMonitoring([.moriMorningGate])
    }

    func scheduleMorningGate() throws {
        stopMorningGate()
        try activityCenter.startMonitoring(.moriMorningGate, during: scheduleFactory.morningGateSchedule())
    }

    func stopDailyThreshold() {
        activityCenter.stopMonitoring([.moriDailySelectedApps])
    }

    func scheduleDailyThreshold(
        selection: FamilyActivitySelection,
        thresholdMinutes: Int
    ) throws {
        stopDailyThreshold()

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: Set(),
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: thresholdMinutes)
        )

        try activityCenter.startMonitoring(
            .moriDailySelectedApps,
            during: scheduleFactory.dailyThresholdSchedule(),
            events: [.moriSelectedAppsThreshold: event]
        )
    }

    func stopBeforeFeedGrace() {
        activityCenter.stopMonitoring([.moriBeforeFeedGrace])
    }

    func scheduleBeforeFeedGrace(graceUntil: Date) throws {
        guard let schedule = scheduleFactory.beforeFeedGraceSchedule(graceUntil: graceUntil) else {
            stopBeforeFeedGrace()
            return
        }

        stopBeforeFeedGrace()
        try activityCenter.startMonitoring(.moriBeforeFeedGrace, during: schedule)
    }

    func stopActiveSession() {
        activityCenter.stopMonitoring([.moriActiveSession])
    }

    func stopAll() {
        activityCenter.stopMonitoring([
            .moriMorningGate,
            .moriDailySelectedApps,
            .moriBeforeFeedGrace,
            .moriActiveSession
        ])
    }

    func scheduleActiveSession(endDate: Date) throws -> Bool {
        guard let schedule = scheduleFactory.activeSessionSchedule(endDate: endDate) else {
            stopActiveSession()
            return false
        }

        stopActiveSession()
        try activityCenter.startMonitoring(.moriActiveSession, during: schedule)
        return true
    }
}
