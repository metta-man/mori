import SwiftUI

struct WeekArchiveMonthGrid: View {
    @Binding var focusedMonth: Date
    let data: WeekArchiveData
    let today: Date
    let onDaySelected: (Date) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 7
    )

    var body: some View {
        VStack(spacing: 0) {
            LifeGridPeriodNavigator(
                title: Self.monthFormatter.string(from: focusedMonth),
                previousLabel: MoriL10n.display("Previous month"),
                nextLabel: MoriL10n.display("Next month"),
                previousAction: { moveMonth(by: -1) },
                nextAction: { moveMonth(by: 1) }
            )
            .padding(.horizontal, 20)
            .offset(y: -16)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriTheme.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 21)
            .padding(.top, 14)

            LazyVGrid(columns: columns, spacing: 11) {
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let summary = data.daySummary(for: date)

                        Button {
                            onDaySelected(date)
                        } label: {
                            WeekArchiveDayCell(
                                summary: summary,
                                today: today
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 60)
                            .accessibilityHidden(true)
                    }
                }
            }
            .padding(.horizontal, 21)
            .padding(.top, 14)

            WeekArchiveMonthLegend()
                .padding(.horizontal, 20)
                .padding(.top, 51)
        }
    }

    private var monthCells: [Date?] {
        LifeGridCalendar.cells(inMonthContaining: focusedMonth)
    }

    private var weekdaySymbols: [String] {
        LifeGridCalendar.weekdaySymbols
    }

    private func moveMonth(by value: Int) {
        focusedMonth = LifeGridCalendar.calendar.date(
            byAdding: .month,
            value: value,
            to: focusedMonth
        ) ?? focusedMonth
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = MoriLocalePreference.load().locale
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()
}

