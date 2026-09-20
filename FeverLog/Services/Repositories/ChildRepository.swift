import Foundation
import SwiftData

@MainActor
protocol ChildRepository {
    func fetchActiveChildren(in household: Household) throws -> [Child]
    func create(
        name: String,
        birthday: Date,
        avatarIdentifier: String,
        avatarColorIdentifier: String,
        household: Household
    ) throws -> Child
    /// Persists in-place mutations already made to a fetched `Child`.
    func update(_ child: Child) throws
    func softDelete(_ child: Child) throws
}

@MainActor
final class SwiftDataChildRepository: ChildRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchActiveChildren(in household: Household) throws -> [Child] {
        let householdID = household.id
        let predicate = #Predicate<Child> { $0.deletedAt == nil && $0.householdID == householdID }
        let descriptor = FetchDescriptor<Child>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor)
    }

    func create(
        name: String,
        birthday: Date,
        avatarIdentifier: String,
        avatarColorIdentifier: String,
        household: Household
    ) throws -> Child {
        let child = Child(
            household: household,
            name: name,
            birthday: birthday,
            avatarIdentifier: avatarIdentifier,
            avatarColorIdentifier: avatarColorIdentifier
        )
        context.insert(child)
        try context.save()
        return child
    }

    func update(_ child: Child) throws {
        child.updatedAt = .now
        try context.save()
    }

    func softDelete(_ child: Child) throws {
        child.markSoftDeleted()
        try context.save()
    }
}
