import Foundation
import SwiftData
import Testing
@testable import FeverLog

@MainActor
@Suite("TemperatureLogRepository")
struct TemperatureLogRepositoryTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainerFactory.makeInMemoryContainer()
    }

    private func makeChild(in container: ModelContainer) throws -> Child {
        let context = container.mainContext
        let household = try SwiftDataHouseholdRepository(context: context).createGuestHouseholdIfNeeded()
        return try SwiftDataChildRepository(context: context).create(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: ChildAvatarOption.star.rawValue,
            avatarColorIdentifier: ChildAvatarColorOption.mint.rawValue,
            household: household
        )
    }

    @Test("creates and fetches a temperature log, newest first")
    func createsAndFetchesNewestFirst() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataTemperatureLogRepository(context: container.mainContext)

        let earlier = Date(timeIntervalSinceNow: -3600)
        _ = try repository.create(temperatureCelsius: 37.0, measurementMethod: .oral, recordedAt: earlier, note: nil, child: child)
        _ = try repository.create(temperatureCelsius: 38.2, measurementMethod: .ear, recordedAt: .now, note: "fussy", child: child)

        let logs = try repository.fetchAll(for: child)
        #expect(logs.count == 2)
        #expect(logs.first?.temperatureCelsius == 38.2)
        #expect(logs.first?.note == "fussy")
    }

    @Test("soft-deleted logs are excluded from default reads")
    func softDeleteExcludesFromDefaultReads() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataTemperatureLogRepository(context: container.mainContext)

        let log = try repository.create(temperatureCelsius: 37.5, measurementMethod: .oral, recordedAt: .now, note: nil, child: child)
        #expect(try repository.fetchAll(for: child).count == 1)

        try repository.softDelete(log)

        #expect(log.deletedAt != nil)
        #expect(try repository.fetchAll(for: child).isEmpty)
    }

    @Test("update persists in-place mutations")
    func updatePersistsMutations() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataTemperatureLogRepository(context: container.mainContext)

        let log = try repository.create(temperatureCelsius: 37.0, measurementMethod: .oral, recordedAt: .now, note: nil, child: child)
        let originalID = log.id

        log.temperatureCelsius = 39.0
        log.measurementMethod = .rectal
        try repository.update(log)

        let fetched = try repository.fetchAll(for: child)
        #expect(fetched.count == 1)
        #expect(fetched.first?.id == originalID)
        #expect(fetched.first?.temperatureCelsius == 39.0)
        #expect(fetched.first?.measurementMethod == .rectal)
    }

    @Test("logs are scoped per child")
    func logsAreScopedPerChild() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let household = try SwiftDataHouseholdRepository(context: context).createGuestHouseholdIfNeeded()
        let childRepository = SwiftDataChildRepository(context: context)
        let childA = try childRepository.create(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: ChildAvatarOption.star.rawValue,
            avatarColorIdentifier: ChildAvatarColorOption.mint.rawValue,
            household: household
        )
        let childB = try childRepository.create(
            name: "Leo",
            birthday: .now,
            avatarIdentifier: ChildAvatarOption.moon.rawValue,
            avatarColorIdentifier: ChildAvatarColorOption.blue.rawValue,
            household: household
        )

        let repository = SwiftDataTemperatureLogRepository(context: context)
        _ = try repository.create(temperatureCelsius: 37.0, measurementMethod: .oral, recordedAt: .now, note: nil, child: childA)
        _ = try repository.create(temperatureCelsius: 38.0, measurementMethod: .oral, recordedAt: .now, note: nil, child: childB)

        #expect(try repository.fetchAll(for: childA).count == 1)
        #expect(try repository.fetchAll(for: childB).count == 1)
    }
}
