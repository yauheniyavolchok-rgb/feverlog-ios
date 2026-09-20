import Foundation
import SwiftData

enum TemperatureMeasurementMethod: String, Codable, CaseIterable, Sendable {
    case oral
    case rectal
    case axillary
    case ear
    case forehead
    case other
}

@Model
final class TemperatureLog {
    var id: UUID
    var childID: UUID
    var child: Child?

    /// Always stored in Celsius, to one decimal place.
    var temperatureCelsius: Double
    var measurementMethod: TemperatureMeasurementMethod
    var recordedAt: Date
    var note: String?

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var lastSyncedAt: Date?
    var syncVersion: Int

    init(
        id: UUID = UUID(),
        child: Child,
        temperatureCelsius: Double,
        measurementMethod: TemperatureMeasurementMethod,
        recordedAt: Date,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.childID = child.id
        self.child = child
        self.temperatureCelsius = temperatureCelsius
        self.measurementMethod = measurementMethod
        self.recordedAt = recordedAt
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
        self.lastSyncedAt = nil
        self.syncVersion = 0
    }
}

extension TemperatureLog: SyncableRecord {}
