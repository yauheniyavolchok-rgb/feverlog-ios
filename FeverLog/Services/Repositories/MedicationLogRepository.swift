import Foundation
import SwiftData

@MainActor
protocol MedicationLogRepository {
    func create(_ log: MedicationLog) throws
    func fetchAll(for child: Child) throws -> [MedicationLog]
    /// Scoped to just `administeredAt >= cutoff` at the fetch level —
    /// unlike `fetchAll(for:)`, this never loads a record just to discard it.
    func fetchAll(for child: Child, since cutoff: Date) throws -> [MedicationLog]
    /// `fetchLimit = 1`, so this is cheap regardless of how much history
    /// exists before `cutoff` — used to decide whether a "load more" style
    /// affordance has anything left to reveal, without fetching it.
    func hasEntry(for child: Child, before cutoff: Date) throws -> Bool
    /// Persists in-place mutations already made to a fetched `MedicationLog`.
    /// Only this record's own snapshot changes — the medication definition
    /// and every other historical log are untouched.
    func update(_ log: MedicationLog) throws
    func softDelete(_ log: MedicationLog) throws
}

@MainActor
final class SwiftDataMedicationLogRepository: MedicationLogRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func create(_ log: MedicationLog) throws {
        context.insert(log)
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "medication_logs", entityID: log.id, context: context)
    }

    func fetchAll(for child: Child) throws -> [MedicationLog] {
        let childID = child.id
        let predicate = #Predicate<MedicationLog> { $0.childID == childID && $0.deletedAt == nil }
        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.administeredAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchAll(for child: Child, since cutoff: Date) throws -> [MedicationLog] {
        let childID = child.id
        let predicate = #Predicate<MedicationLog> {
            $0.childID == childID && $0.deletedAt == nil && $0.administeredAt >= cutoff
        }
        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.administeredAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func hasEntry(for child: Child, before cutoff: Date) throws -> Bool {
        let childID = child.id
        let predicate = #Predicate<MedicationLog> {
            $0.childID == childID && $0.deletedAt == nil && $0.administeredAt < cutoff
        }
        var descriptor = FetchDescriptor<MedicationLog>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }

    func update(_ log: MedicationLog) throws {
        log.updatedAt = .now
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "medication_logs", entityID: log.id, context: context)
    }

    func softDelete(_ log: MedicationLog) throws {
        log.markSoftDeleted()
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "medication_logs", entityID: log.id, context: context)
    }
}
