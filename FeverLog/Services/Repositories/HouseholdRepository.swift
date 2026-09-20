import Foundation
import SwiftData

@MainActor
protocol HouseholdRepository {
    func fetchActiveHouseholds() throws -> [Household]
    /// Returns the existing local guest household, or creates one if none
    /// exists yet. Never makes a network request.
    func createGuestHouseholdIfNeeded() throws -> Household
}

@MainActor
final class SwiftDataHouseholdRepository: HouseholdRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchActiveHouseholds() throws -> [Household] {
        let predicate = #Predicate<Household> { $0.deletedAt == nil }
        let descriptor = FetchDescriptor<Household>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor)
    }

    func createGuestHouseholdIfNeeded() throws -> Household {
        if let existing = try fetchActiveHouseholds().first(where: { $0.isGuest }) {
            return existing
        }
        let household = Household(displayName: L10n.Household.defaultDisplayName, isGuest: true)
        context.insert(household)
        try context.save()
        return household
    }
}
