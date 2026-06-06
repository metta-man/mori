import SwiftUI

// MARK: - Habit Tracker View
/// Daily quality tracking with + / - buttons
struct HabitTrackerView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var todayEntry: HabitEntry?
    @State private var streak: HabitStreak
    @State private var weeklyData: [HabitEntry] = []
    @State private var monthlyStats: MonthlyStats
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showSettings = false
    @State private var showPatternLog = false
    @State private var showLogbook = false
    @State private var patternLogTone: HabitDayTone = .neutral

    init() {
        _streak = State(initialValue: HabitStreak(currentStreak: 0, longestStreak: 0, lastWeekTrend: .stable))
        _monthlyStats = State(initialValue: MonthlyStats(
            month: Date(),
            positiveDays: 0,
            neutralDays: 0,
            negativeDays: 0,
            bestStreak: 0,
            trend: .stable
        ))
    }

    var body: some View {
        NavigationStack {
            MoriForestBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        MoriPageHeader(
                            eyebrow: "Daily Check-In",
                            title: "Daily Check-In",
                            subtitle: "Mark the tone of today. Small records become a clearer memory."
                        )

                        HStack(spacing: 14) {
                            HabitButton(
                                type: .positive,
                                isSelected: todayEntry?.tone == .positive
                            ) {
                                selectEntry(tone: .positive)
                            }

                            HabitButton(
                                type: .neutral,
                                isSelected: todayEntry?.tone == .neutral
                            ) {
                                selectEntry(tone: .neutral)
                            }

                            HabitButton(
                                type: .negative,
                                isSelected: todayEntry?.tone == .negative
                            ) {
                                selectEntry(tone: .negative)
                            }
                        }
                        .padding(.vertical, 4)

                        StreakCard(streak: streak)

                        WeekVisualization(entries: weeklyData)

                        MonthlyStatsCard(stats: monthlyStats)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                }
            }
            .navigationTitle("Mori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            openPatternLog()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(MoriColors.forestCanopy.opacity(0.82))
                        }
                        .accessibility(label: Text("Open pattern log"))

                        Button {
                            showLogbook = true
                        } label: {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(MoriColors.forestCanopy.opacity(0.82))
                        }
                        .accessibility(label: Text("Log a previous day"))

                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundColor(MoriColors.forestCanopy.opacity(0.82))
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showLogbook) {
                LogbookEntrySheet { date, tone, note, trigger, thought, feeling, responsePlan, journalText, photoAttachments in
                    saveBackdatedEntry(
                        date: date,
                        tone: tone,
                        note: note,
                        trigger: trigger,
                        thought: thought,
                        feeling: feeling,
                        responsePlan: responsePlan,
                        journalText: journalText,
                        photoAttachments: photoAttachments
                    )
                }
            }
            .sheet(isPresented: $showPatternLog) {
                PatternLogSheet(
                    existingEntry: todayEntry,
                    initialTone: patternLogTone,
                    onSave: { tone, trigger, thought, feeling, responsePlan in
                        saveTone(
                            tone,
                            note: PatternLogSheet.summary(
                                trigger: trigger,
                                thought: thought,
                                feeling: feeling,
                                responsePlan: responsePlan
                            ),
                            trigger: trigger,
                            thought: thought,
                            feeling: feeling,
                            responsePlan: responsePlan
                        )
                    }
                )
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    Text(toastMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MoriColors.forestCard)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(MoriColors.forestCanopy)
                        .cornerRadius(8)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: showToast)
                }
            }
            .onAppear {
                loadData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .habitDataDidChange)) { _ in
                loadData()
            }
        }
    }

    private func loadData() {
        // Load today's entry
        todayEntry = HabitDataManager.shared.getTodayEntry()

        // Load weekly data
        weeklyData = HabitDataManager.shared.getWeeklyEntries()

        // Load streak
        streak = HabitDataManager.shared.getStreak()

        // Load monthly stats
        monthlyStats = HabitDataManager.shared.getMonthlyStats()
    }

    private func selectEntry(tone: HabitDayTone) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if tone == .negative {
            patternLogTone = tone
            showPatternLog = true
            return
        }

        saveTone(tone)
    }

    private func openPatternLog() {
        patternLogTone = todayEntry?.tone ?? .neutral
        showPatternLog = true
    }

    private func saveTone(
        _ tone: HabitDayTone,
        note: String? = nil,
        trigger: String? = nil,
        thought: String? = nil,
        feeling: String? = nil,
        responsePlan: String? = nil
    ) {
        // Save entry
        let entry = HabitDataManager.shared.saveEntry(
            tone: tone,
            note: note,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan
        )

        // Update local state
        todayEntry = entry

        // Reload data
        streak = HabitDataManager.shared.getStreak()
        weeklyData = HabitDataManager.shared.getWeeklyEntries()
        monthlyStats = HabitDataManager.shared.getMonthlyStats()

        let action = MoriClarityStore.shared.recordDailyOnce(
            kind: .dailyFocus,
            title: MoriPractice.dailyCheckIn.title,
            seeds: MoriPractice.dailyCheckIn.seeds,
            minutes: MoriPractice.dailyCheckIn.minutes,
            note: MoriPractice.dailyCheckIn.note
        )

        // Show toast
        if let action {
            toastMessage = "\(tone.toastMessage) · +\(action.seeds) Seeds"
        } else {
            toastMessage = tone.toastMessage
        }
        showToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }

    private func saveBackdatedEntry(
        date: Date,
        tone: HabitDayTone,
        note: String?,
        trigger: String?,
        thought: String?,
        feeling: String?,
        responsePlan: String?,
        journalText: String?,
        photoAttachments: [GratitudePhotoAttachment]
    ) {
        _ = HabitDataManager.shared.saveEntry(
            on: date,
            tone: tone,
            note: note,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan
        )

        let dayLogPhotos = journalText == nil ? photoAttachments : []
        GratitudeEntry.saveDayLogEntry(
            on: date,
            tone: tone,
            note: note,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan,
            photoAttachments: dayLogPhotos
        )

        if let journalText {
            _ = GratitudeEntry.saveJournalEntry(
                on: date,
                content: journalText,
                promptType: .moment,
                photoAttachments: photoAttachments
            )
        }

        if Calendar.current.isDateInToday(date) {
            MoriClarityStore.shared.recordDailyOnce(
                kind: .dailyFocus,
                title: MoriPractice.dailyCheckIn.title,
                seeds: MoriPractice.dailyCheckIn.seeds,
                minutes: MoriPractice.dailyCheckIn.minutes,
                note: MoriPractice.dailyCheckIn.note
            )
        }

        loadData()
        toastMessage = "Previous day logged"
        showToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
}

