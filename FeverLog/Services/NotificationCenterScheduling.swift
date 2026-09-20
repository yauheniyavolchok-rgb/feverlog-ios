import Foundation
import UserNotifications

/// Thin abstraction over `UNUserNotificationCenter` so `NotificationScheduler`
/// can be unit tested without touching the real notification system (which
/// would require interactive permission prompts under test).
@MainActor
protocol NotificationCenterScheduling {
    func requestAuthorization() async throws -> Bool
    func currentAuthorizationStatus() async -> UNAuthorizationStatus
    func add(_ request: UNNotificationRequest) async throws
    func removeRequests(withIdentifiers identifiers: [String])
    func pendingRequestIdentifiers() async -> [String]
}

extension UNUserNotificationCenter: NotificationCenterScheduling {
    func requestAuthorization() async throws -> Bool {
        try await requestAuthorization(options: [.alert, .sound, .badge])
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }

    func removeRequests(withIdentifiers identifiers: [String]) {
        removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func pendingRequestIdentifiers() async -> [String] {
        await pendingNotificationRequests().map(\.identifier)
    }
}
