import Foundation
import SwiftData
import Testing
@testable import FeverLog

@MainActor
@Suite("SymptomEntryRepository")
struct SymptomEntryRepositoryTests {
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

    @Test("creates and fetches a symptom entry with multiple selected categories")
    func createsAndFetchesMultiSelection() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataSymptomEntryRepository(context: container.mainContext)

        let identifiers = [SymptomCategory.breathing.rawValue, SymptomCategory.hydration.rawValue]
        _ = try repository.create(symptomIdentifiers: identifiers, recordedAt: .now, child: child)

        let fetched = try repository.fetchAll(for: child)
        #expect(fetched.count == 1)
        #expect(Set(fetched.first?.symptomIdentifiers ?? []) == Set(identifiers))
    }

    @Test("stores the recorded date and time")
    func storesRecordedDateTime() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataSymptomEntryRepository(context: container.mainContext)
        let recordedAt = Date(timeIntervalSince1970: 1_700_000_000)

        _ = try repository.create(symptomIdentifiers: [SymptomCategory.pain.rawValue], recordedAt: recordedAt, child: child)

        #expect(try repository.fetchAll(for: child).first?.recordedAt == recordedAt)
    }

    @Test("update persists in-place mutations")
    func updatePersistsMutations() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataSymptomEntryRepository(context: container.mainContext)

        let entry = try repository.create(symptomIdentifiers: [SymptomCategory.pain.rawValue], recordedAt: .now, child: child)
        entry.symptomIdentifiers = [SymptomCategory.skin.rawValue, SymptomCategory.sleep.rawValue]
        try repository.update(entry)

        let fetched = try repository.fetchAll(for: child).first
        #expect(Set(fetched?.symptomIdentifiers ?? []) == Set([SymptomCategory.skin.rawValue, SymptomCategory.sleep.rawValue]))
    }

    @Test("soft-deleted symptom entries are excluded from default reads")
    func softDeleteExcludesFromDefaultReads() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataSymptomEntryRepository(context: container.mainContext)

        let entry = try repository.create(symptomIdentifiers: [SymptomCategory.general.rawValue], recordedAt: .now, child: child)
        #expect(try repository.fetchAll(for: child).count == 1)

        try repository.softDelete(entry)

        #expect(entry.deletedAt != nil)
        #expect(try repository.fetchAll(for: child).isEmpty)
    }
}

@MainActor
@Suite("NoteEntryRepository")
struct NoteEntryRepositoryTests {
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

    @Test("creates and fetches a note, always scoped to a child")
    func createsAndFetchesScopedToChild() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataNoteEntryRepository(context: container.mainContext)

        _ = try repository.create(text: "Seemed more tired than usual today.", recordedAt: .now, child: child)

        let fetched = try repository.fetchAll(for: child)
        #expect(fetched.count == 1)
        #expect(fetched.first?.childID == child.id)
    }

    @Test("update persists in-place mutations")
    func updatePersistsMutations() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataNoteEntryRepository(context: container.mainContext)

        let entry = try repository.create(text: "Original", recordedAt: .now, child: child)
        entry.text = "Updated"
        try repository.update(entry)

        #expect(try repository.fetchAll(for: child).first?.text == "Updated")
    }

    @Test("soft-deleted notes are excluded from default reads")
    func softDeleteExcludesFromDefaultReads() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataNoteEntryRepository(context: container.mainContext)

        let entry = try repository.create(text: "Note", recordedAt: .now, child: child)
        try repository.softDelete(entry)

        #expect(entry.deletedAt != nil)
        #expect(try repository.fetchAll(for: child).isEmpty)
    }
}
