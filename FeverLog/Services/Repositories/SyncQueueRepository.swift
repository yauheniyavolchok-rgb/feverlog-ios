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
        let coalescable = try allItems()
            .filter { $0.entityType == entityType && $0.entityID == entityID }
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
        try allItems().filter { $0.status == .pending }
    }

    func fetchReadyForUpload(now: Date) throws -> [SyncQueueItem] {
        try allItems().filter { item in
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
        try context.save()
    }

    func markFailed(_ item: SyncQueueItem, error: String, nextRetryAt: Date) throws {
        item.status = .failed
        item.retryCount += 1
        item.lastError = error
        item.nextRetryAt = nextRetryAt
        try context.save()
    }

    // SwiftData's #Predicate macro does not support comparing a captured
    // Codable enum constant, so status is always filtered in-process.
    private func allItems() throws -> [SyncQueueItem] {
        let descriptor = FetchDescriptor<SyncQueueItem>(sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor)
    }
}
