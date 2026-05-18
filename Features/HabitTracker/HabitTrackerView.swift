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
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 10) {
                        Text("Daily Check-In")
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.moriCream)

                        Text("Mark the tone of today. Small records become a clearer memory.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(MoriColors.moriCreamMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    
                    // Habit buttons
                    HStack(spacing: 22) {
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
                    .padding(.vertical, 16)
                    
                    // Streak card
                    StreakCard(streak: streak)
                        .padding(.horizontal, 24)
                    
                    // Week visualization
                    WeekVisualization(entries: weeklyData)
                        .padding(.horizontal, 24)
                    
                    // Monthly stats
                    MonthlyStatsCard(stats: monthlyStats)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
            }
            .background(MoriColors.moriDark.ignoresSafeArea())
            .navigationTitle("Mori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(MoriColors.moriDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(MoriColors.moriGold.opacity(0.8))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showPatternLog) {
                PatternLogSheet(
                    existingEntry: todayEntry,
                    onSave: { trigger, thought, feeling, responsePlan in
                        saveTone(
                            .negative,
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
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(MoriColors.warmCharcoal)
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
            showPatternLog = true
            return
        }

        saveTone(tone)
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

        // Show toast
        toastMessage = tone.toastMessage
        showToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
}

private struct PatternLogSheet: View {
    let existingEntry: HabitEntry?
    let onSave: (String, String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var trigger: String
    @State private var thought: String
    @State private var feeling: String
    @State private var responsePlan: String

    init(
        existingEntry: HabitEntry?,
        onSave: @escaping (String, String, String, String) -> Void
    ) {
        self.existingEntry = existingEntry
        self.onSave = onSave
        _trigger = State(initialValue: existingEntry?.trigger ?? "")
        _thought = State(initialValue: existingEntry?.thought ?? "")
        _feeling = State(initialValue: existingEntry?.feeling ?? "")
        _responsePlan = State(initialValue: existingEntry?.responsePlan ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pattern Log")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.moriCream)

                        Text("Notice the loop, then choose the next small move.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(MoriColors.moriCreamMuted)
                    }

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
                            .foregroundColor(MoriColors.moriDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(MoriColors.moriGold)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(24)
            }
            .background(MoriColors.moriDark.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(MoriColors.moriDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: save)
                        .foregroundColor(MoriColors.moriGold)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func save() {
        onSave(trigger, thought, feeling, responsePlan)
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
                .foregroundColor(MoriColors.moriCreamMuted)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.moriCreamMuted.opacity(0.76))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                }

                TextEditor(text: $text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.moriCream)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 74)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .background(MoriColors.moriDarkSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MoriColors.moriHairline, lineWidth: 1)
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
                                .fill(isSelected ? type.color : Color.white)
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: type.symbol)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .white : type.color)
                }
                .scaleEffect(isPressed ? 1.1 : (isSelected ? 1.05 : 1.0))
                .shadow(color: isSelected ? type.color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(type.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MoriColors.moriCreamMuted)
        }
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
                    .foregroundColor(MoriColors.moriCream)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(streak.currentStreak)")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.moriGold)
                    Text("days")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.moriCreamMuted)
                    
                    if streak.currentStreak >= 7 {
                        Text("🔥")
                            .font(.system(size: 20))
                    }
                }
            }
            
            HStack {
                Text("Longest Streak")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.moriCreamMuted)
                
                Spacer()
                
                Text("\(streak.longestStreak) days")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.moriCreamMuted)
            }
        }
        .padding(24)
        .background(MoriColors.moriDarkSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MoriColors.moriHairline, lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

// MARK: - Week Visualization
struct WeekVisualization: View {
    let entries: [HabitEntry]
    
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Last 7 Days")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MoriColors.moriCreamMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    let entry = entries.first { Calendar.current.isDate($0.date, inSameDayAs: getWeekDate(offset: index)) }
                    let isToday = index == 6
                    
                    VStack(spacing: 8) {
                        Circle()
                            .fill(entry?.tone.color ?? HabitDayTone.neutral.color.opacity(0.35))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(isToday ? MoriColors.accentAmber : .clear, lineWidth: 2)
                            )
                            .opacity(isToday ? 1 : 0.7)
                        
                        Text(dayLabels[index])
                            .font(.custom("Poppins-Regular", size: 10))
                            .foregroundColor(MoriColors.moriCreamMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(24)
        .background(MoriColors.moriDarkSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MoriColors.moriHairline, lineWidth: 1)
        )
        .cornerRadius(16)
    }
    
    private func getWeekDate(offset: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -(6 - offset), to: today) ?? today
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
                    .foregroundColor(MoriColors.secondary)
                Text(monthString)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.moriCream)
                Spacer()
            }
            
            Divider()
            
            StatRow(label: "Good days", value: "\(stats.positiveDays) (\(percentage)%)", valueColor: HabitDayTone.positive.color)
            StatRow(label: "Neutral days", value: "\(stats.neutralDays)", valueColor: HabitDayTone.neutral.color)
            StatRow(label: "Bad days", value: "\(stats.negativeDays)", valueColor: HabitDayTone.negative.color)
            StatRow(label: "Best streak", value: "\(stats.bestStreak) days", valueColor: MoriColors.text)
            
            HStack {
                Text("Trend")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(MoriColors.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Text(trendIcon)
                    Text(trendText)
                }
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(trendColor)
            }
        }
        .padding(24)
        .background(MoriColors.moriDarkSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MoriColors.moriHairline, lineWidth: 1)
        )
        .cornerRadius(16)
    }
    
    private var trendColor: Color {
        switch stats.trend {
        case .improving: return HabitDayTone.positive.color
        case .declining: return HabitDayTone.negative.color
        case .stable: return MoriColors.secondary
        }
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let label: String
    let value: String
    var valueColor: Color = MoriColors.text
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriColors.moriCreamMuted)
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
        case .positive: return Color(hex: "#788C5D")
        case .neutral: return MoriColors.morningGold
        case .negative: return Color(hex: "#FF6B35")
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
