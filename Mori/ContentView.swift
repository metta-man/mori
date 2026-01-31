import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GratitudeEntry.date, order: .reverse) private var gratitudeEntries: [GratitudeEntry]
    
    @State private var birthDate = Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? Date()
    @State private var todaysBonus: Int = 0
    @State private var gratitudeText: String = ""
    @State private var habits: [String] = ["Exercise", "Read", "Meditate"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Death Clock Section
                deathClockSection
                
                // Life in Squares Grid
                lifeGridSection
                
                // Habit Tracking Section
                habitTrackingSection
                
                // Gratitude Diary Section
                gratitudeDiarySection
            }
            .padding()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .onAppear {
            loadTodaysGratitude()
        }
    }
    
    // MARK: - Death Clock Section
    private var deathClockSection: some View {
        VStack(spacing: 10) {
            Text("Time Remaining")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("\(remainingDays)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("days")
                .font(.title3)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Life Grid Section
    private var lifeGridSection: some View {
        VStack(spacing: 10) {
            Text("Life in Squares")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("80 years × 52 weeks")
                .font(.caption)
                .foregroundColor(.gray)
            
            LifeGrid(birthDate: birthDate)
                .frame(height: 300)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Habit Tracking Section
    private var habitTrackingSection: some View {
        VStack(spacing: 15) {
            Text("Habit Tracking")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 10) {
                ForEach(habits, id: \.self) { habit in
                    HStack {
                        Text(habit)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            todaysBonus -= 10
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            todaysBonus += 10
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            
            Divider()
                .background(Color.gray)
            
            HStack {
                Text("Today's Bonus:")
                    .foregroundColor(.white)
                Spacer()
                Text("\(todaysBonus) minutes")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(todaysBonus >= 0 ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Gratitude Diary Section
    private var gratitudeDiarySection: some View {
        VStack(spacing: 10) {
            Text("Today's Gratitude")
                .font(.headline)
                .foregroundColor(.white)
            
            TextEditor(text: $gratitudeText)
                .frame(height: 150)
                .scrollContentBackground(.hidden)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
                .onChange(of: gratitudeText) { _, newValue in
                    saveTodaysGratitude(text: newValue)
                }
            
            if let lastEntry = gratitudeEntries.first {
                Text("Last saved: \(lastEntry.date, style: .time)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    private var remainingDays: Int {
        let lifeExpectancy = 85
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        let currentAge = ageComponents.year ?? 0
        let remainingYears = lifeExpectancy - currentAge
        let deathDate = calendar.date(byAdding: .year, value: remainingYears, to: Date()) ?? Date()
        let remainingComponents = calendar.dateComponents([.day], from: Date(), to: deathDate)
        return max(0, remainingComponents.day ?? 0)
    }
    
    // MARK: - Helper Functions
    private func loadTodaysGratitude() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let todaysEntry = gratitudeEntries.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            gratitudeText = todaysEntry.text
        }
    }
    
    private func saveTodaysGratitude(text: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let existingEntry = gratitudeEntries.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            existingEntry.text = text
        } else {
            let newEntry = GratitudeEntry(date: Date(), text: text)
            modelContext.insert(newEntry)
        }
        
        try? modelContext.save()
    }
}

// MARK: - Life Grid View
struct LifeGrid: View {
    let birthDate: Date
    
    private let columns = 52 // weeks in a year
    private let rows = 80 // years of life
    private let squareSize: CGFloat = 4
    private let spacing: CGFloat = 1
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let calculatedSquareSize = min(squareSize, (totalWidth - CGFloat(columns - 1) * spacing) / CGFloat(columns))
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(calculatedSquareSize), spacing: spacing), count: columns), spacing: spacing) {
                    ForEach(0..<(rows * columns), id: \.self) { index in
                        let weekNumber = index
                        let isLived = isWeekLived(weekNumber: weekNumber)
                        
                        Rectangle()
                            .fill(isLived ? Color.gray : Color.blue)
                            .frame(width: calculatedSquareSize, height: calculatedSquareSize)
                    }
                }
                .padding(1)
            }
        }
    }
    
    private func isWeekLived(weekNumber: Int) -> Bool {
        let calendar = Calendar.current
        guard let targetDate = calendar.date(byAdding: .weekOfYear, value: weekNumber, to: birthDate) else {
            return false
        }
        return targetDate <= Date()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: GratitudeEntry.self, inMemory: true)
}
