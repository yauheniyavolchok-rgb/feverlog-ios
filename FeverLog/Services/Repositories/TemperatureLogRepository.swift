import Foundation
import SwiftData

@MainActor
protocol TemperatureLogRepository {
    func fetchAll(for child: Child) throws -> [TemperatureLog]
    /// Scoped to just `recordedAt >= cutoff` at the fetch level — unlike
    /// `fetchAll(for:)`, this never loads a record just to discard it.
    func fetchAll(for child: Child, since cutoff: Date) throws -> [TemperatureLog]
    /// `fetchLimit = 1`, so this is cheap regardless of how much history
    /// exists before `cutoff` — used to decide whether a "load more" style
    /// affordance has anything left to reveal, without fetching it.
    func hasEntry(for child: Child, before cutoff: Date) throws -> Bool
    func create(
        temperatureCelsius: Double,
        measurementMethod: TemperatureMeasurementMethod,
        recordedAt: Date,
        note: String?,
        child: Child
    ) throws -> TemperatureLog
    /// Persists in-place mutations already made to a fetched `TemperatureLog`.
    func update(_ log: TemperatureLog) throws
    func softDelete(_ log: TemperatureLog) throws
}

@MainActor
final class SwiftDataTemperatureLogRepository: TemperatureLogRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(for child: Child) throws -> [TemperatureLog] {
        let childID = child.id
        let predicate = #Predicate<TemperatureLog> { $0.childID == childID && $0.deletedAt == nil }
        let descriptor = FetchDescriptor<TemperatureLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchAll(for child: Child, since cutoff: Date) throws -> [TemperatureLog] {
        let childID = child.id
        let predicate = #Predicate<TemperatureLog> {
            $0.childID == childID && $0.deletedAt == nil && $0.recordedAt >= cutoff
        }
        let descriptor = FetchDescriptor<TemperatureLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func hasEntry(for child: Child, before cutoff: Date) throws -> Bool {
        let childID = child.id
        let predicate = #Predicate<TemperatureLog> {
            $0.childID == childID && $0.deletedAt == nil && $0.recordedAt < cutoff
        }
        var descriptor = FetchDescriptor<TemperatureLog>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }

    func create(
        temperatureCelsius: Double,
        measurementMethod: TemperatureMeasurementMethod,
        recordedAt: Date,
        note: String?,
        child: Child
    ) throws -> TemperatureLog {
        let log = TemperatureLog(
            child: child,
            temperatureCelsius: temperatureCelsius,
            measurementMethod: measurementMethod,
            recordedAt: recordedAt,
            note: note
        )
        context.insert(log)
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "temperature_logs", entityID: log.id, context: context)
        return log
    }

    func update(_ log: TemperatureLog) throws {
        log.updatedAt = .now
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "temperature_logs", entityID: log.id, context: context)
    }

    func softDelete(_ log: TemperatureLog) throws {
        log.markSoftDeleted()
        try context.save()
        SyncQueueTrigger.enqueue(entityType: "temperature_logs", entityID: log.id, context: context)
    }
}
