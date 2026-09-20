import Foundation
import SwiftData

@MainActor
protocol MedicationLogRepository {
    func create(_ log: MedicationLog) throws
    func fetchAll(for child: Child) throws -> [MedicationLog]
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

    func softDelete(_ log: MedicationLog) throws {
        log.markSoftDeleted()
        try context.save()
    }
}
