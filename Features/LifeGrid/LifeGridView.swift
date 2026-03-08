import SwiftUI

struct LifeGridView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var selectedWeek: WeekCoordinate?
    @State private var showWeekDetail = false
    
    private let columns = Array(repeating: GridItem(.fixed(5), spacing: 1), count: 52)
    private let squareSize: CGFloat = 4
    private let ageLabelWidth: CGFloat = 24
    
    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                HStack(alignment: .top, spacing: 4) {
                    // Age labels column
                    AgeLabelsColumn(lifeExpectancy: settings.lifeExpectancy)
                        .frame(width: ageLabelWidth)
                    
                    // Main grid
                    VStack(spacing: 1) {
                        ForEach(0..<settings.lifeExpectancy, id: \.self) { year in
                            LazyVGrid(columns: columns, spacing: 1) {
                                ForEach(0..<52, id: \.self) { week in
                                    let weekIndex = year * 52 + week
                                    let isPast = weekIndex < settings.weeksLived
                                    let isCurrent = weekIndex == settings.currentWeekIndex
                                    
                                    WeekSquare(
                                        year: year,
                                        week: week,
                                        isPast: isPast,
                                        isCurrent: isCurrent
                                    )
                                    .onTapGesture {
                                        handleWeekTap(year: year, week: week)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(MoriColors.background)
            .navigationTitle("Life Grid")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showWeekDetail) {
                if let week = selectedWeek {
                    WeekDetailSheet(
                        week: week,
                        settings: settings,
                        isPresented: $showWeekDetail
                    )
                }
            }
        }
        .onAppear {
            AnalyticsManager.shared.trackLifeGridViewed()
        }
    }
    
    private func handleWeekTap(year: Int, week: Int) {
        let weekIndex = year * 52 + week
        
        // Don't allow tapping future weeks
        if weekIndex >= settings.weeksLived {
            return
        }
        
        selectedWeek = WeekCoordinate(year: year, week: week)
        showWeekDetail = true
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Age Labels Column
struct AgeLabelsColumn: View {
    let lifeExpectancy: Int
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            ForEach(0..<lifeExpectancy, id: \.self) { age in
                Text("\(age)")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(MoriColors.secondary)
                    .frame(height: 5, alignment: .trailing)
                    .frame(width: 20)
            }
        }
    }
}

// MARK: - Week Square
struct WeekSquare: View {
    private let squareSize: CGFloat = 4
    let year: Int
    let week: Int
    let isPast: Bool
    let isCurrent: Bool
    
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        ZStack {
            // Current week pulse animation
            if isCurrent {
                Circle()
                    .fill(MoriColors.accentAmber)
                    .frame(width: squareSize + 2, height: squareSize + 2)
                    .opacity(reduceMotion ? 1 : 0.7)
                    .animation(
                        reduceMotion ? .none : 
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: isCurrent
                    )
            }
            
            // Main square
            Circle()
                .fill(squareColor)
                .frame(width: squareSize, height: squareSize)
                .scaleEffect(isPressed ? 1.2 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to add memory")
    }
    
    private var squareColor: Color {
        if isCurrent {
            return MoriColors.accentAmber
        } else if isPast {
            return MoriColors.warmCharcoal
        } else {
            return MoriColors.creamWhite
        }
    }
    
    private var accessibilityLabel: String {
        if isCurrent {
            return "Current week, week \(week + 1) of age \(year)"
        } else if isPast {
            return "Lived week \(week + 1) of age \(year)"
        } else {
            return "Future week \(week + 1) of age \(year)"
        }
    }
}

// MARK: - Week Coordinate
struct WeekCoordinate: Equatable {
    let year: Int
    let week: Int
}

// MARK: - Week Detail Sheet
struct WeekDetailSheet: View {
    let week: WeekCoordinate
    let settings: UserSettings
    @Binding var isPresented: Bool
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private var weekDate: Date {
        let calendar = Calendar.current
        let birthDate = settings.birthDate
        var components = calendar.dateComponents([.year, .month, .day], from: birthDate)
        components.year = week.year
        components.weekOfYear = week.week + 1
        
        // Estimate the date
        let weekOfYear = week.week + 1
        let daysOffset = weekOfYear * 7
        return calendar.date(byAdding: .day, value: daysOffset, to: birthDate) ?? birthDate
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = weekDate
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekDate) ?? weekDate
        return "\(formatter.string(from: start))-\(formatter.string(from: end)), \(week.year + settings.age)"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Week info
                VStack(spacing: 8) {
                    Text("Week \(week.week + 1), Age \(week.year)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(dateRangeText)
                        .font(.subheadline)
                        .foregroundColor(MoriColors.secondary)
                }
                .padding(.top)
                
                // Memory placeholder
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 40))
                        .foregroundColor(MoriColors.secondary)
                    
                    Text("No memory logged")
                        .font(.subheadline)
                        .foregroundColor(MoriColors.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(MoriColors.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Add memory button
                Button(action: {
                    // TODO: Implement memory logging
                    isPresented = false
                }) {
                    Text("Add Memory")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(MoriColors.accentAmber)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .background(MoriColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    LifeGridView()
        .environmentObject(UserSettings())
}
