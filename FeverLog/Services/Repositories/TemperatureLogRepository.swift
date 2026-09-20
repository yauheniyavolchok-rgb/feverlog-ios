import Foundation
import SwiftData

@MainActor
protocol TemperatureLogRepository {
    func fetchAll(for child: Child) throws -> [TemperatureLog]
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
