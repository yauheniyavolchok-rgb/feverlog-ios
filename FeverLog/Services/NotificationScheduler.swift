import Foundation
import UserNotifications

/// Schedules, edits, and cancels local reminder notifications. No remote
/// push server is involved — everything here is local device behavior.
///
/// TODO(Phase 8, notification copy): Define final notification copy and
/// default reminder intervals with product review.
/// Completion: all notification types have localized copy and documented
/// defaults.
/// Release blocker: yes for notifications.
@MainActor
final class NotificationScheduler {
    private let center: NotificationCenterScheduling

    init(center: NotificationCenterScheduling = UNUserNotificationCenter.current()) {
        self.center = center
    }

    /// A stable, deterministic identifier derived from the reminder's own
    /// id. Re-scheduling the same reminder (e.g. after an edit) always
    /// removes any existing request for that identifier first, so a
    /// reminder can never have two active pending requests at once.
    static func identifier(for reminderID: UUID) -> String {
        "reminder.\(reminderID.uuidString)"
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        (try? await center.requestAuthorization()) ?? false
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await center.currentAuthorizationStatus()
    }

    /// Schedules (or reschedules) a local notification for the reminder.
    /// Disabled reminders are only cancelled, never scheduled.
    func schedule(_ reminder: Reminder) async throws {
        let identifier = Self.identifier(for: reminder.id)
        center.removeRequests(withIdentifiers: [identifier])
        guard reminder.isEnabled else { return }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: Self.content(for: reminder.reminderType),
            trigger: Self.trigger(for: reminder.scheduleDate)
        )
        try await center.add(request)
    }

    func cancel(_ reminder: Reminder) {
        center.removeRequests(withIdentifiers: [Self.identifier(for: reminder.id)])
    }

    func pendingIdentifiers() async -> [String] {
        await center.pendingRequestIdentifiers()
    }

    static func content(for type: ReminderType) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = type.notificationTitle
        content.body = L10n.Reminders.notificationBody
        content.sound = .default
        return content
    }

    static func trigger(for date: Date, calendar: Calendar = .current) -> UNCalendarNotificationTrigger {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }
}
