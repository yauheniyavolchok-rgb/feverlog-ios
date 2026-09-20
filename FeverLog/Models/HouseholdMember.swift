import Foundation
import SwiftData

/// v1 grants identical *data* permissions to every member — `owner` vs
/// `member` only distinguishes who may generate invites and never gates
/// access to household records themselves.
enum HouseholdMemberRole: String, Codable, Sendable {
    case owner
    case member
}

@Model
final class HouseholdMember {
    var id: UUID
    var remoteMemberID: UUID?
    var householdID: UUID
    var household: Household?
    var displayName: String
    var role: HouseholdMemberRole

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var lastSyncedAt: Date?
    var syncVersion: Int

    init(
        id: UUID = UUID(),
        remoteMemberID: UUID? = nil,
        household: Household,
        displayName: String,
        role: HouseholdMemberRole = .member,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.remoteMemberID = remoteMemberID
        self.householdID = household.id
        self.household = household
        self.displayName = displayName
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
        self.lastSyncedAt = nil
        self.syncVersion = 0
    }
}

extension HouseholdMember: SyncableRecord {}
