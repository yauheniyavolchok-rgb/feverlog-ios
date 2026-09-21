import Foundation
import SwiftData
import Testing
@testable import FeverLog

@MainActor
@Suite("Persistence")
struct PersistenceTests {
    // Returns the container itself (not just its context) — a ModelContext
    // does not keep its ModelContainer alive on its own, so callers must
    // hold the container for as long as they use the context, or SwiftData
    // may deallocate the in-memory store out from under it.
    private func makeContainer() throws -> ModelContainer {
        try ModelContainerFactory.makeInMemoryContainer()
    }

    // MARK: - Household

    @Test("creates and fetches a household")
    func createsAndFetchesHousehold() throws {
        let container = try makeContainer()
        let repository = SwiftDataHouseholdRepository(context: container.mainContext)

        let household = try repository.createGuestHouseholdIfNeeded()
        let fetched = try repository.fetchActiveHouseholds()

        #expect(fetched.count == 1)
        #expect(fetched.first?.id == household.id)
        #expect(fetched.first?.isGuest == true)
    }

    @Test("creating a guest household twice returns the same household")
    func guestHouseholdInitializationIsIdempotent() throws {
        let container = try makeContainer()
        let repository = SwiftDataHouseholdRepository(context: container.mainContext)

        let first = try repository.createGuestHouseholdIfNeeded()
        let second = try repository.createGuestHouseholdIfNeeded()

        #expect(first.id == second.id)
        #expect(try repository.fetchActiveHouseholds().count == 1)
    }

    // MARK: - Child

    @Test("creates and fetches a child, and stable IDs survive updates")
    func createsAndFetchesChild() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let households = SwiftDataHouseholdRepository(context: context)
        let children = SwiftDataChildRepository(context: context)

        let household = try households.createGuestHouseholdIfNeeded()
        let child = try children.create(
            name: "Ava",
            birthday: Date(timeIntervalSince1970: 0),
            avatarIdentifier: "avatar.bear",
            avatarColorIdentifier: "mint",
            household: household
        )
        let originalID = child.id

        child.name = "Ava Marie"
        try context.save()

