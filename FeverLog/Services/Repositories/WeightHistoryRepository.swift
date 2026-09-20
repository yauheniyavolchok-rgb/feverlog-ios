import Foundation
import SwiftData

@MainActor
protocol WeightHistoryRepository {
    func addWeight(_ weight: Double, unit: WeightUnit, effectiveDate: Date, child: Child) throws -> WeightHistory
    func fetchHistory(for child: Child) throws -> [WeightHistory]
    /// The active weight for a given instant is the latest non-deleted
    /// weight whose effective date is less than or equal to that instant.
    /// Returns `nil` — never an inferred value — when no such weight exists.
    func activeWeight(for child: Child, at date: Date) throws -> WeightHistory?
}

@MainActor
final class SwiftDataWeightHistoryRepository: WeightHistoryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addWeight(_ weight: Double, unit: WeightUnit, effectiveDate: Date, child: Child) throws -> WeightHistory {
        let entry = WeightHistory(child: child, weight: weight, unit: unit, effectiveDate: effectiveDate)
        context.insert(entry)
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "weight_history", entityID: entry.id, context: context)
        return entry
    }

    func fetchHistory(for child: Child) throws -> [WeightHistory] {
        let childID = child.id
        let predicate = #Predicate<WeightHistory> { $0.childID == childID && $0.deletedAt == nil }
        let descriptor = FetchDescriptor<WeightHistory>(predicate: predicate, sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func activeWeight(for child: Child, at date: Date) throws -> WeightHistory? {
        let childID = child.id
        let predicate = #Predicate<WeightHistory> {
            $0.childID == childID && $0.deletedAt == nil && $0.effectiveDate <= date
        }
        var descriptor = FetchDescriptor<WeightHistory>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
