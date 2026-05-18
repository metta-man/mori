import Foundation

enum MoriSharedDefaults {
    static let appGroupIdentifier = "group.com.mettalabs.mori"

    static var shared: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}

enum MoriWidgetTimeUnit: String, CaseIterable {
    case days
    case weeks
    case months
    case years

    var singularLabel: String {
        switch self {
        case .days: return "day"
        case .weeks: return "week"
        case .months: return "month"
        case .years: return "year"
        }
    }

    var pluralLabel: String {
        switch self {
        case .days: return "days"
        case .weeks: return "weeks"
        case .months: return "months"
        case .years: return "years"
        }
    }
}

struct MoriWidgetSnapshot {
    let birthDate: Date
    let lifeExpectancy: Int
    let timeUnit: MoriWidgetTimeUnit
    let now: Date

    init(
        birthDate: Date,
        lifeExpectancy: Int,
        timeUnit: MoriWidgetTimeUnit,
        now: Date = Date()
    ) {
        self.birthDate = birthDate
        self.lifeExpectancy = max(lifeExpectancy, 1)
        self.timeUnit = timeUnit
        self.now = now
    }

    init(defaults: UserDefaults = MoriSharedDefaults.shared, now: Date = Date()) {
        let fallbackBirthDate = Calendar.current.date(byAdding: .year, value: -30, to: now) ?? now
        let savedBirthDate = defaults.object(forKey: "birthDate") as? Date
        let savedLifeExpectancy = defaults.integer(forKey: "lifeExpectancy")
        let savedTimeUnit = defaults.string(forKey: "clockTimeUnit").flatMap(MoriWidgetTimeUnit.init(rawValue:))

        self.init(
            birthDate: savedBirthDate ?? fallbackBirthDate,
            lifeExpectancy: savedLifeExpectancy > 0 ? savedLifeExpectancy : 80,
            timeUnit: savedTimeUnit ?? .days,
            now: now
        )
    }

    var endDate: Date {
        Calendar.current.date(byAdding: .year, value: lifeExpectancy, to: birthDate) ?? birthDate
    }

    var totalWeeks: Int {
        lifeExpectancy * 52
    }

    var weeksLived: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: birthDate, to: now).day ?? 0
        return min(max(0, days / 7), totalWeeks)
    }

    var currentWeekIndex: Int {
        min(weeksLived, max(totalWeeks - 1, 0))
    }

    var weeksRemaining: Int {
        max(totalWeeks - weeksLived, 0)
    }

    var progress: Double {
        guard totalWeeks > 0 else { return 0 }
        return Double(weeksLived) / Double(totalWeeks)
    }

    var primaryCountdownValue: Int {
        let calendar = Calendar.current
        let days = max(0, calendar.dateComponents([.day], from: now, to: endDate).day ?? 0)

        switch timeUnit {
        case .days:
            return days
        case .weeks:
            return days / 7
        case .months:
            return max(0, calendar.dateComponents([.month], from: now, to: endDate).month ?? 0)
        case .years:
            return max(0, calendar.dateComponents([.year], from: now, to: endDate).year ?? 0)
        }
    }

    var primaryCountdownLabel: String {
        primaryCountdownValue == 1 ? timeUnit.singularLabel : timeUnit.pluralLabel
    }

    var primaryCountdownUnitSymbol: String {
        switch timeUnit {
        case .days: return "d"
        case .weeks: return "w"
        case .months: return "mo"
        case .years: return "y"
        }
    }

    var primaryCompactCountdownValue: String {
        let value = primaryCountdownValue

        if value >= 10_000 {
            return "\(value / 1_000)K"
        }

        if value >= 1_000 {
            let rounded = Double(value) / 1_000
            return String(format: "%.1fK", rounded)
        }

        return value.formatted()
    }

    var primaryCompactCountdownText: String {
        "\(primaryCompactCountdownValue) \(primaryCountdownUnitSymbol)"
    }
}
