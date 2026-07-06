import SwiftUI

struct MonthDaySelection: Identifiable {
    let id: String
    let date: Date
    let habitEntry: HabitEntry?
    let journalEntry: GratitudeEntry?

    init(date: Date, habitEntry: HabitEntry?, journalEntry: GratitudeEntry?) {
        self.date = date
        self.habitEntry = habitEntry
        self.journalEntry = journalEntry
        self.id = Self.id(for: date)
    }

    private static func id(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}

struct MonthDayDetailSheet: View {
    let selection: MonthDaySelection

    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    private var shouldShowJournalEntry: Bool {
        guard let journalEntry = selection.journalEntry else { return false }
        return selection.habitEntry == nil || journalEntry.sourceKind != .dayLog
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dateFormatter.string(from: selection.date))
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.botanicalInk)
                            .fixedSize(horizontal: false, vertical: true)

                        if let tone = selection.habitEntry?.tone {
                            WeekArchiveBitmapLabel(
                                title: MoriL10n.string(
                                    "habit.tone_day",
                                    defaultValue: "%@ day",
                                    arguments: [tone.title]
                                ),
                                icon: tone.weekArchiveIcon,
                                iconSize: 14,
                                iconOpacity: 0.84
                            )
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(tone.color)
                        }
                    }

                    if let habitEntry = selection.habitEntry, habitEntry.hasPatternLog {
                        PatternLogSummaryCard(entry: habitEntry)
                    }

                    if let habitEntry = selection.habitEntry,
                       let note = habitEntry.note?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !note.isEmpty {
                        HabitNoteSummaryCard(note: note)
                    }

                    if shouldShowJournalEntry, let journalEntry = selection.journalEntry {
                        JournalSummaryCard(entry: journalEntry)
                    }
                }
                .padding(24)
            }
            .background(MoriColors.botanicalPaper.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MoriColors.botanicalInk)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

extension HabitDayTone {
    var weekArchiveIcon: MoriBitmapIcon {
        switch self {
        case .positive: return .plus
        case .neutral: return .leaf
        case .negative: return .minus
        }
    }
}

struct PatternLogSummaryCard: View {
    let entry: HabitEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            WeekArchiveBitmapLabel(title: "Pattern Log", icon: .refresh, iconSize: 16, iconOpacity: 0.86)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.botanicalMoss)

            PatternLogRow(title: "Trigger", value: entry.trigger)
            PatternLogRow(title: "Thought", value: entry.thought)
            PatternLogRow(title: "Feeling", value: entry.feeling)
            PatternLogRow(title: "Next response", value: entry.responsePlan)
        }
        .padding(16)
        .background(MoriColors.botanicalSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.botanicalHairline, lineWidth: 1)
        )
    }
}

private struct PatternLogRow: View {
    let title: String
    let value: String?

    var body: some View {
        if let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalMuted)

                Text(MoriL10n.display(value))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.botanicalInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct HabitNoteSummaryCard: View {
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WeekArchiveBitmapLabel(title: "Day Note", icon: .journal, iconSize: 16, iconOpacity: 0.86)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.botanicalInk)

            Text(note)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(MoriColors.botanicalSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.botanicalHairline, lineWidth: 1)
        )
    }
}

private struct JournalSummaryCard: View {
    let entry: GratitudeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeekArchiveBitmapLabel(
                title: entry.sourceLabel,
                icon: entry.weekArchiveSourceIcon,
                iconSize: 16,
                iconOpacity: 0.86
            )
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.botanicalInk)

            Text(entry.displayContent)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(MoriColors.botanicalSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.botanicalHairline, lineWidth: 1)
        )
    }
}
