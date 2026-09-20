import Foundation
import SwiftData

enum ReminderType: String, Codable, CaseIterable, Sendable {
    case medication
    case temperature
    case hydration
    case custom
}

/// Reminder schedules are local device settings in v1 — they are not
/// synchronized between household members unless a later phase explicitly
/// adds them to the sync schema.
@Model
final class Reminder {
    var id: UUID
    var childID: UUID
    var child: Child?

    var reminderType: ReminderType
    var scheduleDate: Date
    var isEnabled: Bool
    var localNotificationIdentifier: String?

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var lastSyncedAt: Date?
    var syncVersion: Int

    init(
        id: UUID = UUID(),
        child: Child,
        reminderType: ReminderType,
        scheduleDate: Date,
        isEnabled: Bool = true,
        localNotificationIdentifier: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.childID = child.id
        self.child = child
        self.reminderType = reminderType
        self.scheduleDate = scheduleDate
        self.isEnabled = isEnabled
        self.localNotificationIdentifier = localNotificationIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
        self.lastSyncedAt = nil
        self.syncVersion = 0
    }
}

extension Reminder: SyncableRecord {}
