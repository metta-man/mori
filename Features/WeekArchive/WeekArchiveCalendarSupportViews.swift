import SwiftUI

struct PeriodNavigator: View {
    let title: String
    let previousAction: () -> Void
    let nextAction: () -> Void

    var body: some View {
        HStack {
            Button(action: previousAction) {
                MoriBitmapIconImage(icon: .chevron, size: 14, opacity: 0.88)
                    .rotationEffect(.degrees(180))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .foregroundColor(MoriColors.botanicalInk)

            Text(MoriL10n.display(title))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.botanicalInk)
                .frame(maxWidth: .infinity)

            Button(action: nextAction) {
                MoriBitmapIconImage(icon: .chevron, size: 14, opacity: 0.88)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .foregroundColor(MoriColors.botanicalInk)
        }
    }
}

struct DayToneSquare: View {
    let date: Date
    let tone: HabitDayTone?
    let size: CGFloat
    var hasJournal: Bool = false
    var hasPatternLog: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: min(7, size * 0.22), style: .continuous)
            .fill(tone?.color ?? MoriColors.botanicalPaperDeep.opacity(0.60))
            .frame(height: size)
            .overlay(
                RoundedRectangle(cornerRadius: min(7, size * 0.22), style: .continuous)
                    .stroke(isToday ? MoriColors.botanicalInk : MoriColors.botanicalHairline, lineWidth: isToday ? 1.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if hasJournal {
                    Circle()
                        .fill(indicatorColor(defaultColor: MoriColors.botanicalInk))
                        .frame(width: max(4, size * 0.18), height: max(4, size * 0.18))
                        .padding(max(2, size * 0.08))
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if hasPatternLog {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(indicatorColor(defaultColor: MoriColors.botanicalSeed))
                        .frame(width: max(8, size * 0.28), height: max(3, size * 0.1))
                        .padding(max(2, size * 0.08))
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel(accessibilityLabel)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private func indicatorColor(defaultColor: Color) -> Color {
        tone == nil ? defaultColor : MoriColors.botanicalSurface.opacity(0.88)
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let toneText = tone?.title ?? "No check-in"
        let journalText = hasJournal ? ", \(MoriL10n.display("log entry available"))" : ""
        let patternText = hasPatternLog ? ", pattern log available" : ""
        return "\(formatter.string(from: date)), \(toneText)\(journalText)\(patternText)"
    }
}

struct MonthGridLegend: View {
    var body: some View {
        FlowLayout(spacing: 10) {
            WeekArchiveLegendPill(title: "Good", color: HabitDayTone.positive.color)
            WeekArchiveLegendPill(title: "Neutral", color: HabitDayTone.neutral.color)
            WeekArchiveLegendPill(title: "Difficult", color: HabitDayTone.negative.color)
            WeekArchiveLegendPill(title: "Log dot", color: MoriColors.botanicalInk)
            WeekArchiveLegendPill(title: "Pattern bar", color: MoriColors.botanicalSeed)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(MoriColors.botanicalMuted)
        .padding(.horizontal, 2)
    }
}

func preferredJournalEntry(
    on date: Date,
    in entries: [GratitudeEntry],
    calendar: Calendar
) -> GratitudeEntry? {
    entries
        .filter { calendar.isDate($0.date, inSameDayAs: date) }
        .sorted { lhs, rhs in
            let lhsPriority = journalEntryPriority(lhs)
            let rhsPriority = journalEntryPriority(rhs)

            if lhsPriority != rhsPriority {
                return lhsPriority < rhsPriority
            }

            return lhs.updatedAt > rhs.updatedAt
        }
        .first
}

private func journalEntryPriority(_ entry: GratitudeEntry) -> Int {
    switch entry.sourceKind {
    case .journal: return 0
    case .dayLog: return 1
    case .dailySpark: return 2
    case .weeklyIntention: return 3
    }
}
