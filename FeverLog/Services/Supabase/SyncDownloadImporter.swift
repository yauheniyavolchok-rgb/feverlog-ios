import Foundation
import SwiftData

/// Applies a decoded remote row into SwiftData, gated by
/// `ConflictResolver` — the app must never render a remote event directly;
/// it always goes through this import step first, and SwiftUI observes
/// the resulting SwiftData state as usual. Each `import*` method returns
/// `true` only if the remote record actually won and was applied.
@MainActor
final class SyncDownloadImporter {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func importChild(_ remote: ChildRemoteRecord, household: Household) -> Bool {
        let id = remote.id
        let existing = fetchOne(Child.self, predicate: #Predicate { $0.id == id })

        if let existing {
            guard shouldApply(remote: remote, localID: existing.id, localUpdatedAt: existing.updatedAt) else { return false }
            existing.name = remote.name
            existing.birthday = parseDate(remote.birthday) ?? existing.birthday
            existing.avatarIdentifier = remote.avatarIdentifier
            existing.avatarColorIdentifier = remote.avatarColorIdentifier
            existing.cachedWeightValue = remote.cachedWeightValue
            existing.cachedWeightUnit = remote.cachedWeightUnit.flatMap(WeightUnit.init(rawValue:))
            existing.updatedAt = remote.updatedAt
            existing.deletedAt = remote.deletedAt
            existing.lastSyncedAt = .now
        } else {
            let child = Child(
                id: remote.id,
                household: household,
                name: remote.name,
                birthday: parseDate(remote.birthday) ?? .now,
                avatarIdentifier: remote.avatarIdentifier,
                avatarColorIdentifier: remote.avatarColorIdentifier,
                createdAt: remote.createdAt,
                updatedAt: remote.updatedAt
            )
            child.cachedWeightValue = remote.cachedWeightValue
            child.cachedWeightUnit = remote.cachedWeightUnit.flatMap(WeightUnit.init(rawValue:))
            child.deletedAt = remote.deletedAt
            child.lastSyncedAt = .now
            context.insert(child)
        }
        try? context.save()
        return true
    }

