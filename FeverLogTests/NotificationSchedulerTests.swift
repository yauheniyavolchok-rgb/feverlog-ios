import Foundation
import Testing
import UserNotifications
@testable import FeverLog

@MainActor
private final class FakeNotificationCenter: NotificationCenterScheduling {
    private(set) var addedRequests: [UNNotificationRequest] = []
    private(set) var removalCalls: [[String]] = []
    var authorizationGranted = true
    var authorizationStatus: UNAuthorizationStatus = .authorized

    func requestAuthorization() async throws -> Bool { authorizationGranted }
    func currentAuthorizationStatus() async -> UNAuthorizationStatus { authorizationStatus }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removeRequests(withIdentifiers identifiers: [String]) {
        removalCalls.append(identifiers)
        addedRequests.removeAll { identifiers.contains($0.identifier) }
    }

    func pendingRequestIdentifiers() async -> [String] {
        addedRequests.map(\.identifier)
    }
}

@MainActor
@Suite("NotificationScheduler")
struct NotificationSchedulerTests {
    private func makeChild() -> Child {
        let household = Household(displayName: "Test Household")
        return Child(household: household, name: "Ava", birthday: .now, avatarIdentifier: "star.fill", avatarColorIdentifier: "mint")
    }

    @Test("scheduling a reminder adds exactly one pending request with the deterministic identifier")
    func schedulingAddsOneRequest() async throws {
        let center = FakeNotificationCenter()
        let scheduler = NotificationScheduler(center: center)
        let reminder = Reminder(child: makeChild(), reminderType: .medication, scheduleDate: .now.addingTimeInterval(3600))

        try await scheduler.schedule(reminder)

        #expect(center.addedRequests.count == 1)
        #expect(center.addedRequests.first?.identifier == NotificationScheduler.identifier(for: reminder.id))
    }

    @Test("re-scheduling the same reminder never leaves duplicate active requests")
    func reschedulingPreventsDuplicates() async throws {
        let center = FakeNotificationCenter()
        let scheduler = NotificationScheduler(center: center)
        let reminder = Reminder(child: makeChild(), reminderType: .hydration, scheduleDate: .now.addingTimeInterval(3600))

        try await scheduler.schedule(reminder)
        try await scheduler.schedule(reminder)
        try await scheduler.schedule(reminder)

        #expect(center.addedRequests.count == 1)
        #expect(await scheduler.pendingIdentifiers().count == 1)
    }

    @Test("scheduling a disabled reminder does not add a request")
    func disabledReminderIsNotScheduled() async throws {
        let center = FakeNotificationCenter()
        let scheduler = NotificationScheduler(center: center)
        let reminder = Reminder(child: makeChild(), reminderType: .custom, scheduleDate: .now.addingTimeInterval(3600), isEnabled: false)

        try await scheduler.schedule(reminder)

        #expect(center.addedRequests.isEmpty)
    }

    @Test("disabling a previously-scheduled reminder cancels its pending request")
    func disablingCancelsExistingRequest() async throws {
        let center = FakeNotificationCenter()
        let scheduler = NotificationScheduler(center: center)
        let reminder = Reminder(child: makeChild(), reminderType: .temperature, scheduleDate: .now.addingTimeInterval(3600))

        try await scheduler.schedule(reminder)
        #expect(center.addedRequests.count == 1)

        reminder.isEnabled = false
        try await scheduler.schedule(reminder)

        #expect(center.addedRequests.isEmpty)
    }

    @Test("cancel removes the reminder's pending request")
    func cancelRemovesRequest() async throws {
        let center = FakeNotificationCenter()
        let scheduler = NotificationScheduler(center: center)
        let reminder = Reminder(child: makeChild(), reminderType: .medication, scheduleDate: .now.addingTimeInterval(3600))

        try await scheduler.schedule(reminder)
        scheduler.cancel(reminder)

        #expect(center.addedRequests.isEmpty)
        #expect(center.removalCalls.last == [NotificationScheduler.identifier(for: reminder.id)])
    }

    @Test("notification content is localized per reminder type and never empty")
    func notificationContentIsLocalized() {
        for type in ReminderType.allCases {
            let content = NotificationScheduler.content(for: type)
            #expect(content.title == type.notificationTitle)
            #expect(!content.title.isEmpty)
            #expect(!content.body.isEmpty)
        }
    }

    @Test("different reminders produce different identifiers")
    func differentRemindersHaveDifferentIdentifiers() {
        let first = Reminder(child: makeChild(), reminderType: .medication, scheduleDate: .now)
        let second = Reminder(child: makeChild(), reminderType: .medication, scheduleDate: .now)
        #expect(NotificationScheduler.identifier(for: first.id) != NotificationScheduler.identifier(for: second.id))
    }
}
