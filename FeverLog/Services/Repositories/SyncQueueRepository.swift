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
    func fetchPending() throws -> [SyncQueueItem]
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

    func fetchPending() throws -> [SyncQueueItem] {
        // SwiftData's #Predicate macro does not support comparing a captured
        // Codable enum constant, so status is filtered in-process instead.
        let descriptor = FetchDescriptor<SyncQueueItem>(sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor).filter { $0.status == .pending }
    }
}
