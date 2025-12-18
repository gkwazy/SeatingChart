//
//  PersistenceController.swift
//  SeatingChart
//
//  Created by GKWazy Software
//

import CoreData
import CloudKit

class PersistenceController: ObservableObject {
    static let shared = PersistenceController(storageMode: AppStateManager().storageMode)

    let container: NSPersistentContainer
    let storageMode: StorageMode

    init(storageMode: StorageMode, inMemory: Bool = false) {
        self.storageMode = storageMode

        // Use CloudKit container for iCloud, regular container for local
        if storageMode == .iCloud {
            container = NSPersistentCloudKitContainer(name: "SeatingChart")
        } else {
            container = NSPersistentContainer(name: "SeatingChart")
        }

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure store based on storage mode
            if let description = container.persistentStoreDescriptions.first {
                if storageMode == .iCloud {
                    // Enable CloudKit sync
                    description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                        containerIdentifier: "iCloud.com.seatingchart.app"
                    )
                    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                    description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                } else {
                    // Local only - no CloudKit
                    description.cloudKitContainerOptions = nil
                }
            }
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Storage Mode Migration

    func switchStorageMode(to newMode: StorageMode, migrateData: Bool) async throws {
        // This would involve creating a new container and migrating data
        // For simplicity, we'll handle this by notifying the user to export/import data
        // A full implementation would copy entities between stores
        throw NSError(domain: "PersistenceController", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Storage mode switching requires app restart. Please export your data first."
        ])
    }

    // MARK: - Save Context

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                #if DEBUG
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
                #endif
            }
        }
    }

    // MARK: - Preview

    static var preview: PersistenceController = {
        let controller = PersistenceController(storageMode: .local, inMemory: true)
        let context = controller.container.viewContext

        // Create sample data for previews
        let classroom = Classroom(context: context)
        classroom.id = UUID()
        classroom.name = "Main Classroom"
        classroom.rows = 5
        classroom.columns = 8
        classroom.isActive = true

        let classPeriod = ClassPeriod(context: context)
        classPeriod.id = UUID()
        classPeriod.name = "Period 1 Math"
        classPeriod.addToClassrooms(classroom)

        // Create sample students
        for i in 1...5 {
            let student = Student(context: context)
            student.id = UUID()
            student.firstName = "Student"
            student.lastName = "\(i)"
            student.studentID = "S\(1000 + i)"
            student.classPeriod = classPeriod
        }

        try? context.save()
        return controller
    }()
}
