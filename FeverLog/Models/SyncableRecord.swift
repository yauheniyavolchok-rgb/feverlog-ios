import Foundation

/// Shared shape for every domain record that may synchronize to a household.
/// `updatedAt` must change on every local mutation, including soft deletion.
/// `deletedAt` represents a soft-delete tombstone — records are never
/// physically removed by application code in v1.
protocol SyncableRecord: AnyObject {
    var id: UUID { get }
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
    var deletedAt: Date? { get set }
    var lastSyncedAt: Date? { get set }
    var syncVersion: Int { get set }
}

extension SyncableRecord {
    var isDeleted: Bool { deletedAt != nil }

    /// Marks the record as soft-deleted. Callers are still responsible for
    /// persisting the change and enqueuing a sync operation.
    func markSoftDeleted(at date: Date = .now) {
        deletedAt = date
        updatedAt = date
    }
}
