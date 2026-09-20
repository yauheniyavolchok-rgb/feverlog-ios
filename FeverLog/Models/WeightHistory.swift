import Foundation
import SwiftData

@Model
final class WeightHistory {
    var id: UUID
    var childID: UUID
    var child: Child?

    var weight: Double
    var unit: WeightUnit
    var effectiveDate: Date

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var lastSyncedAt: Date?
    var syncVersion: Int

    init(
        id: UUID = UUID(),
        child: Child,
        weight: Double,
        unit: WeightUnit,
        effectiveDate: Date,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.childID = child.id
        self.child = child
        self.weight = weight
        self.unit = unit
        self.effectiveDate = effectiveDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
        self.lastSyncedAt = nil
        self.syncVersion = 0
    }
}

extension WeightHistory: SyncableRecord {}
