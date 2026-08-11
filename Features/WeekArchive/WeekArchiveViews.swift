import SwiftUI
import CoreData

private enum WeekArchiveSheet: Identifiable {
    case day(WeekArchiveDaySummary)

    var id: String {
        switch self {
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
    @State private var selectedMode: WeekArchiveDetailMode = .month
    @State private var focusedMonth: Date
    @State private var focusedYear: Int
    @State private var habitEntries: [HabitEntry] = []
    @State private var journalEntries: [GratitudeEntry] = []
    @State private var activeSheet: WeekArchiveSheet?
    @State private var showsWeeklyArchive = false

    private let lifeGridToday: Date

    init() {
        let initialDate = Self.initialLifeGridDate
        lifeGridToday = initialDate
        _focusedMonth = State(initialValue: initialDate)
        _focusedYear = State(initialValue: Calendar.current.component(.year, from: initialDate))
    }

    private var archiveData: WeekArchiveData {
        let data = WeekArchiveData(
            settings: settings,
            dailySparks: dailySparkStore.entries,
            journalEntries: journalEntries,
            actions: clarityStore.actions,
            sessions: settleStore.sessions,
            habitEntries: habitEntries,
            weeklyIntentions: settings.weeklyIntentions
        )

#if DEBUG
        if Self.usesLifeGridReferenceFixture {
            return data.addingLifeGridReferenceFixture()
        }
#endif

        return data
    }

    var body: some View {
        ZStack {
            MoriLandscapeBackground(
                scene: .none,
                placement: .lowerThird
            )
            .ignoresSafeArea()

            if selectedMode == .month {
                LifeGridMonthLandscape()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.opacity)
            }

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    LifeGridHeader(
                        isCompact: selectedMode == .year,
                        onBack: dismiss.callAsFunction,
                        onOpenWeeklyArchive: { showsWeeklyArchive = true }
                    )

                    LifeGridModePicker(selection: $selectedMode)

                    switch selectedMode {
                    case .month:
                        WeekArchiveMonthGrid(
                            focusedMonth: $focusedMonth,
                            data: archiveData,
                            today: lifeGridToday,
                            onDaySelected: { date in
                                activeSheet = .day(archiveData.daySummary(for: date))
                            }
                        )
                        .padding(.top, 46)

                    case .year:
                        WeekArchiveYearGrid(
                            focusedYear: $focusedYear,
                            data: archiveData,
                            onMonthSelected: openMonth
                        )
                        .padding(.top, 23)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .moriHidesMainTabBar()
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
        .sheet(isPresented: $showsWeeklyArchive) {
            WeekArchiveLegacyMapSheet(
                data: archiveData,
                settings: settings
            )
        }
    }

    @ViewBuilder
    private func activeSheetContent(_ sheet: WeekArchiveSheet) -> some View {
        switch sheet {
        case .day(let summary):
            WeekArchiveDayDetailSheet(
                summary: summary,
                onSaveDayLog: saveDayLog
            )
                .presentationDetents([.height(607), .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func saveDayLog(
        date: Date,
        tone: HabitDayTone,
        note: String?,
        photoAttachments: [GratitudePhotoAttachment]
    ) -> WeekArchiveDaySummary {
        let existingEntry = archiveData.daySummary(for: date).habitEntry

        _ = HabitDataManager.shared.saveEntry(
            on: date,
            tone: tone,
            note: note,
            trigger: existingEntry?.trigger,
            thought: existingEntry?.thought,
            feeling: existingEntry?.feeling,
            responsePlan: existingEntry?.responsePlan
        )

        GratitudeEntryStore.live.saveDayLogEntry(
            on: date,
            tone: tone,
            note: note,
            trigger: existingEntry?.trigger,
            thought: existingEntry?.thought,
            feeling: existingEntry?.feeling,
            responsePlan: existingEntry?.responsePlan,
            photoAttachments: photoAttachments
        )

        loadArchiveRecords()
        return archiveData.daySummary(for: date)
    }

    private func openMonth(_ month: Int) {
        let calendar = Calendar.current
        let date = calendar.date(
            from: DateComponents(year: focusedYear, month: month, day: 1)
        ) ?? focusedMonth

        focusedMonth = date
        withAnimation(MoriTheme.Animation.control) {
            selectedMode = .month
        }
    }

    private func loadArchiveRecords() {
        loadHabitEntries()
        loadJournalEntries()
    }

    private func loadHabitEntries() {
        habitEntries = HabitDataManager.shared.getEntries(
            from: settings.archiveStartDate,
            to: Date()
        )
    }

    private func loadJournalEntries() {
        journalEntries = GratitudeEntryStore.live.loadEntries()
    }

    private static var initialLifeGridDate: Date {
#if DEBUG
        if usesLifeGridReferenceFixture,
           let referenceDate = Calendar(identifier: .gregorian).date(
               from: DateComponents(year: 2026, month: 7, day: 17, hour: 12)
           ) {
            return referenceDate
        }
#endif

        return Date()
    }

#if DEBUG
    private static var usesLifeGridReferenceFixture: Bool {
        ProcessInfo.processInfo.arguments.contains("-MoriUseLifeGridReferenceFixtureForUITest")
    }
#endif
}

private struct LifeGridHeader: View {
    let isCompact: Bool
    let onBack: () -> Void
    let onOpenWeeklyArchive: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(MoriTheme.Colors.ink)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(MoriL10n.display("Back"))

                Spacer(minLength: 0)

                Menu {
                    Button(action: onOpenWeeklyArchive) {
                        Label(
                            MoriL10n.display("Weekly archive"),
                            systemImage: "square.grid.2x2"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(MoriTheme.Colors.ink)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(MoriL10n.display("Life Grid options"))
            }
            .frame(height: 44)
            .padding(.horizontal, 13)

            Text(MoriL10n.display("Life Grid"))
                .font(.system(size: isCompact ? 30 : 36, weight: .regular, design: .serif))
                .foregroundColor(MoriTheme.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.top, isCompact ? -11 : 3)
                .accessibilityAddTraits(.isHeader)

            Text(MoriL10n.display("See the shape of your days."))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriTheme.Colors.secondaryText)
                .padding(.top, isCompact ? 4 : 7)
        }
        .padding(.bottom, isCompact ? 26 : 33)
    }
}

private struct LifeGridMonthLandscape: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            Image("MoriDeepSessionForest")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .opacity(0.84)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .clear, location: 0.64),
                            .init(color: .white.opacity(0.34), location: 0.75),
                            .init(color: .white.opacity(0.90), location: 0.88),
                            .init(color: .white, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct LifeGridModePicker: View {
    @Binding var selection: WeekArchiveDetailMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(WeekArchiveDetailMode.allCases) { mode in
                Button {
                    withAnimation(MoriTheme.Animation.control) {
                        selection = mode
                    }
                } label: {
                    Text(mode.title)
                        .font(.system(size: 14, weight: selection == mode ? .semibold : .regular))
                        .foregroundColor(MoriTheme.Colors.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if selection == mode {
                                Capsule(style: .continuous)
                                    .fill(MoriTheme.Colors.raisedPaper.opacity(0.96))
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(MoriTheme.Colors.hairline, lineWidth: 0.7)
                                    )
                                    .shadow(
                                        color: MoriTheme.Colors.shadow.opacity(0.62),
                                        radius: 4,
                                        y: 2
                                    )
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == mode ? .isSelected : [])
            }
        }
        .padding(2)
        .frame(height: 44)
        .background(MoriTheme.Colors.noEntry.opacity(0.42))
        .clipShape(Capsule(style: .continuous))
        .padding(.horizontal, 36)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(MoriL10n.display("Life Grid view"))
    }
}

private struct WeekArchiveLegacyMapSheet: View {
    @Environment(\.dismiss) private var dismiss

    let data: WeekArchiveData
    let settings: UserSettings

    @State private var selectedWeek: WeekArchiveWeekSummary?

    var body: some View {
        NavigationStack {
            MoriRootScrollScreen(
                title: "Weekly archive",
                subtitle: "Return to earlier weeks when you choose.",
                backgroundVariant: .roots
            ) {
                Button(MoriL10n.display("Done")) {
                    dismiss()
                }
                .font(MoriTheme.Typography.control)
                .foregroundColor(MoriTheme.Colors.ink)
                .frame(minHeight: MoriTheme.Spacing.minimumHitTarget)
            } content: {
                WeekArchiveWeekGrid(
                    settings: settings,
                    recordedWeekIndexes: data.recordedWeekIndexes,
                    onWeekSelected: { coordinate in
                        selectedWeek = data.weekSummary(for: coordinate)
                    }
                )
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedWeek) { summary in
                WeekArchiveWeekDetailSheet(summary: summary, settings: settings)
            }
        }
    }
}
