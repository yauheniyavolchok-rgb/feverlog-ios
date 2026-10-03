import Foundation
import SwiftData

@MainActor
protocol QuickLogEntryRepository {
    func fetchAll(for child: Child) throws -> [QuickLogEntry]
    /// Scoped to just `recordedAt >= cutoff` at the fetch level — unlike
    /// `fetchAll(for:)`, this never loads a record just to discard it.
    func fetchAll(for child: Child, since cutoff: Date) throws -> [QuickLogEntry]
    /// `fetchLimit = 1`, so this is cheap regardless of how much history
    /// exists before `cutoff` — used to decide whether a "load more" style
    /// affordance has anything left to reveal, without fetching it.
    func hasEntry(for child: Child, before cutoff: Date) throws -> Bool
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

    func fetchAll(for child: Child, since cutoff: Date) throws -> [QuickLogEntry] {
        let childID = child.id
        let predicate = #Predicate<QuickLogEntry> {
            $0.childID == childID && $0.deletedAt == nil && $0.recordedAt >= cutoff
        }
        let descriptor = FetchDescriptor<QuickLogEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func hasEntry(for child: Child, before cutoff: Date) throws -> Bool {
        let childID = child.id
        let predicate = #Predicate<QuickLogEntry> {
            $0.childID == childID && $0.deletedAt == nil && $0.recordedAt < cutoff
        }
        var descriptor = FetchDescriptor<QuickLogEntry>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
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
