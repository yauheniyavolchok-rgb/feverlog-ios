import Foundation
import SwiftData

@Model
final class QuickLogEntry {
    #Index<QuickLogEntry>([\.childID], [\.recordedAt], [\.deletedAt])

    var id: UUID
    var childID: UUID
    var child: Child?

    var type: QuickLogType
    /// 1-based index into `type.degreeLabels`.
    var degree: Int
    var recordedAt: Date

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var lastSyncedAt: Date?
    var syncVersion: Int

    init(
        id: UUID = UUID(),
        child: Child,
        type: QuickLogType,
        degree: Int,
        recordedAt: Date,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.childID = child.id
        self.child = child
        self.type = type
        self.degree = degree
        self.recordedAt = recordedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
        self.lastSyncedAt = nil
        self.syncVersion = 0
    }
}

extension QuickLogEntry: SyncableRecord {}