    @discardableResult
    func importWeightHistory(_ remote: WeightHistoryRemoteRecord, child: Child) -> Bool {
        let id = remote.id
        let existing = fetchOne(WeightHistory.self, predicate: #Predicate { $0.id == id })

        if let existing {
            guard shouldApply(remote: remote, localID: existing.id, localUpdatedAt: existing.updatedAt) else { return false }
            existing.weight = remote.weight
            existing.unit = WeightUnit(rawValue: remote.unit) ?? existing.unit
            existing.effectiveDate = parseDate(remote.effectiveDate) ?? existing.effectiveDate
            existing.updatedAt = remote.updatedAt
            existing.deletedAt = remote.deletedAt
            existing.lastSyncedAt = .now
        } else {
            let entry = WeightHistory(
                id: remote.id,
                child: child,
                weight: remote.weight,
                unit: WeightUnit(rawValue: remote.unit) ?? .kilograms,
                effectiveDate: parseDate(remote.effectiveDate) ?? .now,
                createdAt: remote.createdAt,
                updatedAt: remote.updatedAt
            )
            entry.deletedAt = remote.deletedAt
            entry.lastSyncedAt = .now
            context.insert(entry)
        }
        try? context.save()
        return true
    }

    @discardableResult
    func importTemperatureLog(_ remote: TemperatureLogRemoteRecord, child: Child) -> Bool {
        let id = remote.id
        let existing = fetchOne(TemperatureLog.self, predicate: #Predicate { $0.id == id })

        if let existing {
            guard shouldApply(remote: remote, localID: existing.id, localUpdatedAt: existing.updatedAt) else { return false }
            existing.temperatureCelsius = remote.temperatureCelsius
            existing.measurementMethod = TemperatureMeasurementMethod(rawValue: remote.measurementMethod) ?? existing.measurementMethod
            existing.recordedAt = remote.recordedAt
            existing.note = remote.note
            existing.updatedAt = remote.updatedAt
            existing.deletedAt = remote.deletedAt
            existing.lastSyncedAt = .now
        } else {
            let log = TemperatureLog(
                id: remote.id,
                child: child,
                temperatureCelsius: remote.temperatureCelsius,
                measurementMethod: TemperatureMeasurementMethod(rawValue: remote.measurementMethod) ?? .other,
                recordedAt: remote.recordedAt,
                note: remote.note,
                createdAt: remote.createdAt,
                updatedAt: remote.updatedAt
            )
            log.deletedAt = remote.deletedAt
            log.lastSyncedAt = .now
            context.insert(log)
        }
        try? context.save()
        return true
    }

    @discardableResult
    func importMedicationLog(_ remote: MedicationLogRemoteRecord, child: Child) -> Bool {
        let id = remote.id
        let existing = fetchOne(MedicationLog.self, predicate: #Predicate { $0.id == id })

        if let existing {
            guard shouldApply(remote: remote, localID: existing.id, localUpdatedAt: existing.updatedAt) else { return false }
            apply(remote, to: existing)
            existing.updatedAt = remote.updatedAt
            existing.deletedAt = remote.deletedAt
            existing.lastSyncedAt = .now
        } else {
            let log = MedicationLog(
                id: remote.id,
                child: child,
                medicationDefinitionID: remote.medicationDefinitionID,
                activeIngredientSnapshot: remote.activeIngredientSnapshot,
                concentrationValueSnapshot: remote.concentrationValueSnapshot,
                concentrationMillilitersSnapshot: remote.concentrationMillilitersSnapshot,
                concentrationUnitSnapshot: remote.concentrationUnitSnapshot,
                formSnapshot: remote.formSnapshot,
                brandSnapshot: remote.brandSnapshot,
                ruleVersionSnapshot: remote.ruleVersionSnapshot,
                sourceVersionSnapshot: remote.sourceVersionSnapshot,
                volumeMilliliters: remote.volumeMilliliters,
                calculatedMilligrams: remote.calculatedMilligrams,
                calculatedMilligramsPerKilogram: remote.calculatedMilligramsPerKilogram,
                weightUsedForCalculation: remote.weightUsedForCalculation,
                weightUnitUsedForCalculation: remote.weightUnitUsedForCalculation.flatMap(WeightUnit.init(rawValue:)),
                calculationStatus: MedicationCalculationStatus(rawValue: remote.calculationStatus) ?? .invalidInput,
                administeredAt: remote.administeredAt,
                createdAt: remote.createdAt,
                updatedAt: remote.updatedAt
            )
            log.deletedAt = remote.deletedAt
            log.lastSyncedAt = .now
            context.insert(log)
        }
        try? context.save()
        return true
    }

    private func apply(_ remote: MedicationLogRemoteRecord, to log: MedicationLog) {
        log.medicationDefinitionID = remote.medicationDefinitionID
        log.activeIngredientSnapshot = remote.activeIngredientSnapshot
        log.concentrationValueSnapshot = remote.concentrationValueSnapshot
        log.concentrationMillilitersSnapshot = remote.concentrationMillilitersSnapshot
        log.concentrationUnitSnapshot = remote.concentrationUnitSnapshot
        log.formSnapshot = remote.formSnapshot
        log.brandSnapshot = remote.brandSnapshot
        log.ruleVersionSnapshot = remote.ruleVersionSnapshot
        log.sourceVersionSnapshot = remote.sourceVersionSnapshot
        log.volumeMilliliters = remote.volumeMilliliters
        log.calculatedMilligrams = remote.calculatedMilligrams
        log.calculatedMilligramsPerKilogram = remote.calculatedMilligramsPerKilogram
        log.weightUsedForCalculation = remote.weightUsedForCalculation
        log.weightUnitUsedForCalculation = remote.weightUnitUsedForCalculation.flatMap(WeightUnit.init(rawValue:))
        log.calculationStatus = MedicationCalculationStatus(rawValue: remote.calculationStatus) ?? log.calculationStatus
        log.administeredAt = remote.administeredAt
    }

    @discardableResult
    func importSymptom(_ remote: SymptomRemoteRecord, child: Child) -> Bool {
        let id = remote.id
        let existing = fetchOne(SymptomEntry.self, predicate: #Predicate { $0.id == id })

        if let existing {
            guard shouldApply(remote: remote, localID: existing.id, localUpdatedAt: existing.updatedAt) else { return false }
            existing.symptomIdentifiers = remote.symptomIdentifiers
            existing.recordedAt = remote.recordedAt
            existing.updatedAt = remote.updatedAt
            existing.deletedAt = remote.deletedAt
            existing.lastSyncedAt = .now
        } else {
            let entry = SymptomEntry(
                id: remote.id,
                child: child,
                symptomIdentifiers: remote.symptomIdentifiers,
                recordedAt: remote.recordedAt,
                createdAt: remote.createdAt,
                updatedAt: remote.updatedAt
            )
            entry.deletedAt = remote.deletedAt
            entry.lastSyncedAt = .now
            context.insert(entry)
        }
        try? context.save()
        return true
    }

    @discardableResult
    func importNote(_ remote: NoteRemoteRecord, child: Child) -> Bool {
        let id = remote.id
        let existing = fetchOne(NoteEntry.self, predicate: #Predicate { $0.id == id })

        if let existing {
            guard shouldApply(remote: remote, localID: existing.id, localUpdatedAt: existing.updatedAt) else { return false }
            existing.text = remote.text
            existing.recordedAt = remote.recordedAt
            existing.updatedAt = remote.updatedAt
            existing.deletedAt = remote.deletedAt
            existing.lastSyncedAt = .now
        } else {
            let entry = NoteEntry(
                id: remote.id,
                child: child,
                text: remote.text,
                recordedAt: remote.recordedAt,
                createdAt: remote.createdAt,
                updatedAt: remote.updatedAt
            )
            entry.deletedAt = remote.deletedAt
            entry.lastSyncedAt = .now
            context.insert(entry)
        }
        try? context.save()
        return true
    }

    private func shouldApply(remote: some RemoteSyncTimestamped, localID: UUID, localUpdatedAt: Date) -> Bool {
        ConflictResolver.remoteWins(
            local: SyncVersionMetadata(id: localID.uuidString, updatedAt: localUpdatedAt),
            remote: SyncVersionMetadata(id: remote.id.uuidString, updatedAt: remote.updatedAt)
        )
    }

    private func fetchOne<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>) -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func parseDate(_ dateOnlyString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateOnlyString)
    }
}

/// Lets `shouldApply` work generically across every remote record type.
protocol RemoteSyncTimestamped {
    var id: UUID { get }
    var updatedAt: Date { get }
}

extension ChildRemoteRecord: RemoteSyncTimestamped {}
extension WeightHistoryRemoteRecord: RemoteSyncTimestamped {}
extension TemperatureLogRemoteRecord: RemoteSyncTimestamped {}
extension MedicationLogRemoteRecord: RemoteSyncTimestamped {}
extension SymptomRemoteRecord: RemoteSyncTimestamped {}
extension NoteRemoteRecord: RemoteSyncTimestamped {}
