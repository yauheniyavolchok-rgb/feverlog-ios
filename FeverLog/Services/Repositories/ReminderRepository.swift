import Foundation
import SwiftData

@MainActor
protocol ReminderRepository {
    func fetchAll(for child: Child) throws -> [Reminder]
    func create(reminderType: ReminderType, scheduleDate: Date, isEnabled: Bool, child: Child) throws -> Reminder
    func update(_ reminder: Reminder) throws
    func softDelete(_ reminder: Reminder) throws
}

@MainActor
final class SwiftDataReminderRepository: ReminderRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(for child: Child) throws -> [Reminder] {
        let childID = child.id
        let predicate = #Predicate<Reminder> { $0.childID == childID && $0.deletedAt == nil }
        let descriptor = FetchDescriptor<Reminder>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.scheduleDate, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func create(reminderType: ReminderType, scheduleDate: Date, isEnabled: Bool, child: Child) throws -> Reminder {
        let reminder = Reminder(child: child, reminderType: reminderType, scheduleDate: scheduleDate, isEnabled: isEnabled)
        reminder.localNotificationIdentifier = NotificationScheduler.identifier(for: reminder.id)
        context.insert(reminder)
        try context.save()
        return reminder
    }

    func update(_ reminder: Reminder) throws {
        reminder.updatedAt = .now
        try context.save()
    }

    func softDelete(_ reminder: Reminder) throws {
        reminder.markSoftDeleted()
        try context.save()
    }
}
