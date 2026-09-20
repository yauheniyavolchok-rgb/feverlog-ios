import Foundation
import SwiftData

/// Notes are always scoped to a child — there are no global/unscoped notes
/// in v1.
@Model
final class NoteEntry {
    var id: UUID
    var childID: UUID
    var child: Child?

    var text: String
    var recordedAt: Date

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var lastSyncedAt: Date?
    var syncVersion: Int

    init(
        id: UUID = UUID(),
        child: Child,
        text: String,
        recordedAt: Date,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.childID = child.id
        self.child = child
        self.text = text
        self.recordedAt = recordedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
        self.lastSyncedAt = nil
        self.syncVersion = 0
    }
}

extension NoteEntry: SyncableRecord {}
