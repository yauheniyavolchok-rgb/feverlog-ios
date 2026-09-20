import Foundation
import SwiftData

enum SyncOperationType: String, Codable, Sendable {
    case upsert
    case delete
}

enum SyncQueueStatus: String, Codable, Sendable {
    case pending
    case inFlight
    case completed
    case failed
}

/// The sync queue is an implementation detail of Phase 9's synchronization
/// pipeline. It must never become a second source of truth for domain
/// records — domain state always lives on the record itself.
@Model
final class SyncQueueItem {
    var id: UUID

    var entityType: String
    var entityID: UUID
    var operationType: SyncOperationType
    var payload: Data?

    var createdAt: Date
    var retryCount: Int
    var lastError: String?
    var status: SyncQueueStatus
    var nextRetryAt: Date?
    var idempotencyKey: String

    init(
        id: UUID = UUID(),
        entityType: String,
        entityID: UUID,
        operationType: SyncOperationType,
        payload: Data? = nil,
        idempotencyKey: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.entityType = entityType
        self.entityID = entityID
        self.operationType = operationType
        self.payload = payload
        self.idempotencyKey = idempotencyKey
        self.createdAt = createdAt
        self.retryCount = 0
        self.lastError = nil
        self.status = .pending
        self.nextRetryAt = nil
    }
}
