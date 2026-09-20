import Foundation
import SwiftData

@MainActor
protocol SymptomEntryRepository {
    func fetchAll(for child: Child) throws -> [SymptomEntry]
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

    func create(symptomIdentifiers: [String], recordedAt: Date, child: Child) throws -> SymptomEntry {
        let entry = SymptomEntry(child: child, symptomIdentifiers: symptomIdentifiers, recordedAt: recordedAt)
        context.insert(entry)
        try context.save()
        return entry
    }

    func update(_ entry: SymptomEntry) throws {
        entry.updatedAt = .now
        try context.save()
    }

    func softDelete(_ entry: SymptomEntry) throws {
        entry.markSoftDeleted()
        try context.save()
    }
}
