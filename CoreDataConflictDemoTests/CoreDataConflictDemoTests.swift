//
//  CoreDataConflictDemoTests.swift
//  CoreDataConflictDemoTests
//
//  Created by Yuhan Chen on 2022/11/04.
//

import XCTest
import CoreData
@testable import CoreDataConflictDemo

final class CoreDataConflictDemoTests: XCTestCase {
    var persistenceController: TestPersistenceController!

    override func setUp() {
        persistenceController = TestPersistenceController()
    }

    override func tearDown() {
        persistenceController.removeDB()
        persistenceController = nil
    }
}
