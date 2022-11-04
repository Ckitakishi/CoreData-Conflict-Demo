//
//  NSManagedObjectContext+Extensions.swift
//  CoreDataConflictDemoTests
//
//  Created by Yuhan Chen on 2022/11/04.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    /// An wrapper of performAndWait(_ block: () -> Void) that can re-throw error or return value captured by closure.
    ///
    /// - Returns: A value we want to use outside of the closure.
    @discardableResult
    func performAndWait<T>(_ closure: (NSManagedObjectContext) throws -> T) throws -> T {
        var result: T?
        var errorToRethrow: Error?

        performAndWait {
            do {
                result = try closure(self)
            }
            catch {
                errorToRethrow = error
            }
        }

        if let errorToRethrow = errorToRethrow {
            throw errorToRethrow
        }
        else {
            // Must have a entity or an error.
            return result!
        }
    }
}
