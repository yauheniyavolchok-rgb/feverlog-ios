import Foundation
import SwiftData

enum MedicationCalculationStatus: String, Codable, Sendable {
    case calculated
    case missingWeight
    case missingRule
    case invalidInput
}

/// Every field here is a snapshot captured at administration time. Editing
/// the medication library or a child's weight history later must never
/// change what a historical `MedicationLog` says happened.
@Model
final class MedicationLog {
    var id: UUID
    var childID: UUID
    var child: Child?

    var medicationDefinitionID: UUID?

    // Snapshots — captured once at administration time, never re-derived.
    var activeIngredientSnapshot: String
    var concentrationValueSnapshot: Double
    var concentrationUnitSnapshot: String
    var formSnapshot: String
    var brandSnapshot: String
    var ruleVersionSnapshot: String?
    var sourceVersionSnapshot: String?

    var volumeMilliliters: Double
    var calculatedMilligrams: Double?
    var calculatedMilligramsPerKilogram: Double?
    var weightUsedForCalculation: Double?
    var weightUnitUsedForCalculation: WeightUnit?
    var calculationStatus: MedicationCalculationStatus

    var administeredAt: Date

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var lastSyncedAt: Date?
    var syncVersion: Int

    init(
        id: UUID = UUID(),
        child: Child,
        medicationDefinitionID: UUID?,
        activeIngredientSnapshot: String,
        concentrationValueSnapshot: Double,
        concentrationUnitSnapshot: String,
        formSnapshot: String,
        brandSnapshot: String,
        ruleVersionSnapshot: String?,
        sourceVersionSnapshot: String?,
        volumeMilliliters: Double,
        calculatedMilligrams: Double?,
        calculatedMilligramsPerKilogram: Double?,
        weightUsedForCalculation: Double?,
        weightUnitUsedForCalculation: WeightUnit?,
        calculationStatus: MedicationCalculationStatus,
        administeredAt: Date,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.childID = child.id
        self.child = child
        self.medicationDefinitionID = medicationDefinitionID
        self.activeIngredientSnapshot = activeIngredientSnapshot
        self.concentrationValueSnapshot = concentrationValueSnapshot
        self.concentrationUnitSnapshot = concentrationUnitSnapshot
        self.formSnapshot = formSnapshot
        self.brandSnapshot = brandSnapshot
        self.ruleVersionSnapshot = ruleVersionSnapshot
        self.sourceVersionSnapshot = sourceVersionSnapshot
        self.volumeMilliliters = volumeMilliliters
        self.calculatedMilligrams = calculatedMilligrams
        self.calculatedMilligramsPerKilogram = calculatedMilligramsPerKilogram
        self.weightUsedForCalculation = weightUsedForCalculation
        self.weightUnitUsedForCalculation = weightUnitUsedForCalculation
        self.calculationStatus = calculationStatus
        self.administeredAt = administeredAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
        self.lastSyncedAt = nil
        self.syncVersion = 0
    }
}

extension MedicationLog: SyncableRecord {}
