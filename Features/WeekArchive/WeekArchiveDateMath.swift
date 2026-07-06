import Foundation

func moriMondayWeekStart(for date: Date) -> Date {
    var calendar = Calendar.current
    calendar.firstWeekday = 2

    let day = calendar.startOfDay(for: date)
    let weekday = calendar.component(.weekday, from: day)
    let daysFromMonday = (weekday - calendar.firstWeekday + 7) % 7
    return calendar.date(byAdding: .day, value: -daysFromMonday, to: day) ?? day
}

func moriMondayWeekStart(for week: WeekCoordinate, archiveStartDate: Date) -> Date {
    var calendar = Calendar.current
    calendar.firstWeekday = 2

    let archiveStartDay = calendar.startOfDay(for: archiveStartDate)
    let archiveYearStart = calendar.date(byAdding: .year, value: week.year, to: archiveStartDay) ?? archiveStartDay
    let archiveWeekStart = moriMondayWeekStart(for: archiveYearStart)
    return calendar.date(byAdding: .weekOfYear, value: week.week, to: archiveWeekStart) ?? archiveWeekStart
}

func moriVisualWeekIndex(for date: Date, archiveStartDate: Date, archiveSpanYears: Int) -> Int? {
    var calendar = Calendar.current
    calendar.firstWeekday = 2

    let archiveStartDay = calendar.startOfDay(for: archiveStartDate)
    let entryDay = calendar.startOfDay(for: date)
    guard entryDay >= archiveStartDay else { return nil }

    let archiveYearAtEntry = calendar.dateComponents([.year], from: archiveStartDay, to: entryDay).year ?? 0
    guard archiveYearAtEntry < archiveSpanYears else { return nil }

    let archiveYearStart = calendar.date(byAdding: .year, value: archiveYearAtEntry, to: archiveStartDay) ?? archiveStartDay
    let archiveWeekStart = moriMondayWeekStart(for: archiveYearStart)
    let entryWeekStart = moriMondayWeekStart(for: entryDay)
    let weeksIntoArchiveYear = calendar.dateComponents([.weekOfYear], from: archiveWeekStart, to: entryWeekStart).weekOfYear ?? 0
    let weekIntoArchiveYear = max(0, min(51, weeksIntoArchiveYear))

    return archiveYearAtEntry * 52 + weekIntoArchiveYear
}
