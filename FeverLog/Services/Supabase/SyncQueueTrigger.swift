import Foundation
import SwiftData

/// Called by each domain repository right after a local create/update/
/// soft-delete commits, per the sync architecture's local-write step:
/// "commit local transaction → create or coalesce SyncQueueItem →
/// attempt background synchronization if possible." The actual upload
/// payload is built later, fresh, by `SyncUploadProcessor` — this only
/// marks the entity as needing a sync attempt. Every local write is an
/// upsert remotely, including soft deletes (a soft delete is just an
/// ordinary field change to `deletedAt`).
@MainActor
enum SyncQueueTrigger {
    static func enqueue(entityType: String, entityID: UUID, context: ModelContext) {
        try? SwiftDataSyncQueueRepository(context: context).enqueueOrCoalesce(
            entityType: entityType,
            entityID: entityID,
            operationType: .upsert,
            payload: nil
        )
    }
}
