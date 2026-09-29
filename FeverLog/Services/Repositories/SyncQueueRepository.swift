import Foundation
import SwiftData

@MainActor
protocol SyncQueueRepository {
    func enqueue(
        entityType: String,
        entityID: UUID,
        operationType: SyncOperationType,
        payload: Data?,
        idempotencyKey: String
    ) throws -> SyncQueueItem

    /// Creates a new pending queue item for (entityType, entityID), or —
    /// if a pending or failed-not-yet-retried item for the same entity
    /// already exists — replaces its payload/operation in place instead of
    /// adding a second one. This is always safe: the item being replaced
    /// was never successfully uploaded, so nothing already-sent is lost,
    /// and the newer local state is exactly what should be sent next.
    /// An item currently `.inFlight` is left alone; a fresh item is
    /// created instead so an in-progress upload is never mutated mid-send.
    @discardableResult
    func enqueueOrCoalesce(
        entityType: String,
        entityID: UUID,
        operationType: SyncOperationType,
        payload: Data?
    ) throws -> SyncQueueItem

    func fetchPending() throws -> [SyncQueueItem]

    /// Items ready to attempt right now: pending items, plus failed items
    /// whose backoff window has elapsed.
    func fetchReadyForUpload(now: Date) throws -> [SyncQueueItem]

    func markInFlight(_ item: SyncQueueItem) throws
    func markCompleted(_ item: SyncQueueItem) throws
    func markFailed(_ item: SyncQueueItem, error: String, nextRetryAt: Date) throws

    /// Deletes completed items older than `cutoff`. Without this, the
    /// queue table grows forever — every local write enqueues a row that,
    /// once uploaded, just sits there — and every subsequent enqueue pays
    /// the cost of scanning past it.
    func purgeCompleted(olderThan cutoff: Date) throws
}

@MainActor
final class SwiftDataSyncQueueRepository: SyncQueueRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func enqueue(
        entityType: String,
        entityID: UUID,
        operationType: SyncOperationType,
        payload: Data?,
        idempotencyKey: String
    ) throws -> SyncQueueItem {
        let item = SyncQueueItem(
            entityType: entityType,
            entityID: entityID,
            operationType: operationType,
            payload: payload,
            idempotencyKey: idempotencyKey
        )
        context.insert(item)
        try context.save()
        return item
    }

    @discardableResult
    func enqueueOrCoalesce(
        entityType: String,
        entityID: UUID,
        operationType: SyncOperationType,
        payload: Data?
    ) throws -> SyncQueueItem {
        // Predicate-filtered to just this entity's own (small) history,
        // rather than fetching every queue item in the table to filter
        // in-process — this runs on every single local write.
        let predicate = #Predicate<SyncQueueItem> {
            $0.entityType == entityType && $0.entityID == entityID && $0.completedAt == nil
        }
        let descriptor = FetchDescriptor<SyncQueueItem>(predicate: predicate)
        let coalescable = try context.fetch(descriptor)
            .filter { $0.status == .pending || $0.status == .failed }

        if let existing = coalescable.first {
            existing.operationType = operationType
            existing.payload = payload
            existing.status = .pending
            existing.nextRetryAt = nil
            existing.lastError = nil
            try context.save()
            return existing
        }

        return try enqueue(
            entityType: entityType,
            entityID: entityID,
            operationType: operationType,
            payload: payload,
            idempotencyKey: UUID().uuidString
        )
    }

    func fetchPending() throws -> [SyncQueueItem] {
        try activeItems().filter { $0.status == .pending }
    }

    func fetchReadyForUpload(now: Date) throws -> [SyncQueueItem] {
        try activeItems().filter { item in
            switch item.status {
            case .pending:
                return true
            case .failed:
                guard let nextRetryAt = item.nextRetryAt else { return true }
                return nextRetryAt <= now
            case .inFlight, .completed:
                return false
            }
        }
    }

    func markInFlight(_ item: SyncQueueItem) throws {
        item.status = .inFlight
        try context.save()
    }

    func markCompleted(_ item: SyncQueueItem) throws {
        item.status = .completed
        item.lastError = nil
        item.completedAt = .now
        try context.save()
    }

    func markFailed(_ item: SyncQueueItem, error: String, nextRetryAt: Date) throws {
        item.status = .failed
        item.retryCount += 1
        item.lastError = error
        item.nextRetryAt = nextRetryAt
        try context.save()
    }

    func purgeCompleted(olderThan cutoff: Date) throws {
        // `#Predicate` doesn't support force-unwrapping an optional, so
        // the date comparison itself happens in-process — but the fetch
        // is still predicate-scoped to just the completed subset, not
        // the whole (much larger, ever-growing) table.
        let predicate = #Predicate<SyncQueueItem> { $0.completedAt != nil }
        let completedItems = try context.fetch(FetchDescriptor<SyncQueueItem>(predicate: predicate))
        for item in completedItems where (item.completedAt ?? .distantFuture) < cutoff {
            context.delete(item)
        }
        try context.save()
    }

    // SwiftData's #Predicate macro does not support comparing a captured
    // Codable enum constant, so `status` is always filtered in-process —
    // but `completedAt == nil` is a reliable proxy for "not completed"
    // that IS predicate-safe, and excludes the table's fastest-growing,
    // otherwise-permanent set of rows before anything reaches memory.
    private func activeItems() throws -> [SyncQueueItem] {
        let predicate = #Predicate<SyncQueueItem> { $0.completedAt == nil }
        let descriptor = FetchDescriptor<SyncQueueItem>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor)
    }
}
