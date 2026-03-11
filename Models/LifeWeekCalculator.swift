import Foundation

enum LifeWeekSyncStatus: String, Codable {
    case pendingUpsert
    case synced
    
    var displayName: String {
        switch self {
        case .pendingUpsert:
            return "Pending Sync"
        case .synced:
            return "Synced"
        }
    }
}

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
    var createdAt: Date?
    var updatedAt: Date?
    var lastSyncedAt: Date?
    var remoteID: String?
    var syncStatus: LifeWeekSyncStatus
    
    init(
        id: UUID = UUID(),
        weekIndex: Int,
        yearIndex: Int,
        weekOfYear: Int,
        startDate: Date,
        endDate: Date,
        isLived: Bool,
        mood: String? = nil,
        note: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        lastSyncedAt: Date? = nil,
        remoteID: String? = nil,
        syncStatus: LifeWeekSyncStatus = .pendingUpsert
    ) {
        self.id = id
        self.weekIndex = weekIndex
        self.yearIndex = yearIndex
        self.weekOfYear = weekOfYear
        self.startDate = startDate
        self.endDate = endDate
        self.isLived = isLived
        self.mood = mood
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.remoteID = remoteID
        self.syncStatus = syncStatus
    }
}

struct LifeWeekCalculator {
    static func generateWeeks(birthDate: Date, lifeExpectancy: Int = 80) -> [LifeWeek] {
        let totalWeeks = lifeExpectancy * 52
        var weeks: [LifeWeek] = []
        
        let today = Date()
        let calendar = Calendar.current
        
        // Start from birth date
        var currentDate = birthDate
        
        for weekIndex in 0..<totalWeeks {
            // Calculate start and end of this week
            let weekStart = calendar.date(byAdding: .day, value: weekIndex * 7, to: birthDate)!
            let weekEnd = calendar.date(byAdding: .day, value: (weekIndex + 1) * 7 - 1, to: birthDate)!
            
            // Calculate year index (0-based)
            let yearIndex = weekIndex / 52
            
            // Calculate week of year
            let weekOfYear = calendar.component(.weekOfYear, from: weekStart)
            
            // Determine if this week has been lived
            let isLived = today >= weekStart
            
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
}
