import Foundation
import Supabase
import SwiftData
import Testing
@testable import FeverLog

private final class FakeSyncUploadClient: SyncUploadClient, @unchecked Sendable {
    private(set) var upsertCalls: [(table: String, json: AnyJSON)] = []
    var errorForTable: [String: Error] = [:]

    func upsert(table: String, json: AnyJSON) async throws {
        if let error = errorForTable[table] {
            throw error
        }
        upsertCalls.append((table, json))
    }
}

private struct FakeUploadError: Error {}

@MainActor
@Suite("SyncUploadProcessor", .serialized)
struct SyncUploadProcessorTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainerFactory.makeInMemoryContainer()
    }

    private func makeLinkedChild(in context: ModelContext) throws -> Child {
        let household = try SwiftDataHouseholdRepository(context: context).createGuestHouseholdIfNeeded()
        household.remoteHouseholdID = household.id
        try SwiftDataHouseholdRepository(context: context).update(household)
        return try SwiftDataChildRepository(context: context).create(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: "star.fill",
            avatarColorIdentifier: "mint",
            household: household
        )
    }

    @Test("uploads a pending child and marks the queue item completed")
    func uploadsPendingChild() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeLinkedChild(in: context)
        let queueRepository = SwiftDataSyncQueueRepository(context: context)
        let uploadClient = FakeSyncUploadClient()
        let processor = SyncUploadProcessor(context: context, queueRepository: queueRepository, uploadClient: uploadClient)

        await processor.processPendingUploads()

        #expect(uploadClient.upsertCalls.map(\.table) == ["children"])
        let remaining = try queueRepository.fetchReadyForUpload(now: .now)
        #expect(remaining.isEmpty)
        _ = child
    }

    @Test("an item for a child whose household isn't linked yet is left pending, not attempted")
    func unlinkedHouseholdItemIsSkipped() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let household = try SwiftDataHouseholdRepository(context: context).createGuestHouseholdIfNeeded()
        // Deliberately not linking remoteHouseholdID.
        _ = try SwiftDataChildRepository(context: context).create(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: "star.fill",
            avatarColorIdentifier: "mint",
            household: household
        )
        let queueRepository = SwiftDataSyncQueueRepository(context: context)
        let uploadClient = FakeSyncUploadClient()
        let processor = SyncUploadProcessor(context: context, queueRepository: queueRepository, uploadClient: uploadClient)

        await processor.processPendingUploads()

        #expect(uploadClient.upsertCalls.isEmpty)
        #expect(try queueRepository.fetchPending().count == 1)
    }

    @Test("a nil upload client (Supabase not configured) never attempts anything")
    func nilClientNeverUploads() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeLinkedChild(in: context)
        _ = child
        let queueRepository = SwiftDataSyncQueueRepository(context: context)
        let processor = SyncUploadProcessor(context: context, queueRepository: queueRepository, uploadClient: nil)

        await processor.processPendingUploads()

        #expect(try queueRepository.fetchPending().count == 1)
    }

    @Test("running two cycles back to back is idempotent — a completed item is never re-uploaded")
    func rerunningIsIdempotent() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeLinkedChild(in: context)
        _ = child
        let queueRepository = SwiftDataSyncQueueRepository(context: context)
        let uploadClient = FakeSyncUploadClient()
        let processor = SyncUploadProcessor(context: context, queueRepository: queueRepository, uploadClient: uploadClient)

        await processor.processPendingUploads()
        await processor.processPendingUploads()

        #expect(uploadClient.upsertCalls.count == 1)
    }

    @Test("a failed upload schedules a bounded-backoff retry without losing the local record")
    func failedUploadSchedulesRetry() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeLinkedChild(in: context)
        _ = child
        let queueRepository = SwiftDataSyncQueueRepository(context: context)
        let uploadClient = FakeSyncUploadClient()
        uploadClient.errorForTable["children"] = FakeUploadError()
        let processor = SyncUploadProcessor(context: context, queueRepository: queueRepository, uploadClient: uploadClient)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        await processor.processPendingUploads(now: now)

        let item = try queueRepository.fetchPending().first
        #expect(item == nil) // no longer "pending" — it's "failed" now
        #expect(try context.fetch(FetchDescriptor<Child>()).count == 1) // local record untouched

        let readyImmediately = try queueRepository.fetchReadyForUpload(now: now)
        #expect(readyImmediately.isEmpty)

        let readyAfterBackoff = try queueRepository.fetchReadyForUpload(now: now.addingTimeInterval(SyncRetryPolicy.delay(forAttempt: 0)))
        #expect(readyAfterBackoff.count == 1)
    }

    @Test("children upload before other entity types in the same cycle")
    func childrenUploadFirst() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeLinkedChild(in: context)
        _ = try SwiftDataTemperatureLogRepository(context: context).create(
            temperatureCelsius: 37.5,
            measurementMethod: .oral,
            recordedAt: .now,
            note: nil,
            child: child
        )
        let queueRepository = SwiftDataSyncQueueRepository(context: context)
        let uploadClient = FakeSyncUploadClient()
        let processor = SyncUploadProcessor(context: context, queueRepository: queueRepository, uploadClient: uploadClient)

        await processor.processPendingUploads()

        #expect(uploadClient.upsertCalls.first?.table == "children")
        #expect(Set(uploadClient.upsertCalls.map(\.table)) == ["children", "temperature_logs"])
    }
}
