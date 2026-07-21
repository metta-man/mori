import Foundation
import DeviceActivity

struct AttentionShieldScheduleFactory {
    private static let timestampComponents: Set<Calendar.Component> = [
        .year,
        .month,
        .day,
        .hour,
        .minute,
        .second
    ]
    private static let timeComponents: Set<Calendar.Component> = [
        .hour,
        .minute,
        .second
    ]

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func dailyThresholdSchedule() -> DeviceActivitySchedule {
        DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
    }

    func morningGateSchedule() -> DeviceActivitySchedule {
        DeviceActivitySchedule(
            intervalStart: MorningGate.startComponents,
            intervalEnd: MorningGate.endComponents,
            repeats: true
        )
    }

    func beforeFeedGraceSchedule(
        now: Date = Date(),
        graceUntil: Date
    ) -> DeviceActivitySchedule? {
        let startDate = max(now.addingTimeInterval(1), graceUntil)
        let endDate = startDate.addingTimeInterval(15 * 60)
        guard startDate < endDate else { return nil }

        // Repeating time-of-day schedule: one-shot schedules are not reliable for this
        // callback, and repeating schedules should not carry absolute date components.
        // Start the interval at the grace expiry and re-lock in intervalDidStart.
        return DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(Self.timeComponents, from: startDate),
            intervalEnd: calendar.dateComponents(Self.timeComponents, from: endDate),
            repeats: true
        )
    }

    func activeSessionSchedule(
        now: Date = Date(),
        endDate: Date
    ) -> DeviceActivitySchedule? {
        let startDate = min(now.addingTimeInterval(1), endDate.addingTimeInterval(-1))
        return oneShotSchedule(startDate: startDate, endDate: endDate)
    }

    private func oneShotSchedule(startDate: Date, endDate: Date) -> DeviceActivitySchedule? {
        guard startDate < endDate else { return nil }

        return DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(Self.timestampComponents, from: startDate),
            intervalEnd: calendar.dateComponents(Self.timestampComponents, from: endDate),
            repeats: false
        )
    }
}
