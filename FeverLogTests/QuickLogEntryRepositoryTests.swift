import Foundation
import SwiftData
import Testing
@testable import FeverLog

@MainActor
@Suite("QuickLogEntryRepository")
struct QuickLogEntryRepositoryTests {
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

    @Test("creates and fetches a quick log entry with its type and degree")
    func createsAndFetches() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataQuickLogEntryRepository(context: container.mainContext)

        _ = try repository.create(type: .vomit, degree: 2, recordedAt: .now, child: child)

        let fetched = try repository.fetchAll(for: child)
        #expect(fetched.count == 1)
        #expect(fetched.first?.type == .vomit)
        #expect(fetched.first?.degree == 2)
        #expect(fetched.first?.childID == child.id)
    }

    @Test("every quick log type can be created and round-trips correctly")
    func everyTypeRoundTrips() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataQuickLogEntryRepository(context: container.mainContext)

        for type in QuickLogType.allCases {
            _ = try repository.create(type: type, degree: 1, recordedAt: .now, child: child)
        }

        let fetched = try repository.fetchAll(for: child)
        #expect(Set(fetched.map(\.type)) == Set(QuickLogType.allCases))
    }

    @Test("update persists in-place mutations to degree and recorded time")
    func updatePersistsMutations() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataQuickLogEntryRepository(context: container.mainContext)

        let entry = try repository.create(type: .breath, degree: 1, recordedAt: .now, child: child)
        entry.degree = 3
        try repository.update(entry)

        #expect(try repository.fetchAll(for: child).first?.degree == 3)
    }

    @Test("soft-deleted entries are excluded from default reads")
    func softDeleteExcludesFromDefaultReads() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataQuickLogEntryRepository(context: container.mainContext)

        let entry = try repository.create(type: .poop, degree: 2, recordedAt: .now, child: child)
        try repository.softDelete(entry)

        #expect(entry.deletedAt != nil)
        #expect(try repository.fetchAll(for: child).isEmpty)
    }

    @Test("fetchAll(since:) and hasEntry(before:) are scoped to recordedAt against the cutoff")
    func dateBoundedFetchAndExistenceCheck() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataQuickLogEntryRepository(context: container.mainContext)
        let cutoff = Date(timeIntervalSinceNow: -3600)

        #expect(try repository.hasEntry(for: child, before: cutoff) == false)

        _ = try repository.create(type: .poop, degree: 1, recordedAt: cutoff.addingTimeInterval(-60), child: child)
        let recent = try repository.create(type: .food, degree: 2, recordedAt: .now, child: child)

        let sinceEntries = try repository.fetchAll(for: child, since: cutoff)
        #expect(sinceEntries.map(\.id) == [recent.id])
        #expect(try repository.hasEntry(for: child, before: cutoff) == true)
    }
}
