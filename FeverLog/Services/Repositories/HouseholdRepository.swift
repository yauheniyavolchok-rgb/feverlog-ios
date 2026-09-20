import Foundation
import SwiftData

@MainActor
protocol HouseholdRepository {
    func fetchActiveHouseholds() throws -> [Household]
    /// Returns the existing local household, or creates one if none
    /// exists yet. Never makes a network request. v1 supports exactly one
    /// local household per device — see the multi-household migration TODO
    /// in the Phase 9 spec for why a second is never created here.
    func createGuestHouseholdIfNeeded() throws -> Household
    /// Persists in-place mutations already made to a fetched `Household`
    /// (e.g. `remoteHouseholdID` once the Supabase sync coordinator links
    /// it).
    func update(_ household: Household) throws
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
        if let existing = try fetchActiveHouseholds().first {
            return existing
        }
        let household = Household(displayName: L10n.Household.defaultDisplayName, isGuest: true)
        context.insert(household)
        try context.save()
        return household
    }

    func update(_ household: Household) throws {
        household.updatedAt = .now
        try context.save()
    }
}
