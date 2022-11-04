//
//  CheckExpectation.swift
//  CoreDataConflictDemoTests
//
//  Created by Yuhan Chen on 2022/11/04.
//

import XCTest
import CoreData

enum Expectation {
    struct EntityValue<T: NSManagedObject> {
        /// The count of objects associated on the relationship type(one-to-one, many-to-many...) to be confirmed.
        let relationshipsCount: Int

        /// The reference ID of specified object.
        let referenceID: Int

        /// The addtional checking to be done. Sometimes there're values that are difficult to check by a common method,
        /// e.g., even if we know that there're two rows of data in a many-to-many relationship table, but what exactly
        /// they are, the common method doesn't need to know. In that case we could use `additionalHandler`.
        let additionalHandler: ((_ entity: T?, _ message: String) -> Void)?

        init(
            relationshipsCount: Int,
            referenceID: Int,
            additionalHandler: ((_ entity: T?, _ message: String) -> Void)? = nil
        ) {
            self.relationshipsCount = relationshipsCount
            self.referenceID = referenceID
            self.additionalHandler = additionalHandler
        }
    }

    struct ManyToManyRelationship {
        let entityAs: [EntityValue<EntityA>?]
        let entityBs: [EntityValue<EntityB>?]
    }
}

extension CoreDataConflictDemoTests {
    func checkManyToManyRelationship(
        _ expectation: Expectation.ManyToManyRelationship,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let resultBackgroundContext = persistenceController.container.newBackgroundContext()

        // EntityA
        let entityAFetchRequest: NSFetchRequest<EntityA> = EntityA.fetchRequest()
        let entityAs = try resultBackgroundContext.performAndWait { context -> [EntityA] in
            try context.fetch(entityAFetchRequest)
        }

        [100, 200].enumerated().forEach { index, attr in
            // Count
            let entity = entityAs.first(where: { $0.attribute == attr })
            let expectedEntityA = expectation.entityAs[index]
            XCTAssertEqual(
                entity?.toManyRelationship?.count,
                expectedEntityA?.relationshipsCount,
                "[EntityA] attribute: \(attr) - relationshipsCount",
                file: file,
                line: line
            )

            // Additional checks
            expectedEntityA?.additionalHandler?(entity, "[EntityA] attribute: \(attr) - extra")
        }

        // EntityB
        let entityBFetchRequest: NSFetchRequest<EntityB> = EntityB.fetchRequest()
        let entityBs = try resultBackgroundContext.performAndWait { context -> [EntityB] in
            try context.fetch(entityBFetchRequest)
        }

        [10, 11, 12].enumerated().forEach { index, attr in
            // Count
            let entity = entityBs.first(where: { $0.attribute == attr })
            let expectedEntityB = expectation.entityBs[index]
            XCTAssertEqual(
                entity?.toManyRelationship?.count,
                expectedEntityB?.relationshipsCount,
                "[EntityB] attribute: \(attr) [Failure] relationshipsCount",
                file: file,
                line: line
            )

            // Additional checks
            expectedEntityB?.additionalHandler?(entity, "[EntityB] attribute: \(attr) - extra")
        }
    }
}
