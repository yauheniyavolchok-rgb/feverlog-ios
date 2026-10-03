import Foundation
import SwiftData

@MainActor
protocol NoteEntryRepository {
    func fetchAll(for child: Child) throws -> [NoteEntry]
    /// Scoped to just `recordedAt >= cutoff` at the fetch level — unlike
    /// `fetchAll(for:)`, this never loads a record just to discard it.
    func fetchAll(for child: Child, since cutoff: Date) throws -> [NoteEntry]
    /// `fetchLimit = 1`, so this is cheap regardless of how much history
    /// exists before `cutoff` — used to decide whether a "load more" style
    /// affordance has anything left to reveal, without fetching it.
    func hasEntry(for child: Child, before cutoff: Date) throws -> Bool
    func create(text: String, recordedAt: Date, child: Child) throws -> NoteEntry
    func update(_ entry: NoteEntry) throws
    func softDelete(_ entry: NoteEntry) throws
}

@MainActor
final class SwiftDataNoteEntryRepository: NoteEntryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(for child: Child) throws -> [NoteEntry] {
        let childID = child.id
        let predicate = #Predicate<NoteEntry> { $0.childID == childID && $0.deletedAt == nil }
        let descriptor = FetchDescriptor<NoteEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchAll(for child: Child, since cutoff: Date) throws -> [NoteEntry] {
        let childID = child.id
        let predicate = #Predicate<NoteEntry> {
            $0.childID == childID && $0.deletedAt == nil && $0.recordedAt >= cutoff
        }
        let descriptor = FetchDescriptor<NoteEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func hasEntry(for child: Child, before cutoff: Date) throws -> Bool {
        let childID = child.id
        let predicate = #Predicate<NoteEntry> {
            $0.childID == childID && $0.deletedAt == nil && $0.recordedAt < cutoff
        }
        var descriptor = FetchDescriptor<NoteEntry>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }

    func create(text: String, recordedAt: Date, child: Child) throws -> NoteEntry {
        let entry = NoteEntry(child: child, text: text, recordedAt: recordedAt)
        context.insert(entry)
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "notes", entityID: entry.id, context: context)
        return entry
    }

    func update(_ entry: NoteEntry) throws {
        entry.updatedAt = .now
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "notes", entityID: entry.id, context: context)
    }

    func softDelete(_ entry: NoteEntry) throws {
        entry.markSoftDeleted()
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "notes", entityID: entry.id, context: context)
    }
}
