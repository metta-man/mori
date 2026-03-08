//
//  UserManager.swift
//  Mori
//
//  User data management with CoreData
//

import Foundation
import CoreData

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    private let context: NSManagedObjectContext
    
    @Published var currentUser: UserEntity?
    
    private init() {
        self.context = PersistenceController.shared.viewContext
        fetchCurrentUser()
    }
    
    func fetchCurrentUser() {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let users = try context.fetch(request)
            if let user = users.first {
                currentUser = user
            } else {
                createDefaultUser()
            }
        } catch {
            print("Failed to fetch user: \(error)")
            createDefaultUser()
        }
    }
    
    private func createDefaultUser() {
        let user = UserEntity(context: context)
        user.id = UUID()
        user.name = "New User"
        user.birthDate = Date()
        user.lifeExpectancy = 80
        user.createdAt = Date()
        user.updatedAt = Date()
        
        PersistenceController.shared.save()
        currentUser = user
    }
    
    func updateBirthDate(_ date: Date) {
        currentUser?.birthDate = date
        currentUser?.updatedAt = Date()
        PersistenceController.shared.save()
    }
    
    func updateLifeExpectancy(_ years: Int16) {
        currentUser?.lifeExpectancy = years
        currentUser?.updatedAt = Date()
        PersistenceController.shared.save()
    }
    
    func updateName(_ name: String) {
        currentUser?.name = name
        currentUser?.updatedAt = Date()
        PersistenceController.shared.save()
    }
}
