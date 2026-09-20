import Foundation
import SwiftData

/// A local installation always has a guest household before authentication.
/// A guest household is local-only until it is explicitly linked or migrated
/// to an authenticated household (Phase 9).
@Model
final class Household {
    var id: UUID
    var displayName: String
    var remoteHouseholdID: UUID?
    var isGuest: Bool

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var lastSyncedAt: Date?
    var syncVersion: Int

    @Relationship(deleteRule: .cascade, inverse: \HouseholdMember.household)
    var members: [HouseholdMember] = []

    @Relationship(deleteRule: .cascade, inverse: \Child.household)
    var children: [Child] = []

    init(
        id: UUID = UUID(),
        displayName: String,
        remoteHouseholdID: UUID? = nil,
        isGuest: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.remoteHouseholdID = remoteHouseholdID
        self.isGuest = isGuest
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
        self.lastSyncedAt = nil
        self.syncVersion = 0
    }
}

extension Household: SyncableRecord {}
