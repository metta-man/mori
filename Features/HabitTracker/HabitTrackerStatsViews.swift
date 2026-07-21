import SwiftUI

struct RecentDayPatternCard: View {
    let entries: [HabitEntry]
    let todayEntry: HabitEntry?

    private var toneSummary: String {
        guard let todayEntry else {
            return MoriL10n.display("No tone recorded today yet.")
        }

        return MoriL10n.string(
            "daily_review.today_recorded",
            defaultValue: "Today is marked %@.",
            arguments: [todayEntry.tone.title.lowercased()]
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MoriSectionTitle(
                title: "Recent day pattern",
                subtitle: "A quiet look at the last seven days."
            )

            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    let date = weekDate(offset: index)
                    let entry = entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
                    let isToday = Calendar.current.isDateInToday(date)

                    DayPatternDot(
                        date: date,
                        tone: entry?.tone,
                        isToday: isToday
                    )
                }
            }

            Text(toneSummary)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private func weekDate(offset: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -(6 - offset), to: today) ?? today
    }
}

private struct DayPatternDot: View {
    let date: Date
    let tone: HabitDayTone?
    let isToday: Bool

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(tone?.color ?? MoriColors.botanicalLine.opacity(0.35))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(isToday ? MoriColors.botanicalInk : .clear, lineWidth: 2)
                )
                .opacity(tone == nil ? 0.46 : 1)

            Text(dayLabel(for: date))
                .font(.system(size: 10, weight: isToday ? .semibold : .medium))
                .foregroundColor(isToday ? MoriColors.botanicalInk : MoriColors.botanicalMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let toneText = tone?.title ?? MoriL10n.display("No record")
        return "\(dayLabel(for: date)), \(toneText)"
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }
}
