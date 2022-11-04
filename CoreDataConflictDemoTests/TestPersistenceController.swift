//
//  TestPersistenceController.swift
//  CoreDataConflictDemoTests
//
//  Created by Yuhan Chen on 2022/11/04.
//

import CoreData

class TestPersistenceController {
    lazy var container: NSPersistentContainer = {
        guard
            let modelPath = Bundle(for: CoreDataConflictDemoTests.self).path(forResource: "TestingModel", ofType: "momd"),
            let objectModel = NSManagedObjectModel(contentsOf: URL(fileURLWithPath: modelPath))
        else {
            fatalError("Cannot create managed object model.")
        }
        return NSPersistentContainer(name: "TestingModel", managedObjectModel: objectModel)
    }()

    private lazy var dbDirectoryURL: URL? = try? FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
    ).appendingPathComponent("databases", isDirectory: true)

    private lazy var storeURL: URL? = dbDirectoryURL?.appendingPathComponent("UnitTest.sqlite")

    init() {
        if (try? dbDirectoryURL?.checkResourceIsReachable()) != true {
            try? FileManager.default.createDirectory(
                at: dbDirectoryURL!,
                withIntermediateDirectories: true
            )
        }

        let description = NSPersistentStoreDescription()
        description.url = storeURL

        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    func removeDB() {
        guard let url = dbDirectoryURL else { fatalError("Bad db directory url.") }
        try? FileManager.default.removeItem(at: url)
    }
}
