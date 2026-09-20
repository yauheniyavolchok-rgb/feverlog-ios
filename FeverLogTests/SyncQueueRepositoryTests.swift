import Foundation
import SwiftData
import Testing
@testable import FeverLog

@MainActor
@Suite("SyncQueueRepository coalescing and retry", .serialized)
struct SyncQueueRepositoryTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainerFactory.makeInMemoryContainer()
    }

    @Test("enqueueOrCoalesce creates exactly one item for repeated writes to the same entity")
    func coalescesRepeatedWrites() throws {
        let container = try makeContainer()
        let repository = SwiftDataSyncQueueRepository(context: container.mainContext)
        let entityID = UUID()

        try repository.enqueueOrCoalesce(entityType: "temperature_logs", entityID: entityID, operationType: .upsert, payload: nil)
        try repository.enqueueOrCoalesce(entityType: "temperature_logs", entityID: entityID, operationType: .upsert, payload: nil)
        try repository.enqueueOrCoalesce(entityType: "temperature_logs", entityID: entityID, operationType: .upsert, payload: nil)

        #expect(try repository.fetchPending().count == 1)
    }

    @Test("coalescing does not affect a different entity's queue item")
    func coalescingIsScopedPerEntity() throws {
        let container = try makeContainer()
        let repository = SwiftDataSyncQueueRepository(context: container.mainContext)

        try repository.enqueueOrCoalesce(entityType: "temperature_logs", entityID: UUID(), operationType: .upsert, payload: nil)
        try repository.enqueueOrCoalesce(entityType: "temperature_logs", entityID: UUID(), operationType: .upsert, payload: nil)

        #expect(try repository.fetchPending().count == 2)
    }

    @Test("a completed item does not get coalesced into — a fresh item is created instead")
    func completedItemsAreNotCoalescedInto() throws {
        let container = try makeContainer()
        let repository = SwiftDataSyncQueueRepository(context: container.mainContext)
        let entityID = UUID()

        let first = try repository.enqueueOrCoalesce(entityType: "notes", entityID: entityID, operationType: .upsert, payload: nil)
        try repository.markCompleted(first)

        try repository.enqueueOrCoalesce(entityType: "notes", entityID: entityID, operationType: .upsert, payload: nil)

        #expect(try repository.fetchPending().count == 1)
    }

    @Test("fetchReadyForUpload includes pending items and excludes failed items still in backoff")
    func readyForUploadExcludesBackoffWindow() throws {
        let container = try makeContainer()
        let repository = SwiftDataSyncQueueRepository(context: container.mainContext)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let pendingItem = try repository.enqueueOrCoalesce(entityType: "notes", entityID: UUID(), operationType: .upsert, payload: nil)
        let failedItem = try repository.enqueueOrCoalesce(entityType: "notes", entityID: UUID(), operationType: .upsert, payload: nil)
        try repository.markFailed(failedItem, error: "network", nextRetryAt: now.addingTimeInterval(300))

        let ready = try repository.fetchReadyForUpload(now: now)
        #expect(ready.map(\.id) == [pendingItem.id])
    }

    @Test("fetchReadyForUpload includes a failed item once its backoff window has elapsed")
    func readyForUploadIncludesElapsedBackoff() throws {
        let container = try makeContainer()
        let repository = SwiftDataSyncQueueRepository(context: container.mainContext)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let failedItem = try repository.enqueueOrCoalesce(entityType: "notes", entityID: UUID(), operationType: .upsert, payload: nil)
        try repository.markFailed(failedItem, error: "network", nextRetryAt: now.addingTimeInterval(-1))

        let ready = try repository.fetchReadyForUpload(now: now)
        #expect(ready.map(\.id) == [failedItem.id])
    }

    @Test("fetchReadyForUpload excludes in-flight and completed items")
    func readyForUploadExcludesInFlightAndCompleted() throws {
        let container = try makeContainer()
        let repository = SwiftDataSyncQueueRepository(context: container.mainContext)

        let inFlightItem = try repository.enqueueOrCoalesce(entityType: "notes", entityID: UUID(), operationType: .upsert, payload: nil)
        try repository.markInFlight(inFlightItem)

        let completedItem = try repository.enqueueOrCoalesce(entityType: "notes", entityID: UUID(), operationType: .upsert, payload: nil)
        try repository.markCompleted(completedItem)

        #expect(try repository.fetchReadyForUpload(now: .now).isEmpty)
    }

    @Test("markFailed increments retryCount and records the error")
    func markFailedIncrementsRetryCount() throws {
        let container = try makeContainer()
        let repository = SwiftDataSyncQueueRepository(context: container.mainContext)
        let item = try repository.enqueueOrCoalesce(entityType: "notes", entityID: UUID(), operationType: .upsert, payload: nil)

        try repository.markFailed(item, error: "boom", nextRetryAt: .now.addingTimeInterval(10))
        try repository.markFailed(item, error: "boom again", nextRetryAt: .now.addingTimeInterval(20))

        #expect(item.retryCount == 2)
        #expect(item.lastError == "boom again")
        #expect(item.status == .failed)
    }

    @Test("re-enqueuing after a failure clears the error and backoff")
    func reenqueueClearsFailureState() throws {
        let container = try makeContainer()
        let repository = SwiftDataSyncQueueRepository(context: container.mainContext)
        let entityID = UUID()
        let item = try repository.enqueueOrCoalesce(entityType: "notes", entityID: entityID, operationType: .upsert, payload: nil)
        try repository.markFailed(item, error: "boom", nextRetryAt: .now.addingTimeInterval(300))

        try repository.enqueueOrCoalesce(entityType: "notes", entityID: entityID, operationType: .upsert, payload: nil)

        #expect(item.status == .pending)
        #expect(item.lastError == nil)
        #expect(item.nextRetryAt == nil)
    }
}