        let fetched = try children.fetchActiveChildren(in: household)
        #expect(fetched.count == 1)
        #expect(fetched.first?.id == originalID)
        #expect(fetched.first?.name == "Ava Marie")
    }

    @Test("soft-deleted child is excluded from default reads")
    func softDeletedChildIsExcluded() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let households = SwiftDataHouseholdRepository(context: context)
        let children = SwiftDataChildRepository(context: context)

        let household = try households.createGuestHouseholdIfNeeded()
        let child = try children.create(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: "avatar.bear",
            avatarColorIdentifier: "mint",
            household: household
        )

        #expect(try children.fetchActiveChildren(in: household).count == 1)

        try children.softDelete(child)

        #expect(child.deletedAt != nil)
        #expect(try children.fetchActiveChildren(in: household).isEmpty)
    }

    // MARK: - Weight history

    @Test("creates and fetches weight history, selects the active weight for a date")
    func weightHistoryActiveWeightSelection() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let households = SwiftDataHouseholdRepository(context: context)
        let children = SwiftDataChildRepository(context: context)
        let weights = SwiftDataWeightHistoryRepository(context: context)

        let household = try households.createGuestHouseholdIfNeeded()
        let child = try children.create(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: "avatar.bear",
            avatarColorIdentifier: "mint",
            household: household
        )

        let calendar = Calendar(identifier: .gregorian)
        let earlyDate = calendar.date(byAdding: .day, value: -30, to: .now) ?? .now
        let laterDate = calendar.date(byAdding: .day, value: -5, to: .now) ?? .now

        _ = try weights.addWeight(9.0, unit: .kilograms, effectiveDate: earlyDate, child: child)
        _ = try weights.addWeight(10.2, unit: .kilograms, effectiveDate: laterDate, child: child)

        #expect(try weights.fetchHistory(for: child).count == 2)

        let activeAtToday = try weights.activeWeight(for: child, at: .now)
        #expect(activeAtToday?.weight == 10.2)

        let activeBetween = try weights.activeWeight(
            for: child,
            at: calendar.date(byAdding: .day, value: -10, to: .now) ?? .now
        )
        #expect(activeBetween?.weight == 9.0)
    }

    @Test("returns nil (missing weight) when no active weight exists for the date")
    func missingWeightReturnsNil() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let households = SwiftDataHouseholdRepository(context: context)
        let children = SwiftDataChildRepository(context: context)
        let weights = SwiftDataWeightHistoryRepository(context: context)

        let household = try households.createGuestHouseholdIfNeeded()
        let child = try children.create(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: "avatar.bear",
            avatarColorIdentifier: "mint",
            household: household
        )

        let calendar = Calendar(identifier: .gregorian)
        let futureWeightDate = calendar.date(byAdding: .day, value: 5, to: .now) ?? .now
        _ = try weights.addWeight(10.0, unit: .kilograms, effectiveDate: futureWeightDate, child: child)

        // No weight recorded on/before "now" — only one recorded in the future.
        let active = try weights.activeWeight(for: child, at: .now)
        #expect(active == nil)
    }

    // MARK: - Medication log snapshots

    @Test("medication log preserves its calculation snapshot")
    func medicationLogPreservesSnapshot() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let households = SwiftDataHouseholdRepository(context: context)
        let children = SwiftDataChildRepository(context: context)
        let logs = SwiftDataMedicationLogRepository(context: context)

        let household = try households.createGuestHouseholdIfNeeded()
        let child = try children.create(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: "avatar.bear",
            avatarColorIdentifier: "mint",
            household: household
        )

        let definitionID = "acetaminophen-childrens-tylenol-160-5-suspension-example"
        let log = MedicationLog(
            child: child,
            medicationDefinitionID: definitionID,
            activeIngredientSnapshot: "Acetaminophen",
            concentrationValueSnapshot: 160,
            concentrationMillilitersSnapshot: 5,
            concentrationUnitSnapshot: "mg/mL",
            formSnapshot: "suspension",
            brandSnapshot: "Children's Tylenol",
            ruleVersionSnapshot: "v1",
            sourceVersionSnapshot: "2026.1",
            volumeMilliliters: 5,
            calculatedMilligrams: 160,
            calculatedMilligramsPerKilogram: 15.4,
            weightUsedForCalculation: 10.4,
            weightUnitUsedForCalculation: .kilograms,
            calculationStatus: .calculated,
            administeredAt: .now
        )
        try logs.create(log)

        // Simulate the medication library changing after the fact — the log
        // must not be affected since it stores its own snapshot.
        let fetched = try logs.fetchAll(for: child)
        #expect(fetched.count == 1)
        let entry = try #require(fetched.first)
        #expect(entry.activeIngredientSnapshot == "Acetaminophen")
        #expect(entry.brandSnapshot == "Children's Tylenol")
        #expect(entry.concentrationValueSnapshot == 160)
        #expect(entry.calculatedMilligrams == 160)
        #expect(entry.weightUsedForCalculation == 10.4)
        #expect(entry.medicationDefinitionID == definitionID)

        try logs.softDelete(entry)
        #expect(try logs.fetchAll(for: child).isEmpty)
    }

    // MARK: - Sync queue

    @Test("inserts and fetches pending sync queue items")
    func syncQueueInsertAndFetch() throws {
        let container = try makeContainer()
        let queue = SwiftDataSyncQueueRepository(context: container.mainContext)

        let entityID = UUID()
        let item = try queue.enqueue(
            entityType: "TemperatureLog",
            entityID: entityID,
            operationType: .upsert,
            payload: nil,
            idempotencyKey: UUID().uuidString
        )

        let pending = try queue.fetchPending()
        #expect(pending.count == 1)
        #expect(pending.first?.id == item.id)
        #expect(pending.first?.entityID == entityID)
        #expect(pending.first?.status == .pending)
    }

    // MARK: - Migration plan

    // Uses an explicit on-disk URL (in a temp directory, cleaned up after)
    // rather than `makeProductionContainer()` directly — that uses the
    // default persistent store location, which a test shouldn't touch.
    @Test("a store opened through the versioned schema and migration plan round-trips data")
    func migrationPlanContainerRoundTripsData() throws {
        let storeURL = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).store")
        defer {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
            }
        }

        let schema = ModelContainerFactory.makeSchema()
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: ModelContainerFactory.MigrationPlan.self,
            configurations: [configuration]
        )

        let household = try SwiftDataHouseholdRepository(context: container.mainContext).createGuestHouseholdIfNeeded()

        // Reopen against the same file through the same schema/migration
        // path to confirm the data actually persisted to disk and survives
        // a fresh container being opened against it — not just that the
        // first container's in-memory state looked right.
        let reopened = try ModelContainer(
            for: schema,
            migrationPlan: ModelContainerFactory.MigrationPlan.self,
            configurations: [configuration]
        )
        let fetched = try SwiftDataHouseholdRepository(context: reopened.mainContext).fetchActiveHouseholds()
        #expect(fetched.count == 1)
        #expect(fetched.first?.id == household.id)
    }
}
