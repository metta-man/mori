import SwiftUI
import CoreData

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
    
    @State private var memoryText: String = ""
    @State private var isEditing: Bool = false
    @State private var existingNote: String?
    @State private var weekID: UUID?
    @State private var showSaveSuccess: Bool = false
    
    private let store = LifeWeekStore.shared
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
    
    private var weekDate: Date {
        let calendar = Calendar.current
        let birthDate = settings.birthDate
        let weekOfYear = week.week + 1
        let daysOffset = weekOfYear * 7
        return calendar.date(byAdding: .day, value: daysOffset, to: birthDate) ?? birthDate
    }
    
    private var dateRangeText: String {
        let start = weekDate
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekDate) ?? weekDate
        return "\(dateFormatter.string(from: start))-\(dateFormatter.string(from: end)), Age \(week.year + settings.age)"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
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
                    
                    // Memory section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(MoriColors.accentAmber)
                            Text("本周记忆")
                                .font(.headline)
                                .foregroundColor(MoriColors.text)
                            Spacer()
                            if existingNote != nil && !isEditing {
                                Button("编辑") {
                                    isEditing = true
                                }
                                .font(.subheadline)
                                .foregroundColor(MoriColors.accentAmber)
                            }
                        }
                        
                        if isEditing || existingNote == nil {
                            TextEditor(text: $memoryText)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(MoriColors.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(MoriColors.accentAmber.opacity(0.3), lineWidth: 1)
                                )
                                .foregroundColor(MoriColors.text)
                                .scrollContentBackground(.hidden)
                            
                            Button(action: saveMemory) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("保存记忆")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(memoryText.isEmpty ? MoriColors.secondary : MoriColors.accentAmber)
                                .cornerRadius(12)
                            }
                            .disabled(memoryText.isEmpty)
                        } else {
                            Text(existingNote ?? "")
                                .font(.custom("Caveat", size: 18))
                                .foregroundColor(MoriColors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(MoriColors.cardBackground)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Reflection prompts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("反思提示")
                            .font(.headline)
                            .foregroundColor(MoriColors.secondary)
                            .padding(.horizontal)
                        
                        ForEach(reflectionPrompts, id: \.self) { prompt in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(MoriColors.morningGold)
                                    .font(.system(size: 16))
                                Text(prompt)
                                    .font(.subheadline)
                                    .foregroundColor(MoriColors.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(MoriColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.large])
        .onAppear(perform: loadExistingNote)
    }
    
    private var reflectionPrompts: [String] {
        if week.year + settings.age < 10 {
            return [
                "这周发生了什么有趣的事?",
                "你学到了什么新东西?",
                "什么事情让你感到开心?"
            ]
        } else if week.year + settings.age < 30 {
            return [
                "这周你最大的收获是什么?",
                "有什么挑战?你是如何应对的?",
                "你想对下周说什么?"
            ]
        } else {
            return [
                "这周你最感谢的是什么?",
                "有什么值得记住的时刻?",
                "你想留下什么?"
            ]
        }
    }
    
    private func loadExistingNote() {
        guard let userID = UserManager.shared.currentUser?.id else { return }
        if let lifeWeek = store.fetchWeek(userID: userID, yearIndex: week.year, weekIndex: week.week) {
            existingNote = lifeWeek.note
            memoryText = lifeWeek.note ?? ""
            weekID = lifeWeek.id
        }
    }
    
    private func saveMemory() {
        guard let userID = UserManager.shared.currentUser?.id else { return }
        
        let trimmed = memoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let id = weekID {
            store.updateNote(weekID: id, note: trimmed)
        } else {
            // Create a new LifeWeek with the note
            let calendar = Calendar.current
            let birthDate = settings.birthDate
            let startDate = calendar.date(byAdding: .day, value: week.week * 7, to: birthDate) ?? birthDate
            let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
            
            let newWeek = LifeWeek(
                weekIndex: week.week,
                yearIndex: week.year,
                weekOfYear: week.week + 1,
                startDate: startDate,
                endDate: endDate,
                isLived: week.year * 52 + week.week < settings.weeksLived,
                note: trimmed
            )
            store.saveWeek(newWeek, userID: userID)
        }
        
        existingNote = trimmed
        isEditing = false
        showSaveSuccess = true
        
        // Auto-dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPresented = false
        }
    }
}

#Preview {
    LifeGridView()
        .environmentObject(UserSettings())
}