private struct PatternLogSheet: View {
    let existingEntry: HabitEntry?
    let onSave: (HabitDayTone, String, String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTone: HabitDayTone
    @State private var trigger: String
    @State private var thought: String
    @State private var feeling: String
    @State private var responsePlan: String

    init(
        existingEntry: HabitEntry?,
        initialTone: HabitDayTone,
        onSave: @escaping (HabitDayTone, String, String, String, String) -> Void
    ) {
        self.existingEntry = existingEntry
        self.onSave = onSave
        _selectedTone = State(initialValue: initialTone)
        _trigger = State(initialValue: existingEntry?.trigger ?? "")
        _thought = State(initialValue: existingEntry?.thought ?? "")
        _feeling = State(initialValue: existingEntry?.feeling ?? "")
        _responsePlan = State(initialValue: existingEntry?.responsePlan ?? "")
    }

    var body: some View {
        NavigationStack {
            MoriForestBackground {
                ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pattern Log")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.forestCanopy)

                        Text("Notice the loop, then choose the next small move.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(MoriColors.forestMuted)
                    }

                    Picker("Day tone", selection: $selectedTone) {
                        ForEach(HabitDayTone.allCases) { tone in
                            Text(tone.title).tag(tone)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(MoriColors.forestMoss)

                    PatternLogField(
                        title: "Trigger",
                        placeholder: "What set it off?",
                        text: $trigger
                    )

                    PatternLogField(
                        title: "Thought",
                        placeholder: "What did your mind say?",
                        text: $thought
                    )

                    PatternLogField(
                        title: "Feeling",
                        placeholder: "Name the feeling or body signal.",
                        text: $feeling
                    )

                    PatternLogField(
                        title: "Next response",
                        placeholder: "If this shows up again, I will...",
                        text: $responsePlan
                    )

                    Button(action: save) {
                        Label("Save pattern log", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(MoriColors.forestCard)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(MoriColors.forestCanopy)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: save)
                        .foregroundColor(MoriColors.forestCanopy)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func save() {
        onSave(selectedTone, trigger, thought, feeling, responsePlan)
        dismiss()
    }

    static func summary(
        trigger: String,
        thought: String,
        feeling: String,
        responsePlan: String
    ) -> String? {
        let rows = [
            ("Trigger", trigger),
            ("Thought", thought),
            ("Feeling", feeling),
            ("Next response", responsePlan)
        ]
            .map { label, value in (label, value.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.1.isEmpty }

        guard !rows.isEmpty else { return nil }
        return rows.map { "\($0.0): \($0.1)" }.joined(separator: "\n")
    }
}

private struct PatternLogField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.forestMuted)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted.opacity(0.72))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                }

                TextEditor(text: $text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.forestCanopy)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 74)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .background(MoriColors.forestPaperDeep.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MoriColors.forestLine.opacity(0.55), lineWidth: 1)
            )
        }
    }
}

// MARK: - Habit Button
struct HabitButton: View {
    enum ButtonType {
        case positive
        case neutral
        case negative

        var symbol: String {
            switch self {
            case .positive: return "plus"
            case .neutral: return "equal"
            case .negative: return "minus"
            }
        }

        var label: String {
            switch self {
            case .positive: return "Good day"
            case .neutral: return "Neutral day"
            case .negative: return "Difficult day"
            }
        }

