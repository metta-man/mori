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
        let endDate = startDate.addingTimeInterval(60)
        return oneShotSchedule(startDate: startDate, endDate: endDate)
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
