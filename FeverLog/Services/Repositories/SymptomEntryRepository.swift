import Foundation
import SwiftData

@MainActor
protocol SymptomEntryRepository {
    func fetchAll(for child: Child) throws -> [SymptomEntry]
    /// Scoped to just `recordedAt >= cutoff` at the fetch level — unlike
    /// `fetchAll(for:)`, this never loads a record just to discard it.
    func fetchAll(for child: Child, since cutoff: Date) throws -> [SymptomEntry]
    /// `fetchLimit = 1`, so this is cheap regardless of how much history
    /// exists before `cutoff` — used to decide whether a "load more" style
    /// affordance has anything left to reveal, without fetching it.
    func hasEntry(for child: Child, before cutoff: Date) throws -> Bool
    func create(symptomIdentifiers: [String], recordedAt: Date, child: Child) throws -> SymptomEntry
    func update(_ entry: SymptomEntry) throws
    func softDelete(_ entry: SymptomEntry) throws
}

@MainActor
final class SwiftDataSymptomEntryRepository: SymptomEntryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(for child: Child) throws -> [SymptomEntry] {
        let childID = child.id
        let predicate = #Predicate<SymptomEntry> { $0.childID == childID && $0.deletedAt == nil }
        let descriptor = FetchDescriptor<SymptomEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchAll(for child: Child, since cutoff: Date) throws -> [SymptomEntry] {
        let childID = child.id
        let predicate = #Predicate<SymptomEntry> {
            $0.childID == childID && $0.deletedAt == nil && $0.recordedAt >= cutoff
        }
        let descriptor = FetchDescriptor<SymptomEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func hasEntry(for child: Child, before cutoff: Date) throws -> Bool {
        let childID = child.id
        let predicate = #Predicate<SymptomEntry> {
            $0.childID == childID && $0.deletedAt == nil && $0.recordedAt < cutoff
        }
        var descriptor = FetchDescriptor<SymptomEntry>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }

    func create(symptomIdentifiers: [String], recordedAt: Date, child: Child) throws -> SymptomEntry {
        let entry = SymptomEntry(child: child, symptomIdentifiers: symptomIdentifiers, recordedAt: recordedAt)
        context.insert(entry)
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "symptoms", entityID: entry.id, context: context)
        return entry
    }

    func update(_ entry: SymptomEntry) throws {
        entry.updatedAt = .now
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "symptoms", entityID: entry.id, context: context)
    }

    func softDelete(_ entry: SymptomEntry) throws {
        entry.markSoftDeleted()
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "symptoms", entityID: entry.id, context: context)
    }
}