        var color: Color {
            switch self {
            case .positive: return HabitDayTone.positive.color
            case .neutral: return HabitDayTone.neutral.color
            case .negative: return HabitDayTone.negative.color
            }
        }

        var backgroundColor: Color {
            switch self {
            case .positive: return Color(hex: "#F0F5EB")
            case .neutral: return Color(hex: "#F5F1E8")
            case .negative: return Color(hex: "#FFF5F0")
            }
        }
    }

    let type: ButtonType
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                }
                action()
            }) {
                ZStack {
                    Circle()
                        .stroke(type.color, lineWidth: 2)
                        .background(
                            Circle()
                                .fill(isSelected ? type.color : MoriColors.forestCard)
                        )
                        .frame(width: 54, height: 54)

                    Image(systemName: type.symbol)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? MoriColors.forestCard : type.color)
                }
                .scaleEffect(isPressed ? 1.1 : (isSelected ? 1.05 : 1.0))
                .shadow(color: isSelected ? type.color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())

            Text(type.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MoriColors.forestMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(isSelected ? type.color.opacity(0.12) : MoriColors.forestCard.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? type.color.opacity(0.45) : MoriColors.forestHairline, lineWidth: 1)
        )
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    let streak: HabitStreak

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current Streak")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MoriColors.forestCanopy)

                Spacer()

                HStack(spacing: 4) {
                    Text("\(streak.currentStreak)")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestSeed)
                    Text("days")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)

                    if streak.currentStreak >= 7 {
                        Text("🔥")
                            .font(.system(size: 20))
                    }
                }
            }

            HStack {
                Text("Longest Streak")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)

                Spacer()

                Text("\(streak.longestStreak) days")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

// MARK: - Week Visualization
struct WeekVisualization: View {
    let entries: [HabitEntry]

    var body: some View {
        VStack(spacing: 16) {
            Text("Last 7 Days")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MoriColors.forestMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    let date = getWeekDate(offset: index)
                    let entry = entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
                    let isToday = Calendar.current.isDateInToday(date)

                    VStack(spacing: 8) {
                        Circle()
                            .fill(entry?.tone.color ?? HabitDayTone.neutral.color.opacity(0.35))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(isToday ? MoriColors.forestCanopy : .clear, lineWidth: 2)
                            )
                            .opacity(isToday ? 1 : 0.7)

                        Text(dayLabel(for: date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(MoriColors.forestMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private func getWeekDate(offset: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -(6 - offset), to: today) ?? today
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }
}

// MARK: - Monthly Stats Card
struct MonthlyStatsCard: View {
    let stats: MonthlyStats

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: stats.month)
    }

    private var percentage: Int {
        let total = stats.positiveDays + stats.neutralDays + stats.negativeDays
        guard total > 0 else { return 0 }
        return Int((Double(stats.positiveDays) / Double(total)) * 100)
    }

    private var trendText: String {
        switch stats.trend {
        case .improving: return "Improving"
        case .declining: return "Declining"
        case .stable: return "Stable"
        }
    }

    private var trendIcon: String {
        switch stats.trend {
        case .improving: return "↑"
        case .declining: return "↓"
        case .stable: return "→"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundColor(MoriColors.forestMoss)
                Text(monthString)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.forestCanopy)
                Spacer()
            }

            Divider()
                .background(MoriColors.forestLine.opacity(0.58))

            StatRow(label: "Good days", value: "\(stats.positiveDays) (\(percentage)%)", valueColor: HabitDayTone.positive.color)
            StatRow(label: "Neutral days", value: "\(stats.neutralDays)", valueColor: HabitDayTone.neutral.color)
            StatRow(label: "Bad days", value: "\(stats.negativeDays)", valueColor: HabitDayTone.negative.color)
            StatRow(label: "Best streak", value: "\(stats.bestStreak) days", valueColor: MoriColors.forestCanopy)

            HStack {
                Text("Trend")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
                Spacer()
                HStack(spacing: 4) {
                    Text(trendIcon)
                    Text(trendText)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(trendColor)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var trendColor: Color {
        switch stats.trend {
        case .improving: return HabitDayTone.positive.color
        case .declining: return HabitDayTone.negative.color
        case .stable: return MoriColors.forestMuted
        }
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let label: String
    let value: String
    var valueColor: Color = MoriColors.forestCanopy

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Preview
#Preview {
    HabitTrackerView()
        .environmentObject(UserSettings())
}

extension HabitDayTone {
    var color: Color {
        switch self {
        case .positive: return MoriColors.forestMoss
        case .neutral: return MoriColors.forestSeed
        case .negative: return MoriColors.forestClay
        }
    }

    var mutedColor: Color {
        color.opacity(0.42)
    }

    var title: String {
        switch self {
        case .positive: return "Good"
        case .neutral: return "Neutral"
        case .negative: return "Difficult"
        }
    }

    var toastMessage: String {
        switch self {
        case .positive: return "Recorded as a good day"
        case .neutral: return "Recorded as a neutral day"
        case .negative: return "Recorded as a difficult day"
        }
    }
}
