import Foundation
import SwiftData
import Testing
@testable import FeverLog

@MainActor
@Suite("ReminderRepository")
struct ReminderRepositoryTests {
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

    @Test("creates and fetches a reminder scoped to a child, soonest first")
    func createsAndFetchesSortedBySchedule() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataReminderRepository(context: container.mainContext)

        _ = try repository.create(reminderType: .medication, scheduleDate: .now.addingTimeInterval(7200), isEnabled: true, child: child)
        _ = try repository.create(reminderType: .hydration, scheduleDate: .now.addingTimeInterval(3600), isEnabled: true, child: child)

        let fetched = try repository.fetchAll(for: child)
        #expect(fetched.count == 2)
        #expect(fetched.first?.reminderType == .hydration)
    }

    @Test("assigns a deterministic local notification identifier at creation")
    func assignsNotificationIdentifier() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataReminderRepository(context: container.mainContext)

        let reminder = try repository.create(
            reminderType: .custom,
            scheduleDate: .now.addingTimeInterval(3600),
            isEnabled: true,
            child: child
        )

        #expect(reminder.localNotificationIdentifier == NotificationScheduler.identifier(for: reminder.id))
    }

    @Test("update persists in-place mutations")
    func updatePersistsMutations() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataReminderRepository(context: container.mainContext)

        let reminder = try repository.create(
            reminderType: .medication,
            scheduleDate: .now.addingTimeInterval(3600),
            isEnabled: true,
            child: child
        )
        reminder.isEnabled = false
        try repository.update(reminder)

        #expect(try repository.fetchAll(for: child).first?.isEnabled == false)
    }

    @Test("soft-deleted reminders are excluded from default reads")
    func softDeleteExcludesFromDefaultReads() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let repository = SwiftDataReminderRepository(context: container.mainContext)

        let reminder = try repository.create(
            reminderType: .temperature,
            scheduleDate: .now.addingTimeInterval(3600),
            isEnabled: true,
            child: child
        )
        try repository.softDelete(reminder)

        #expect(reminder.deletedAt != nil)
        #expect(try repository.fetchAll(for: child).isEmpty)
    }
}