struct WeekArchiveYearGrid: View {
    @Binding var focusedYear: Int
    let data: WeekArchiveData
    let onMonthSelected: (Int) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 14),
        count: 4
    )

    var body: some View {
        VStack(spacing: 0) {
            LifeGridPeriodNavigator(
                title: String(focusedYear),
                previousLabel: MoriL10n.display("Previous year"),
                nextLabel: MoriL10n.display("Next year"),
                previousAction: { focusedYear -= 1 },
                nextAction: { focusedYear += 1 }
            )
            .padding(.horizontal, 20)

            LazyVGrid(columns: columns, alignment: .center, spacing: 21) {
                ForEach(1...12, id: \.self) { month in
                    LifeGridMiniMonth(
                        year: focusedYear,
                        month: month,
                        data: data,
                        action: { onMonthSelected(month) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            LifeGridYearSummaryPanel(
                daysRemembered: displayedDaysRemembered,
                quietMinutes: displayedQuietMinutes,
                tone: displayedTone
            )
            .padding(.horizontal, 20)
            .padding(.top, 53)
        }
    }

    private var displayedDaysRemembered: Int {
        return data.daysRemembered(inYear: focusedYear)
    }

    private var displayedQuietMinutes: Int {
        return data.quietMinutes(inYear: focusedYear)
    }

    private var displayedTone: HabitDayTone? {
        return data.mostCommonTone(inYear: focusedYear)
    }
}

private struct LifeGridPeriodNavigator: View {
    let title: String
    let previousLabel: String
    let nextLabel: String
    let previousAction: () -> Void
    let nextAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            navigationButton(
                systemName: "chevron.left",
                accessibilityLabel: previousLabel,
                action: previousAction
            )

            Text(MoriL10n.display(title))
                .font(.system(size: 22, weight: .regular, design: .serif))
                .foregroundColor(MoriTheme.Colors.ink)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            navigationButton(
                systemName: "chevron.right",
                accessibilityLabel: nextLabel,
                action: nextAction
            )
        }
        .frame(height: 44)
    }

    private func navigationButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MoriTheme.Colors.mutedText.opacity(0.78))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct WeekArchiveDayCell: View {
    let summary: WeekArchiveDaySummary
    let today: Date

    private var isToday: Bool {
        LifeGridCalendar.calendar.isDate(summary.date, inSameDayAs: today)
    }

    private var isFuture: Bool {
        summary.date > LifeGridCalendar.calendar.startOfDay(for: today)
    }

    private var dayNumber: Int {
        LifeGridCalendar.calendar.component(.day, from: summary.date)
    }

    private var tone: MoriMoodTone? {
        summary.habitEntry?.tone.lifeGridMoodTone
    }

    private var indicators: [MoriCalendarIndicator] {
        var values: [MoriCalendarIndicator] = []

        if summary.journalEntries.contains(where: { !$0.photoAttachments.isEmpty }) {
            values.append(.photo)
        }

        let habitNote = summary.habitEntry?.note?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if summary.dailySpark != nil || !summary.journalEntries.isEmpty || habitNote?.isEmpty == false {
            values.append(.note)
        }

        if summary.quietMinutes > 0 || !summary.sessions.isEmpty {
            values.append(.quiet)
        }

        return Array(values.prefix(2))
    }

    var body: some View {
        VStack(spacing: 7) {
            Text("\(dayNumber)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(MoriTheme.Colors.ink.opacity(isFuture ? 0.68 : 1))
                .monospacedDigit()

            HStack(spacing: 4) {
                ForEach(Array(indicators.enumerated()), id: \.offset) { _, indicator in
                    Circle()
                        .fill(indicatorColor(indicator))
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(fillColor)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(
                    isToday
                        ? MoriTheme.Colors.ink
                        : MoriTheme.Colors.hairline.opacity(0.38),
                    lineWidth: isToday ? 1.35 : 0.65
                )
        )
        .opacity(isFuture ? 0.66 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isToday ? .isSelected : [])
    }

    private var fillColor: Color {
        if isToday {
            return MoriTheme.Colors.raisedPaper.opacity(0.56)
        }

        if let tone {
            let strength: Double
            switch tone {
            case .good:
                switch indicators.count {
                case 2...: strength = 0.58
                case 1: strength = 0.24
                default: strength = 0.16
                }
            case .neutral:
                switch indicators.count {
                case 2...: strength = 0.46
                case 1: strength = 0.31
                default: strength = 0.19
                }
            case .difficult:
                switch indicators.count {
                case 2...: strength = 0.54
                case 1: strength = 0.41
                default: strength = 0.27
                }
            }
            return tone.color.opacity(strength)
        }

        if summary.hasRecords {
            return MoriTheme.Colors.sage.opacity(0.12)
        }

        return MoriTheme.Colors.noEntry.opacity(0.46)
    }

    private func indicatorColor(_ indicator: MoriCalendarIndicator) -> Color {
        switch indicator {
        case .note:
            return MoriTheme.Colors.ink.opacity(0.68)
        case .photo:
            return MoriTheme.Colors.raisedPaper.opacity(0.96)
        case .quiet:
            return MoriTheme.Colors.moss.opacity(0.78)
        }
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.locale = MoriLocalePreference.load().locale
        formatter.dateStyle = .medium
        let toneText = tone?.title ?? MoriL10n.display("No entry")
        let recordText = summary.hasRecords
            ? ", \(MoriL10n.display("records available"))"
            : ""
        return "\(formatter.string(from: summary.date)), \(toneText)\(recordText)"
    }
}

private struct WeekArchiveMonthLegend: View {
    var body: some View {
        HStack(spacing: 0) {
            legendItem(title: "Good", color: MoriTheme.Colors.good)
            legendItem(title: "Neutral", color: MoriTheme.Colors.neutral)
            legendItem(title: "Difficult", color: MoriTheme.Colors.difficult)
            legendItem(title: "No entry", color: MoriTheme.Colors.noEntry)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(color.opacity(title == "No entry" ? 0.86 : 0.88))
                .frame(width: 13, height: 13)
                .overlay {
                    if title == "No entry" {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(MoriTheme.Colors.hairline.opacity(0.72), lineWidth: 0.7)
                    }
                }

            Text(MoriL10n.display(title))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MoriTheme.Colors.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LifeGridMiniMonth: View {
    let year: Int
    let month: Int
    let data: WeekArchiveData
    let action: () -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 3),
        count: 7
    )

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(monthTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MoriTheme.Colors.ink)
                    .frame(maxWidth: .infinity)

                LazyVGrid(columns: columns, spacing: 3) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                        if let date {
                            miniDay(date)
                        } else {
                            Color.clear
                                .frame(height: 9.5)
                        }
                    }
                }
            }
            .frame(height: 108, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(MoriL10n.display("Show this month"))
    }

    private var monthDate: Date {
        LifeGridCalendar.calendar.date(
            from: DateComponents(year: year, month: month, day: 1)
        ) ?? Date()
    }

    private var cells: [Date?] {
        LifeGridCalendar.cells(inMonthContaining: monthDate)
    }

    private var monthTitle: String {
        Self.monthFormatter.string(from: monthDate)
    }

    @ViewBuilder
    private func miniDay(_ date: Date) -> some View {
        let summary = data.daySummary(for: date)
        let tone = summary.habitEntry?.tone.lifeGridMoodTone
        let day = LifeGridCalendar.calendar.component(.day, from: date)

        Text("\(day)")
            .font(.system(size: 4.4, weight: .semibold))
            .foregroundColor(MoriTheme.Colors.ink.opacity(0.66))
            .frame(maxWidth: .infinity)
            .frame(height: 9.5)
            .background(
                tone?.color.opacity(0.54)
                    ?? (summary.hasRecords
                        ? MoriTheme.Colors.sage.opacity(0.20)
                        : MoriTheme.Colors.noEntry.opacity(0.66))
            )
            .clipShape(RoundedRectangle(cornerRadius: 2.6, style: .continuous))
    }

    private var rememberedCount: Int {
        cells.compactMap { $0 }.filter { data.hasRecords(on: $0) }.count
    }

    private var accessibilityLabel: String {
        "\(monthTitle), \(rememberedCount) \(MoriL10n.display("days remembered"))"
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = MoriLocalePreference.load().locale
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter
    }()
}

private struct LifeGridYearSummaryPanel: View {
    let daysRemembered: Int
    let quietMinutes: Int
    let tone: HabitDayTone?

    var body: some View {
        HStack(spacing: 0) {
            metric(
                systemName: "calendar",
                title: "Days remembered",
                value: daysRemembered.formatted()
            )

            divider

            metric(
                systemName: "clock.arrow.circlepath",
                title: "Quiet minutes",
                value: quietMinutes.formatted()
            )

            divider

            metric(
                systemName: "face.smiling",
                title: "Most common tone",
                value: toneLabel
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 156)
        .background(MoriTheme.Colors.raisedPaper.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MoriTheme.Colors.hairline.opacity(0.62), lineWidth: 0.8)
        )
    }

    private func metric(
        systemName: String,
        title: String,
        value: String
    ) -> some View {
        VStack(spacing: 9) {
            Image(systemName: systemName)
                .font(.system(size: 23, weight: .light))
                .foregroundColor(MoriTheme.Colors.moss.opacity(0.72))
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            Text(MoriL10n.display(title))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(MoriTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 28, alignment: .top)

            Text(value)
                .font(.system(size: 24, weight: .light, design: .serif))
                .foregroundColor(MoriTheme.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var divider: some View {
        Rectangle()
            .fill(MoriTheme.Colors.hairline.opacity(0.72))
            .frame(width: 1, height: 112)
    }

    private var toneLabel: String {
        switch tone {
        case .positive:
            return MoriL10n.display("Calm")
        case .neutral:
            return MoriL10n.display("Neutral")
        case .negative:
            return MoriL10n.display("Difficult")
        case nil:
            return "—"
        }
    }
}

private enum LifeGridCalendar {
    static var calendar: Calendar {
        var value = Calendar.current
        value.firstWeekday = 2
        return value
    }

    static var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let mondayIndex = min(1, max(0, symbols.count - 1))
        return Array(symbols[mondayIndex...]) + Array(symbols[..<mondayIndex])
    }

    static func cells(inMonthContaining date: Date) -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: date),
              let dayRange = calendar.range(of: .day, in: .month, for: date) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        let days = dayRange.compactMap { day in
            calendar.date(bySetting: .day, value: day, of: interval.start)
        }

        return Array(repeating: nil, count: leadingBlanks) + days.map(Optional.some)
    }
}
