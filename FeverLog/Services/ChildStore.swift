import Foundation
import Observation
import SwiftData

/// Holds the current household's children and the selected child, backed by
/// SwiftData. Views read child state from here rather than querying
/// repositories directly, so there is a single in-memory reflection of the
/// local source of truth shared across Home/Timeline/Charts/Settings.
@Observable
@MainActor
final class ChildStore {
    private var householdRepository: HouseholdRepository?
    private var childRepository: ChildRepository?

    private(set) var household: Household?
    private(set) var children: [Child] = []
    private(set) var isLoaded = false

    var selectedChildID: UUID?

    var selectedChild: Child? {
        children.first { $0.id == selectedChildID }
    }

    /// Must be called once a `ModelContext` is available (SwiftUI environment
    /// values aren't available at `init` time).
    func configure(context: ModelContext) {
        guard householdRepository == nil else { return }
        householdRepository = SwiftDataHouseholdRepository(context: context)
        childRepository = SwiftDataChildRepository(context: context)
    }

    func loadInitialStateIfNeeded() throws {
        guard !isLoaded, let householdRepository else { return }
        let household = try householdRepository.createGuestHouseholdIfNeeded()
        self.household = household
        try refreshChildren()
        isLoaded = true
    }

    func refreshChildren() throws {
        guard let household, let childRepository else { return }
        children = try childRepository.fetchActiveChildren(in: household)
        if let selectedChildID, children.contains(where: { $0.id == selectedChildID }) {
            return
        }
        selectedChildID = children.first?.id
    }

    @discardableResult
    func createChild(
        name: String,
        birthday: Date,
        avatarIdentifier: String,
        avatarColorIdentifier: String
    ) throws -> Child? {
        guard let household, let childRepository else { return nil }
        let child = try childRepository.create(
            name: name,
            birthday: birthday,
            avatarIdentifier: avatarIdentifier,
            avatarColorIdentifier: avatarColorIdentifier,
            household: household
        )
        try refreshChildren()
        selectedChildID = child.id
        return child
    }

    /// Persists in-place mutations already made to a fetched `Child`.
    func updateChild(_ child: Child) throws {
        guard let childRepository else { return }
        try childRepository.update(child)
        try refreshChildren()
    }

    func softDelete(_ child: Child) throws {
        guard let childRepository else { return }
        try childRepository.softDelete(child)
        try refreshChildren()
    }
}
