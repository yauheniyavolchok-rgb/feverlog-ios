import Foundation
import SwiftData
import Testing
@testable import FeverLog

@MainActor
@Suite("ChildStore")
struct ChildStoreTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainerFactory.makeInMemoryContainer()
    }

    @Test("loading initial state creates a local guest household without network access")
    func loadInitialStateCreatesGuestHousehold() throws {
        let container = try makeContainer()
        let store = ChildStore()
        store.configure(context: container.mainContext)

        try store.loadInitialStateIfNeeded()

        #expect(store.household?.isGuest == true)
        #expect(store.children.isEmpty)
    }

    @Test("loading initial state twice does not create a second household")
    func loadInitialStateIsIdempotent() throws {
        let container = try makeContainer()
        let store = ChildStore()
        store.configure(context: container.mainContext)

        try store.loadInitialStateIfNeeded()
        let firstHouseholdID = store.household?.id
        try store.loadInitialStateIfNeeded()

        #expect(store.household?.id == firstHouseholdID)
    }

    @Test("creating a child selects it and appears in the active list")
    func creatingChildSelectsIt() throws {
        let container = try makeContainer()
        let store = ChildStore()
        store.configure(context: container.mainContext)
        try store.loadInitialStateIfNeeded()

        let child = try store.createChild(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: ChildAvatarOption.star.rawValue,
            avatarColorIdentifier: ChildAvatarColorOption.mint.rawValue
        )

        #expect(store.children.count == 1)
        #expect(store.selectedChildID == child?.id)
    }

    @Test("soft-deleting the selected child clears selection and excludes it from the list")
    func softDeletingSelectedChildClearsSelection() throws {
        let container = try makeContainer()
        let store = ChildStore()
        store.configure(context: container.mainContext)
        try store.loadInitialStateIfNeeded()

        let child = try #require(try store.createChild(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: ChildAvatarOption.star.rawValue,
            avatarColorIdentifier: ChildAvatarColorOption.mint.rawValue
        ))

        try store.softDelete(child)

        #expect(store.children.isEmpty)
        #expect(store.selectedChildID == nil)
    }

    @Test("switching between two children updates the selection")
    func switchingBetweenChildren() throws {
        let container = try makeContainer()
        let store = ChildStore()
        store.configure(context: container.mainContext)
        try store.loadInitialStateIfNeeded()

        let first = try #require(try store.createChild(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: ChildAvatarOption.star.rawValue,
            avatarColorIdentifier: ChildAvatarColorOption.mint.rawValue
        ))
        let second = try #require(try store.createChild(
            name: "Leo",
            birthday: .now,
            avatarIdentifier: ChildAvatarOption.moon.rawValue,
            avatarColorIdentifier: ChildAvatarColorOption.blue.rawValue
        ))

        #expect(store.selectedChildID == second.id)
        store.selectedChildID = first.id
        #expect(store.selectedChild?.name == "Ava")
    }
}
