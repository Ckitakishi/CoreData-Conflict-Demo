//
//  MergeConflictTests.swift
//  CoreDataConflictDemoTests
//
//  Created by Yuhan Chen on 2022/11/04.
//

import XCTest
import CoreData

extension CoreDataConflictDemoTests {
    func testUpdateUpdatedManyToManyRelationshipWithOverwritePolicy() throws {
        try performManyToManyChanges(
            opInMemory: .update,
            opInStore: .update,
            mergePolicy: .overwrite
        )

        try checkManyToManyRelationship(
            Expectation.ManyToManyRelationship(
                entityAs: [
                    .init(relationshipsCount: 1, referenceID: 1) { entity, message in
                        // [!!] Shouldn't be empty?
                        //
                        // Note: When inserting data on a different context instead of
                        // `persistenceController.container.viewContext`, result will be what we expected.
                        let relatedEntityB = entity?.toManyRelationship?.firstObject as? EntityB
                        XCTAssertEqual(relatedEntityB?.attribute, 10, message)
                    },
                    .init(relationshipsCount: 2, referenceID: 2)
                ],
                entityBs: [
                    .init(relationshipsCount: 0, referenceID: 1),
                    .init(relationshipsCount: 1, referenceID: 2) { entity, message in
                        let relatedEntityA = entity?.toManyRelationship?.allObjects.first as? EntityA
                        XCTAssertEqual(relatedEntityA?.attribute, 200, message)
                    },
                    .init(relationshipsCount: 1, referenceID: 3)
                ]
            )
        )
    }
}

private enum Operation {
    case update
    case delete
}

extension CoreDataConflictDemoTests {
    /// Original Data (all reverse relationships are set properly):
    ///
    /// EntityA(attribute: 100) = [EntityB(attribute: 10), EntityB(attribute: 11)]
    /// EntityA(attribute: 200) = [EntityB(attribute: 11), EntityB(attribute: 12)]
    ///
    /// EntityB(attribute: 10) = [EntityA(attribute: 100)]
    /// EntityB(attribute: 11) = [EntityA(attribute: 100), EntityA(attribute: 200)]
    /// EntityB(attribute: 12) = [EntityA(attribute: 200)]
    func insertNewItemsInToManyTable() throws {
        let viewContext = persistenceController.container.viewContext

        try viewContext.performAndWait { context in
            let entityBArray = (10...12).map { uniqueID -> EntityB in
                let entityB = EntityB(context: context)
                entityB.attribute = Int64(uniqueID)
                return entityB
            }

            let entityA1 = EntityA(context: viewContext)
            entityA1.attribute = 100
            entityA1.toManyRelationship = NSOrderedSet(array: Array(entityBArray.prefix(2)))

            let entityA2 = EntityA(context: viewContext)
            entityA2.attribute = 200
            entityA2.toManyRelationship = NSOrderedSet(array: Array(entityBArray.suffix(2)))

            try context.save()
        }
    }
    
    private func performManyToManyChanges(
        opInMemory: Operation,
        opInStore: Operation,
        mergePolicy: NSMergePolicy = .error
    ) throws {
        try insertNewItemsInToManyTable()

        // original context
        let viewContext = persistenceController.container.viewContext
        viewContext.mergePolicy = mergePolicy

        let fetchRequest: NSFetchRequest<EntityA> = EntityA.fetchRequest()
        try viewContext.performAndWait { context in
            let firstItem = try context.fetch(fetchRequest).first(where: { $0.attribute == 100 })!

            switch opInMemory {
            case .update:
                let mutableRelationships = firstItem.toManyRelationship?.mutableCopy() as! NSMutableOrderedSet
                // Remove EntityB(attribute: 10)
                let relationshipToRemove = mutableRelationships.filtered(using: NSPredicate(format: "%d = attribute", 10))
                mutableRelationships.minus(relationshipToRemove)
                firstItem.toManyRelationship = mutableRelationships
            case .delete:
                context.delete(firstItem)
            }
        }

        // new context
        let newBackgroundContext = persistenceController.container.newBackgroundContext()

        try newBackgroundContext.performAndWait { context in
            let firstItem = try context.fetch(fetchRequest).first(where: { $0.attribute == 100 })!

            switch opInStore {
            case .update:
                let mutableRelationships = firstItem.toManyRelationship?.mutableCopy() as! NSMutableOrderedSet
                // Remove EntityB(attribute: 11)
                let relationshipToRemove = mutableRelationships.filtered(using: NSPredicate(format: "%d = attribute", 11))
                mutableRelationships.minus(relationshipToRemove)
                firstItem.toManyRelationship = mutableRelationships
            case .delete:
                context.delete(firstItem)
            }

            try context.save()
        }

        try viewContext.performAndWait { context in
            try context.save()
        }
    }
}
