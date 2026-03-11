import Foundation
import CoreData

/// Service for managing LifeWeek persistence in Core Data
final class LifeWeekStore {
    static let shared = LifeWeekStore()
    
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }
    
    // MARK: - Fetch
    
    func fetchWeeks(for userID: UUID, yearIndex: Int? = nil) -> [LifeWeek] {
        let request = LifeWeekEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
        if let yearIndex = yearIndex {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                request.predicate!,
                NSPredicate(format: "yearIndex == %d", yearIndex)
            ])
        }
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \LifeWeekEntity.yearIndex, ascending: true),
            NSSortDescriptor(keyPath: \LifeWeekEntity.weekIndex, ascending: true)
        ]
        
        do {
            let entities = try viewContext.fetch(request)
            return entities.compactMap { mapToModel($0) }
        } catch {
            print("Failed to fetch weeks: \(error)")
            return []
        }
    }
    
    func fetchWeek(id: UUID) -> LifeWeek? {
        let request = LifeWeekEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entities = try viewContext.fetch(request)
            return entities.first.flatMap { mapToModel($0) }
        } catch {
            print("Failed to fetch week: \(error)")
            return nil
        }
    }
    
    func fetchWeek(userID: UUID, yearIndex: Int, weekIndex: Int) -> LifeWeek? {
        let request = LifeWeekEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "userID == %@ AND yearIndex == %d AND weekIndex == %d",
            userID as CVarArg, yearIndex, weekIndex
        )
        request.fetchLimit = 1
        
        do {
            let entities = try viewContext.fetch(request)
            return entities.first.flatMap { mapToModel($0) }
        } catch {
            print("Failed to fetch week: \(error)")
            return nil
        }
    }
    
    // MARK: - Save/Update
    
    @discardableResult
    func saveWeek(_ week: LifeWeek, userID: UUID) -> LifeWeekEntity? {
        let entity: LifeWeekEntity
        
        // Try to find existing
        if let existing = fetchWeekEntity(id: week.id) {
            entity = existing
        } else if let existing = fetchWeekEntity(userID: userID, yearIndex: week.yearIndex, weekIndex: week.weekIndex) {
            entity = existing
        } else {
            entity = LifeWeekEntity(context: viewContext)
            entity.id = week.id
            entity.createdAt = Date()
        }
        
        // Update fields
        entity.userID = userID
        entity.weekIndex = Int32(week.weekIndex)
        entity.yearIndex = Int32(week.yearIndex)
        entity.weekOfYear = Int32(week.weekOfYear)
        entity.startDate = week.startDate
        entity.endDate = week.endDate
        entity.isLived = week.isLived
        entity.mood = week.mood
        entity.note = week.note
        entity.updatedAt = Date()
        
        // Sync fields
        if entity.syncStatus == nil {
            entity.syncStatus = "pendingUpsert"
        }
        
        save()
        return entity
    }
    
    func updateMood(weekID: UUID, mood: String?) {
        guard let entity = fetchWeekEntity(id: weekID) else { return }
        entity.mood = mood
        entity.updatedAt = Date()
        entity.syncStatus = "pendingUpsert"
        save()
    }
    
    func updateNote(weekID: UUID, note: String?) {
        guard let entity = fetchWeekEntity(id: weekID) else { return }
        entity.note = note
        entity.updatedAt = Date()
        entity.syncStatus = "pendingUpsert"
        save()
    }
    
    // MARK: - Delete
    
    func deleteWeek(id: UUID) {
        guard let entity = fetchWeekEntity(id: id) else { return }
        viewContext.delete(entity)
        save()
    }
    
    // MARK: - Sync Support
    
    func fetchUnsyncedWeeks() -> [LifeWeek] {
        let request = LifeWeekEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", "pendingUpsert")
        
        do {
            let entities = try viewContext.fetch(request)
            return entities.compactMap { mapToModel($0) }
        } catch {
            print("Failed to fetch unsynced weeks: \(error)")
            return []
        }
    }
    
    func markAsSynced(weekID: UUID, remoteID: String) {
        fetchWeekEntity(id: weekID) else { return }
 guard let entity =        entity.remoteID = remoteID
        entity.syncStatus = "synced"
        entity.lastSyncedAt = Date()
        save()
    }
    
    // MARK: - Private
    
    private func fetchWeekEntity(id: UUID) -> LifeWeekEntity? {
        let request = LifeWeekEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    private func fetchWeekEntity(userID: UUID, yearIndex: Int, weekIndex: Int) -> LifeWeekEntity? {
        let request = LifeWeekEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "userID == %@ AND yearIndex == %d AND weekIndex == %d",
            userID as CVarArg, yearIndex, weekIndex
        )
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    private func mapToModel(_ entity: LifeWeekEntity) -> LifeWeek? {
        guard let id = entity.id,
              let startDate = entity.startDate,
              let endDate = entity.endDate else { return nil }
        
        let syncStatus: LifeWeekSyncStatus
        switch entity.syncStatus {
        case "synced": syncStatus = .synced
        default: syncStatus = .pendingUpsert
        }
        
        return LifeWeek(
            id: id,
            weekIndex: Int(entity.weekIndex),
            yearIndex: Int(entity.yearIndex),
            weekOfYear: Int(entity.weekOfYear),
            startDate: startDate,
            endDate: endDate,
            isLived: entity.isLived,
            mood: entity.mood,
            note: entity.note,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            lastSyncedAt: entity.lastSyncedAt,
            remoteID: entity.remoteID,
            syncStatus: syncStatus
        )
    }
    
    private func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
