import Foundation
import SwiftData

@MainActor
protocol NoteEntryRepository {
    func fetchAll(for child: Child) throws -> [NoteEntry]
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

    func create(text: String, recordedAt: Date, child: Child) throws -> NoteEntry {
        let entry = NoteEntry(child: child, text: text, recordedAt: recordedAt)
        context.insert(entry)
        try context.save()
        return entry
    }

    func update(_ entry: NoteEntry) throws {
        entry.updatedAt = .now
        try context.save()
    }

    func softDelete(_ entry: NoteEntry) throws {
        entry.markSoftDeleted()
        try context.save()
    }
}
