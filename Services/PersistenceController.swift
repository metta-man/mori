//
//  PersistenceController.swift
//  Mori
//
//  Core Data stack management
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Mori")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Failed to load Core Data stack: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Preview Support
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create sample user
        let user = UserEntity(context: viewContext)
        user.id = UUID()
        user.name = "Demo User"
        user.birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date())
        user.lifeExpectancy = 80
        user.createdAt = Date()
        user.updatedAt = Date()
        
        // Create sample habit entries
        for dayOffset in 0..<7 {
            let entry = HabitEntryEntity(context: viewContext)
            entry.id = UUID()
            entry.date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())
            entry.moodRating = Int16.random(in: 1...5)
            entry.note = dayOffset == 0 ? "Feeling motivated!" : nil
            entry.createdAt = Date()
            entry.updatedAt = Date()
            entry.user = user
        }
        
        // Create sample gratitude entry
        let gratitude = GratitudeEntryEntity(context: viewContext)
        gratitude.id = UUID()
        gratitude.date = Date()
        gratitude.prompt = "What made you smile today?"
        gratitude.content = "Had a great coffee this morning"
        gratitude.createdAt = Date()
        gratitude.updatedAt = Date()
        gratitude.user = user
        
        do {
            try viewContext.save()
        } catch {
            fatalError("Failed to save preview context: \(error)")
        }
        
        return controller
    }()

    // MARK: - Save Context
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Failed to save context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - Background Context
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
