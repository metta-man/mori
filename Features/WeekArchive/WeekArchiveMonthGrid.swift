import SwiftUI

struct WeekArchiveMonthGrid: View {
    @Binding var focusedMonth: Date
    let data: WeekArchiveData
    let onDaySelected: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let startIndex = max(0, min(symbols.count - 1, calendar.firstWeekday - 1))
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Month",
                subtitle: "Each day is colored by its daily check-in tone."
            )

            PeriodNavigator(
                title: monthFormatter.string(from: focusedMonth),
                previousAction: { moveMonth(by: -1) },
                nextAction: { moveMonth(by: 1) }
            )

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(String(symbol.prefix(1)))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let summary = data.daySummary(for: date)
                        Button {
                            onDaySelected(date)
                        } label: {
                            WeekArchiveDayCell(summary: summary)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 46)
                    }
                }
            }
            .padding(16)
            .background(MoriColors.botanicalSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MoriColors.botanicalHairline, lineWidth: 1)
            )

            WeekArchiveMonthLegend()
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }

    private var monthCells: [Date?] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: focusedMonth),
              let dayRange = calendar.range(of: .day, in: .month, for: focusedMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        let days = dayRange.compactMap { day in
            calendar.date(bySetting: .day, value: day, of: interval.start)
        }

        return Array(repeating: nil, count: leadingBlanks) + days.map(Optional.some)
    }

    private func moveMonth(by value: Int) {
        focusedMonth = Calendar.current.date(byAdding: .month, value: value, to: focusedMonth) ?? focusedMonth
    }
}

private struct WeekArchiveDayCell: View {
    let summary: WeekArchiveDaySummary

    private var isToday: Bool {
        Calendar.current.isDateInToday(summary.date)
    }

    private var dayNumber: Int {
        Calendar.current.component(.day, from: summary.date)
    }

    private var tone: HabitDayTone? {
        summary.habitEntry?.tone
    }

    private var fillColor: Color {
        if let tone {
            return tone.color
        }

        return summary.hasRecords ? MoriColors.botanicalMoss.opacity(0.12) : MoriColors.botanicalPaperDeep.opacity(0.50)
    }

    private var dayNumberColor: Color {
        if tone != nil {
            return MoriColors.botanicalSurface
        }

        return summary.hasRecords ? MoriColors.botanicalInk : MoriColors.botanicalMuted
    }

    private func recordIndicatorColor(_ defaultColor: Color) -> Color {
        tone == nil ? defaultColor : MoriColors.botanicalSurface.opacity(0.88)
    }

    var body: some View {
        VStack(spacing: 5) {
            Text("\(dayNumber)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(dayNumberColor)
                .monospacedDigit()

            HStack(spacing: 3) {
                if summary.dailySpark != nil {
                    Circle()
                        .fill(recordIndicatorColor(MoriColors.botanicalSeed))
                        .frame(width: 5, height: 5)
                }
                if !summary.journalEntries.isEmpty {
                    Circle()
                        .fill(recordIndicatorColor(MoriColors.botanicalInk))
                        .frame(width: 5, height: 5)
                }
                if !summary.actions.isEmpty {
                    Circle()
                        .fill(recordIndicatorColor(MoriColors.botanicalMoss))
                        .frame(width: 5, height: 5)
                }
                if !summary.sessions.isEmpty || summary.quietMinutes > 0 {
                    Circle()
                        .fill(recordIndicatorColor(MoriColors.botanicalMist))
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(fillColor)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isToday ? MoriColors.botanicalInk : MoriColors.botanicalHairline, lineWidth: isToday ? 1.4 : 1)
        )
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let toneText = tone.map { "\($0.title) day" } ?? "No daily check-in"
        return summary.hasRecords ? "\(formatter.string(from: summary.date)), \(toneText), records available" : "\(formatter.string(from: summary.date)), \(toneText)"
    }
}

private struct WeekArchiveMonthLegend: View {
    var body: some View {
        FlowLayout(spacing: 10) {
            WeekArchiveLegendPill(title: "Good", color: HabitDayTone.positive.color)
            WeekArchiveLegendPill(title: "Neutral", color: HabitDayTone.neutral.color)
            WeekArchiveLegendPill(title: "Difficult", color: HabitDayTone.negative.color)
            WeekArchiveLegendPill(title: "No check-in", color: MoriColors.botanicalLine.opacity(0.58))
        }
    }
}
