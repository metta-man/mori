import Foundation
import CoreData

final class WeekArchiveIdentityStore {
    static let shared = WeekArchiveIdentityStore()

    private let defaults: UserDefaults
    private let persistenceController: PersistenceController
    private let key = "weekArchiveUserID"

    init(
        defaults: UserDefaults = .standard,
        persistenceController: PersistenceController = .shared
    ) {
        self.defaults = defaults
        self.persistenceController = persistenceController
    }

    var userID: UUID {
        if let rawValue = defaults.string(forKey: key),
           let savedID = UUID(uuidString: rawValue) {
            return savedID
        }

        let resolvedID = legacyUserID() ?? UUID()
        defaults.set(resolvedID.uuidString, forKey: key)
        return resolvedID
    }

    private func legacyUserID() -> UUID? {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: true)]
        return try? persistenceController.viewContext.fetch(request).first?.id
    }
}

/// Week Archive persistence. The Core Data entity keeps its original name for migration compatibility.
final class WeekArchiveRecordStore {
    static let shared = WeekArchiveRecordStore()
    
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }
    
    // MARK: - Fetch
    
    func fetchRecords(for userID: UUID, yearIndex: Int? = nil) -> [WeekArchiveRecord] {
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
    
    func fetchRecord(id: UUID) -> WeekArchiveRecord? {
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
    
    func fetchRecord(userID: UUID, yearIndex: Int, weekIndex: Int) -> WeekArchiveRecord? {
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
    func saveRecord(_ record: WeekArchiveRecord, userID: UUID) -> WeekArchiveRecord? {
        let entity: LifeWeekEntity
        
        // Try to find existing
        if let existing = fetchRecordEntity(id: record.id) {
            entity = existing
        } else if let existing = fetchRecordEntity(userID: userID, yearIndex: record.yearIndex, weekIndex: record.weekIndex) {
            entity = existing
        } else {
            entity = LifeWeekEntity(context: viewContext)
            entity.id = record.id
            entity.createdAt = Date()
        }
        
        // Update fields
        entity.userID = userID
        entity.weekIndex = Int32(record.weekIndex)
        entity.yearIndex = Int32(record.yearIndex)
        entity.weekOfYear = Int32(record.weekOfYear)
        entity.startDate = record.startDate
        entity.endDate = record.endDate
        entity.isLived = record.isLived
        entity.mood = record.mood
        entity.note = record.note
        entity.updatedAt = Date()
        
        // Sync fields
        if entity.syncStatus == nil {
            entity.syncStatus = "pendingUpsert"
        }
        
        save()
        return mapToModel(entity)
    }
    
    func updateMood(recordID: UUID, mood: String?) {
        guard let entity = fetchRecordEntity(id: recordID) else { return }
        entity.mood = mood
        entity.updatedAt = Date()
        entity.syncStatus = "pendingUpsert"
        save()
    }
    
    func updateNote(recordID: UUID, note: String?) {
        guard let entity = fetchRecordEntity(id: recordID) else { return }
        entity.note = note
        entity.updatedAt = Date()
        entity.syncStatus = "pendingUpsert"
        save()
    }
    
    // MARK: - Delete
    
    func deleteRecord(id: UUID) {
        guard let entity = fetchRecordEntity(id: id) else { return }
        viewContext.delete(entity)
        save()
    }
    
    // MARK: - Sync Support
    
    func fetchUnsyncedRecords() -> [WeekArchiveRecord] {
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
    
    func markAsSynced(recordID: UUID, remoteID: String) {
        guard let entity = fetchRecordEntity(id: recordID) else { return }
        entity.remoteID = remoteID
        entity.syncStatus = "synced"
        entity.lastSyncedAt = Date()
        save()
    }
    
    // MARK: - Private
    
    private func fetchRecordEntity(id: UUID) -> LifeWeekEntity? {
        let request = LifeWeekEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    private func fetchRecordEntity(userID: UUID, yearIndex: Int, weekIndex: Int) -> LifeWeekEntity? {
        let request = LifeWeekEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "userID == %@ AND yearIndex == %d AND weekIndex == %d",
            userID as CVarArg, yearIndex, weekIndex
        )
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    private func mapToModel(_ entity: LifeWeekEntity) -> WeekArchiveRecord? {
        guard let id = entity.id,
              let startDate = entity.startDate,
              let endDate = entity.endDate else { return nil }
        
        let syncStatus: WeekArchiveSyncStatus
        switch entity.syncStatus {
        case "synced": syncStatus = .synced
        default: syncStatus = .pendingUpsert
        }
        
        return WeekArchiveRecord(
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
