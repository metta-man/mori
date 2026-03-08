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
    
    init() {
        _streak = State(initialValue: HabitStreak(currentStreak: 0, longestStreak: 0, lastWeekTrend: .stable))
        _monthlyStats = State(initialValue: MonthlyStats(
            month: Date(),
            positiveDays: 0,
            negativeDays: 0,
            bestStreak: 0,
            trend: .stable
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Title
                    Text("How was your day?")
                        .font(.custom("CormorantGaramond-Regular", size: 36))
                        .foregroundColor(MoriColors.text)
                        .padding(.top, 32)
                    
                    // Habit buttons
                    HStack(spacing: 48) {
                        HabitButton(
                            type: .positive,
                            isSelected: todayEntry?.isPositive == true
                        ) {
                            selectEntry(isPositive: true)
                        }
                        
                        HabitButton(
                            type: .negative,
                            isSelected: todayEntry?.isPositive == false
                        ) {
                            selectEntry(isPositive: false)
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
            .background(MoriColors.background.ignoresSafeArea())
            .navigationTitle("Mori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(MoriColors.secondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                HabitSettingsSheet(isPresented: $showSettings)
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    Text(toastMessage)
                        .font(.custom("Poppins-Regular", size: 14))
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
    
    private func selectEntry(isPositive: Bool) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Save entry
        let entry = HabitDataManager.shared.saveEntry(isPositive: isPositive)
        
        // Update local state
        todayEntry = entry
        
        // Reload data
        streak = HabitDataManager.shared.getStreak()
        weeklyData = HabitDataManager.shared.getWeeklyEntries()
        monthlyStats = HabitDataManager.shared.getMonthlyStats()
        
        // Show toast
        toastMessage = isPositive ? "Day recorded as good" : "Day recorded as bad"
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
}

// MARK: - Habit Button
struct HabitButton: View {
    enum ButtonType {
        case positive
        case negative
        
        var symbol: String {
            switch self {
            case .positive: return "plus"
            case .negative: return "minus"
            }
        }
        
        var label: String {
            switch self {
            case .positive: return "Good day"
            case .negative: return "Bad day"
            }
        }
        
        var color: Color {
            switch self {
            case .positive: return Color(hex: "#788c5d")
            case .negative: return Color(hex: "#FF6B35")
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .positive: return Color(hex: "#F0F5EB")
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
                .font(.custom("Poppins-Medium", size: 12))
                .foregroundColor(MoriColors.secondary)
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
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(MoriColors.text)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(streak.currentStreak)")
                        .font(.custom("CormorantGaramond-SemiBold", size: 24))
                        .foregroundColor(MoriColors.accentAmber)
                    Text("days")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(MoriColors.secondary)
                    
                    if streak.currentStreak >= 7 {
                        Text("🔥")
                            .font(.system(size: 20))
                    }
                }
            }
            
            HStack {
                Text("Longest Streak")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(MoriColors.secondary)
                
                Spacer()
                
                Text("\(streak.longestStreak) days")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(MoriColors.secondary)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Week Visualization
struct WeekVisualization: View {
    let entries: [HabitEntry]
    
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Last 7 Days")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(MoriColors.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    let entry = entries.first { Calendar.current.isDate($0.date, inSameDayAs: getWeekDate(offset: index)) }
                    let isToday = index == 6
                    
                    VStack(spacing: 8) {
                        Circle()
                            .fill(dotColor(for: entry?.isPositive))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(isToday ? MoriColors.accentAmber : .clear, lineWidth: 2)
                            )
                            .opacity(isToday ? 1 : 0.7)
                        
                        Text(dayLabels[index])
                            .font(.custom("Poppins-Regular", size: 10))
                            .foregroundColor(MoriColors.softTaupe)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func dotColor(for isPositive: Bool?) -> Color {
        guard let isPositive = isPositive else {
            return MoriColors.warmGray
        }
        return isPositive ? Color(hex: "#788c5d") : Color(hex: "#FF6B35")
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
        let total = stats.positiveDays + stats.negativeDays
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
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(MoriColors.text)
                Spacer()
            }
            
            Divider()
            
            StatRow(label: "Good days", value: "\(stats.positiveDays) (\(percentage)%)", valueColor: Color(hex: "#788c5d"))
            StatRow(label: "Bad days", value: "\(stats.negativeDays)", valueColor: Color(hex: "#FF6B35"))
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var trendColor: Color {
        switch stats.trend {
        case .improving: return Color(hex: "#788c5d")
        case .declining: return Color(hex: "#FF6B35")
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
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(MoriColors.secondary)
            Spacer()
            Text(value)
                .font(.custom("Poppins-SemiBold", size: 14))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Habit Settings Sheet
struct HabitSettingsSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Data") {
                    Button("Clear All Data", role: .destructive) {
                        // Clear data
                    }
                }
            }
            .navigationTitle("Habit Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HabitTrackerView()
        .environmentObject(UserSettings())
}
