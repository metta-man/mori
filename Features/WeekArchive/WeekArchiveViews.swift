import SwiftUI
import CoreData

private enum WeekArchiveSheet: Identifiable {
    case week(WeekArchiveWeekSummary)
    case day(WeekArchiveDaySummary)

    var id: String {
        switch self {
        case .week(let summary):
            return "week-\(summary.id)"
        case .day(let summary):
            return "day-\(summary.id)"
        }
    }
}

struct WeekArchiveDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: UserSettings
    @StateObject private var clarityStore = MoriClarityStore.shared
    @StateObject private var dailySparkStore = DailySparkStore.shared
    @StateObject private var settleStore = SettleSessionStore.shared
    @State private var selectedMode: WeekArchiveDetailMode = .week
    @State private var focusedMonth = Date()
    @State private var habitEntries: [HabitEntry] = []
    @State private var journalEntries: [GratitudeEntry] = []
    @State private var activeSheet: WeekArchiveSheet?

    private var archiveData: WeekArchiveData {
        WeekArchiveData(
            settings: settings,
            dailySparks: dailySparkStore.entries,
            journalEntries: journalEntries,
            actions: clarityStore.actions,
            sessions: settleStore.sessions,
            habitEntries: habitEntries,
            weeklyIntentions: settings.weeklyIntentions
        )
    }

    var body: some View {
        MoriRootScrollScreen(
            title: "Weeks",
            subtitle: "Review the weeks and days in your archive.",
            backgroundVariant: .roots
        ) {
            Button(action: dismiss.callAsFunction) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoriV2Palette.forestInk)

                    Text("Back")
                        .font(MoriV2Type.control)
                        .foregroundColor(MoriV2Palette.forestInk)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: MoriV2Layout.minimumHitTarget)
                .background(MoriColors.sanctuarySurface.opacity(0.78))
                .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(MoriV2PressButtonStyle())
            .accessibilityLabel("Back")
        } content: {
            Picker("Week archive detail view", selection: $selectedMode) {
                ForEach(WeekArchiveDetailMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(MoriColors.botanicalInk)

            switch selectedMode {
            case .week:
                WeekArchiveWeekGrid(
                    settings: settings,
                    recordedWeekIndexes: archiveData.recordedWeekIndexes,
                    onWeekSelected: { coordinate in
                        activeSheet = .week(archiveData.weekSummary(for: coordinate))
                    }
                )
            case .month:
                WeekArchiveMonthGrid(
                    focusedMonth: $focusedMonth,
                    data: archiveData,
                    onDaySelected: { date in
                        activeSheet = .day(archiveData.daySummary(for: date))
                    }
                )
            }
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            AnalyticsManager.shared.trackWeekArchiveViewed()
            loadArchiveRecords()
        }
        .onMoriDataChange(.habit, perform: loadHabitEntries)
        .onMoriDataChange(.gratitude, perform: loadJournalEntries)
        .onMoriDataChange(.dailySpark, perform: loadJournalEntries)
        .sheet(item: $activeSheet) { sheet in
            activeSheetContent(sheet)
        }
    }

    @ViewBuilder
    private func activeSheetContent(_ sheet: WeekArchiveSheet) -> some View {
        switch sheet {
        case .week(let summary):
            WeekArchiveWeekDetailSheet(summary: summary, settings: settings)
        case .day(let summary):
            WeekArchiveDayDetailSheet(summary: summary)
        }
    }

    private func loadArchiveRecords() {
        loadHabitEntries()
        loadJournalEntries()
    }

    private func loadHabitEntries() {
        habitEntries = HabitDataManager.shared.getEntries(from: settings.archiveStartDate, to: Date())
    }

    private func loadJournalEntries() {
        journalEntries = GratitudeEntryStore.live.loadEntries()
    }
}
