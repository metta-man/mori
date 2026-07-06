import SwiftUI
import UIKit

// MARK: - Week Coordinate
struct WeekCoordinate: Equatable {
    let year: Int
    let week: Int

    var linearIndex: Int {
        year * 52 + week
    }
}

// MARK: - Week Detail Sheet
struct WeekArchiveReflectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let week: WeekCoordinate
    let settings: UserSettings
    let habitEntries: [HabitEntry]
    let journalEntries: [GratitudeEntry]

    init(
        week: WeekCoordinate,
        settings: UserSettings,
        habitEntries: [HabitEntry],
        journalEntries: [GratitudeEntry]
    ) {
        self.week = week
        self.settings = settings
        self.habitEntries = habitEntries
        self.journalEntries = journalEntries
    }

    @State private var memoryText: String = ""
    @State private var isEditing: Bool = false
    @State private var existingNote: String?
    @State private var weekID: UUID?
    @State private var showSaveSuccess: Bool = false

    private let store = WeekArchiveRecordStore.shared
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private var weekDate: Date {
        moriMondayWeekStart(for: week, archiveStartDate: settings.archiveStartDate)
    }

    private var dateRangeText: String {
        let start = weekDate
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekDate) ?? weekDate
        return "\(dateFormatter.string(from: start))-\(dateFormatter.string(from: end)), archive year \(week.year + 1)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Week info
                    VStack(spacing: 8) {
                        Text(MoriL10n.string(
                            "week_archive.week_archive_year",
                            defaultValue: "Week %d, Archive year %d",
                            arguments: [week.week + 1, week.year + 1]
                        ))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(MoriColors.botanicalInk)

                        Text(dateRangeText)
                            .font(.subheadline)
                            .foregroundColor(MoriColors.botanicalMuted)
                    }
                    .padding(.top)

                    if hasWeekActivity {
                        WeekArchiveActivitySection(
                            habitEntries: habitEntries,
                            journalEntries: journalEntries
                        )
                        .padding(.horizontal)
                    }

                    // Memory section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            MoriBitmapIconImage(icon: .journal, size: 17, opacity: 0.86)
                            Text("Memory from this week")
                                .font(.headline)
                                .foregroundColor(MoriColors.botanicalInk)
                            Spacer()
                            if existingNote != nil && !isEditing {
                                Button("Edit") {
                                    isEditing = true
                                }
                                .font(.subheadline)
                                .foregroundColor(MoriColors.botanicalInk)
                            }
                        }

                        if isEditing || existingNote == nil {
                            TextEditor(text: $memoryText)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(MoriColors.botanicalSurface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(MoriColors.botanicalHairline, lineWidth: 1)
                                )
                                .foregroundColor(MoriColors.botanicalInk)
                                .scrollContentBackground(.hidden)

                            Button(action: saveMemory) {
                                HStack {
                                    MoriBitmapIconImage(icon: .leaf, size: 17, opacity: memoryText.isEmpty ? 0.46 : 0.96)
                                    Text("Save Memory")
                                }
                                .font(.headline)
                                .foregroundColor(MoriColors.botanicalSurface)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(memoryText.isEmpty ? MoriColors.botanicalMuted.opacity(0.35) : MoriColors.botanicalInk)
                                .cornerRadius(12)
                            }
                            .disabled(memoryText.isEmpty)
                        } else {
                            Text(existingNote ?? "")
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundColor(MoriColors.botanicalInk)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(MoriColors.botanicalSurface)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // Reflection prompts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reflection prompts")
                            .font(.headline)
                            .foregroundColor(MoriColors.botanicalMuted)
                            .padding(.horizontal)

                        ForEach(reflectionPrompts, id: \.self) { prompt in
                            HStack(alignment: .top, spacing: 12) {
                                MoriBitmapIconImage(icon: .leaf, size: 16, opacity: 0.76)
                                Text(prompt)
                                    .font(.subheadline)
                                    .foregroundColor(MoriColors.botanicalMuted)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(MoriColors.botanicalPaper)
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
            .moriKeyboardDoneToolbar()
        }
        .presentationDetents([.large])
        .onAppear(perform: loadExistingNote)
    }

    private var reflectionPrompts: [String] {
        if week.year < 10 {
            return [
                "What surprised you this week?",
                "What did you learn for the first time?",
                "What made you feel light?"
            ]
        } else if week.year < 30 {
            return [
                "What did this week teach you?",
                "What was hard, and how did you meet it?",
                "What do you want next week to remember?"
            ]
        } else {
            return [
                "What are you most grateful for this week?",
                "Which moment deserves to be kept?",
                "What would you like to leave behind?"
            ]
        }
    }

    private func loadExistingNote() {
        let userID = WeekArchiveIdentityStore.shared.userID
        if let record = store.fetchRecord(userID: userID, yearIndex: week.year, weekIndex: week.week) {
            existingNote = record.note
            memoryText = record.note ?? ""
            weekID = record.id
        }
    }

    private func saveMemory() {
        dismissKeyboard()

        let userID = WeekArchiveIdentityStore.shared.userID

        let trimmed = memoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let id = weekID {
            store.updateNote(recordID: id, note: trimmed)
        } else {
            // Core Data still stores this through the original entity name for migration compatibility.
            let calendar = Calendar.current
            let startDate = moriMondayWeekStart(for: week, archiveStartDate: settings.archiveStartDate)
            let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate

            let newRecord = WeekArchiveRecord(
                weekIndex: week.week,
                yearIndex: week.year,
                weekOfYear: week.week + 1,
                startDate: startDate,
                endDate: endDate,
                isLived: week.year * 52 + week.week < settings.archiveWeeksElapsed,
                note: trimmed
            )
            store.saveRecord(newRecord, userID: userID)
        }

        existingNote = trimmed
        isEditing = false
        showSaveSuccess = true

        // Auto-dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }

    private func dismissKeyboard() {
        MoriKeyboardDismissAction.system()
    }

    private var hasWeekActivity: Bool {
        !habitEntries.isEmpty || !journalEntries.isEmpty
    }
}
