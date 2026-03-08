//
//  LifeWeekCalculator.swift
//  Mori
//
//  Calculates life weeks based on birth date and life expectancy
//

import Foundation

struct LifeWeek: Identifiable, Hashable {
    let id: UUID
    let weekIndex: Int
    let yearIndex: Int
    let weekOfYear: Int
    let startDate: Date
    let endDate: Date
    let isLived: Bool
    var mood: String?
    var note: String?
    
    init(weekIndex: Int, yearIndex: Int, weekOfYear: Int, startDate: Date, endDate: Date, isLived: Bool, mood: String? = nil, note: String? = nil) {
        self.id = UUID()
        self.weekIndex = weekIndex
        self.yearIndex = yearIndex
        self.weekOfYear = weekOfYear
        self.startDate = startDate
        self.endDate = endDate
        self.isLived = isLived
        self.mood = mood
        self.note = note
    }
}

struct LifeWeekCalculator {
    
    /// Calculate all life weeks from birth date
    /// - Parameters:
    ///   - birthDate: User's birth date
    ///   - lifeExpectancy: Expected lifespan in years (default 80)
    /// - Returns: Array of LifeWeek objects
    static func calculateLifeWeeks(birthDate: Date, lifeExpectancy: Int = 80) -> [LifeWeek] {
        let calendar = Calendar.current
        let totalWeeks = lifeExpectancy * 52
        var weeks: [LifeWeek] = []
        
        let today = Date()
        
        // Start from birth date
        var currentDate = birthDate
        
        for weekIndex in 0..<totalWeeks {
            // Calculate start and end of this week
            let weekStart = calendar.date(byAdding: .day, value: weekIndex * 7, to: birthDate)!
            let weekEnd = calendar.date(byAdding: .day, value: (weekIndex + 1) * 7 - 1, to: birthDate)!
            
            // Calculate year index (which year of life)
            let yearIndex = weekIndex / 52
            
            // Calculate week of year (1-52)
            let weekOfYear = calendar.component(.weekOfYear, from: weekStart)
            
            // Determine if this week is lived
            let isLived = weekEnd < today
            
            let week = LifeWeek(
                weekIndex: weekIndex,
                yearIndex: yearIndex,
                weekOfYear: weekOfYear,
                startDate: weekStart,
                endDate: weekEnd,
                isLived: isLived
            )
            
            weeks.append(week)
        }
        
        return weeks
    }
    
    /// Get weeks lived count
    static func weeksLived(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let today = Date()
        let weeks = calendar.dateComponents([.weekOfYear], from: birthDate, to: today).weekOfYear ?? 0
        return max(0, weeks)
    }
    
    /// Get weeks remaining
    static func weeksRemaining(from birthDate: Date, lifeExpectancy: Int = 80) -> Int {
        let totalWeeks = lifeExpectancy * 52
        let lived = weeksLived(from: birthDate)
        return max(0, totalWeeks - lived)
    }
    
    /// Calculate percentage of life lived
    static func percentageLived(from birthDate: Date, lifeExpectancy: Int = 80) -> Double {
        let totalWeeks = lifeExpectancy * 52
        let lived = weeksLived(from: birthDate)
        return Double(lived) / Double(totalWeeks) * 100
    }
}
