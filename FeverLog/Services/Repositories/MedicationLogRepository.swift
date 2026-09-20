import Foundation
import SwiftData

@MainActor
protocol MedicationLogRepository {
    func create(_ log: MedicationLog) throws
    func fetchAll(for child: Child) throws -> [MedicationLog]
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
