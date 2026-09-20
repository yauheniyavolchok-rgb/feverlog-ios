import Foundation
import SwiftData
import Testing
@testable import FeverLog

@MainActor
@Suite("SyncDownloadImporter", .serialized)
struct SyncDownloadImporterTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainerFactory.makeInMemoryContainer()
    }

    private func makeChild(in context: ModelContext) throws -> Child {
        let household = try SwiftDataHouseholdRepository(context: context).createGuestHouseholdIfNeeded()
        return try SwiftDataChildRepository(context: context).create(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: "star.fill",
            avatarColorIdentifier: "mint",
            household: household
        )
    }

    private func makeRemoteTemperatureLog(
        id: UUID = UUID(),
        childID: UUID,
        celsius: Double = 38.0,
        recordedAt: Date = .now,
        updatedAt: Date,
        deletedAt: Date? = nil
    ) -> TemperatureLogRemoteRecord {
        TemperatureLogRemoteRecord(
            id: id,
            childID: childID,
            temperatureCelsius: celsius,
            measurementMethod: "oral",
            recordedAt: recordedAt,
            note: nil,
            createdBy: nil,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }

    @Test("importing a brand-new remote record creates it locally")
    func importsNewRecord() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeChild(in: context)
        let importer = SyncDownloadImporter(context: context)
        let remote = makeRemoteTemperatureLog(childID: child.id, updatedAt: .now)

        let applied = importer.importTemperatureLog(remote, child: child)

        #expect(applied)
        let local = try context.fetch(FetchDescriptor<TemperatureLog>())
        #expect(local.count == 1)
        #expect(local.first?.id == remote.id)
        #expect(local.first?.temperatureCelsius == 38.0)
    }

    @Test("a newer remote record overwrites the existing local one")
    func newerRemoteRecordWins() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeChild(in: context)
        let importer = SyncDownloadImporter(context: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let original = makeRemoteTemperatureLog(childID: child.id, celsius: 37.0, updatedAt: now)
        importer.importTemperatureLog(original, child: child)

        let newer = makeRemoteTemperatureLog(id: original.id, childID: child.id, celsius: 39.0, updatedAt: now.addingTimeInterval(60))
        let applied = importer.importTemperatureLog(newer, child: child)

        #expect(applied)
        let local = try context.fetch(FetchDescriptor<TemperatureLog>())
        #expect(local.count == 1)
        #expect(local.first?.temperatureCelsius == 39.0)
    }

    @Test("an older remote record never overwrites a newer local one")
    func olderRemoteRecordLoses() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeChild(in: context)
        let importer = SyncDownloadImporter(context: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let original = makeRemoteTemperatureLog(childID: child.id, celsius: 37.0, updatedAt: now)
        importer.importTemperatureLog(original, child: child)
        // Simulate a local edit that's newer than the remote record we're about to receive.
        let local = try #require(context.fetch(FetchDescriptor<TemperatureLog>()).first)
        local.temperatureCelsius = 40.0
        local.updatedAt = now.addingTimeInterval(120)
        try context.save()

        let stale = makeRemoteTemperatureLog(id: original.id, childID: child.id, celsius: 39.0, updatedAt: now.addingTimeInterval(60))
        let applied = importer.importTemperatureLog(stale, child: child)

        #expect(!applied)
        #expect(local.temperatureCelsius == 40.0)
    }

    @Test("importing the identical event twice is idempotent — no duplicate row, no error")
    func duplicateEventIsIdempotent() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeChild(in: context)
        let importer = SyncDownloadImporter(context: context)
        let remote = makeRemoteTemperatureLog(childID: child.id, updatedAt: .now)

        importer.importTemperatureLog(remote, child: child)
        let secondApplyResult = importer.importTemperatureLog(remote, child: child)

        // Re-applying the exact same (id, updatedAt) is not treated as a
        // remote win (equal timestamps, equal id) — a no-op, matching
        // ConflictResolver's "identical metadata never flips" guarantee.
        #expect(!secondApplyResult)
        #expect(try context.fetch(FetchDescriptor<TemperatureLog>()).count == 1)
    }

    @Test("a newer remote tombstone soft-deletes the local record")
    func newerRemoteTombstoneDeletes() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeChild(in: context)
        let importer = SyncDownloadImporter(context: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let original = makeRemoteTemperatureLog(childID: child.id, updatedAt: now)
        importer.importTemperatureLog(original, child: child)

        let tombstone = makeRemoteTemperatureLog(
            id: original.id,
            childID: child.id,
            updatedAt: now.addingTimeInterval(60),
            deletedAt: now.addingTimeInterval(60)
        )
        importer.importTemperatureLog(tombstone, child: child)

        let local = try #require(context.fetch(FetchDescriptor<TemperatureLog>()).first)
        #expect(local.deletedAt != nil)
    }

    @Test("an older remote update never resurrects a newer local tombstone")
    func olderRemoteUpdateCannotResurrectTombstone() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeChild(in: context)
        let importer = SyncDownloadImporter(context: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let original = makeRemoteTemperatureLog(childID: child.id, updatedAt: now)
        importer.importTemperatureLog(original, child: child)

        let local = try #require(context.fetch(FetchDescriptor<TemperatureLog>()).first)
        local.markSoftDeleted(at: now.addingTimeInterval(120))
        try context.save()

        let staleUpdate = makeRemoteTemperatureLog(id: original.id, childID: child.id, celsius: 41.0, updatedAt: now.addingTimeInterval(60))
        let applied = importer.importTemperatureLog(staleUpdate, child: child)

        #expect(!applied)
        #expect(local.deletedAt != nil)
    }

    @Test("importing a new remote child creates it under the given household")
    func importsNewChild() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let household = try SwiftDataHouseholdRepository(context: context).createGuestHouseholdIfNeeded()
        household.remoteHouseholdID = household.id
        let importer = SyncDownloadImporter(context: context)
        let remote = ChildRemoteRecord(
            id: UUID(),
            householdID: household.id,
            name: "Leo",
            birthday: "2023-05-01",
            avatarIdentifier: "star.fill",
            avatarColorIdentifier: "mint",
            cachedWeightValue: nil,
            cachedWeightUnit: nil,
            createdBy: nil,
            createdAt: .now,
            updatedAt: .now,
            deletedAt: nil
        )

        let applied = importer.importChild(remote, household: household)

        #expect(applied)
        let local = try context.fetch(FetchDescriptor<Child>())
        #expect(local.count == 1)
        #expect(local.first?.name == "Leo")
    }
}
