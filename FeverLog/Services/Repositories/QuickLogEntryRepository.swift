import Foundation
import SwiftData

@MainActor
protocol QuickLogEntryRepository {
    func fetchAll(for child: Child) throws -> [QuickLogEntry]
    func create(type: QuickLogType, degree: Int, recordedAt: Date, child: Child) throws -> QuickLogEntry
    func update(_ entry: QuickLogEntry) throws
    func softDelete(_ entry: QuickLogEntry) throws
}

@MainActor
final class SwiftDataQuickLogEntryRepository: QuickLogEntryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(for child: Child) throws -> [QuickLogEntry] {
        let childID = child.id
        let predicate = #Predicate<QuickLogEntry> { $0.childID == childID && $0.deletedAt == nil }
        let descriptor = FetchDescriptor<QuickLogEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func create(type: QuickLogType, degree: Int, recordedAt: Date, child: Child) throws -> QuickLogEntry {
        let entry = QuickLogEntry(child: child, type: type, degree: degree, recordedAt: recordedAt)
        context.insert(entry)
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "quick_logs", entityID: entry.id, context: context)
        return entry
    }

    func update(_ entry: QuickLogEntry) throws {
        entry.updatedAt = .now
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "quick_logs", entityID: entry.id, context: context)
    }

    func softDelete(_ entry: QuickLogEntry) throws {
        entry.markSoftDeleted()
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "quick_logs", entityID: entry.id, context: context)
    }
}
