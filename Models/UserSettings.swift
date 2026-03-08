import Foundation

class UserSettings: ObservableObject {
    @Published var birthDate: Date {
        didSet {
            UserDefaults.standard.set(birthDate, forKey: "birthDate")
            AnalyticsManager.shared.trackBirthDateSet()
        }
    }
    
    @Published var lifeExpectancy: Int {
        didSet {
            UserDefaults.standard.set(lifeExpectancy, forKey: "lifeExpectancy")
        }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    var age: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: birthDate, to: Date())
        return components.year ?? 0
    }
    
    var totalWeeks: Int {
        lifeExpectancy * 52
    }
    
    var weeksLived: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.weekOfYear, .year], from: birthDate, to: now)
        let years = components.year ?? 0
        let weeks = components.weekOfYear ?? 0
        return min(years * 52 + weeks, totalWeeks)
    }
    
    var weeksRemaining: Int {
        max(totalWeeks - weeksLived, 0)
    }
    
    var percentageLived: Double {
        guard totalWeeks > 0 else { return 0 }
        return Double(weeksLived) / Double(totalWeeks)
    }
    
    var currentWeekIndex: Int {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: Date())
        let year = calendar.component(.year, from: birthDate)
        let currentYear = calendar.component(.year, from: Date())
        return (currentYear - year) * 52 + weekOfYear
    }
    
    init() {
        let savedDate = UserDefaults.standard.object(forKey: "birthDate") as? Date
        self.birthDate = savedDate ?? Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        
        let savedLifeExpectancy = UserDefaults.standard.integer(forKey: "lifeExpectancy")
        self.lifeExpectancy = savedLifeExpectancy > 0 ? savedLifeExpectancy : 80
        
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}
