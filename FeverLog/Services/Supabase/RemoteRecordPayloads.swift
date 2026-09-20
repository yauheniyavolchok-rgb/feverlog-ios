import Foundation

/// One Encodable payload per synchronized table, matching the Postgres
/// schema in supabase/migrations exactly (explicit `CodingKeys` throughout
/// — the client does not use automatic snake_case conversion, and it
/// would mis-convert `ID` suffixes like `householdID` → `household_i_d`
/// anyway). Each is built fresh at upload time from the current local
/// record, never cached, so it always reflects the latest local state —
/// see `SyncUploadProcessor`.

struct ChildRemoteRecord: Codable {
    let id: UUID
    let householdID: UUID
    let name: String
    let birthday: String
    let avatarIdentifier: String
    let avatarColorIdentifier: String
    let cachedWeightValue: Double?
    let cachedWeightUnit: String?
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case householdID = "household_id"
        case name
        case birthday
        case avatarIdentifier = "avatar_identifier"
        case avatarColorIdentifier = "avatar_color_identifier"
        case cachedWeightValue = "cached_weight_value"
        case cachedWeightUnit = "cached_weight_unit"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct WeightHistoryRemoteRecord: Codable {
    let id: UUID
    let childID: UUID
    let weight: Double
    let unit: String
    let effectiveDate: String
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case childID = "child_id"
        case weight
        case unit
        case effectiveDate = "effective_date"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct TemperatureLogRemoteRecord: Codable {
    let id: UUID
    let childID: UUID
    let temperatureCelsius: Double
    let measurementMethod: String
    let recordedAt: Date
    let note: String?
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case childID = "child_id"
        case temperatureCelsius = "temperature_celsius"
        case measurementMethod = "measurement_method"
        case recordedAt = "recorded_at"
        case note
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct MedicationLogRemoteRecord: Codable {
    let id: UUID
    let childID: UUID
    let medicationDefinitionID: String?
    let activeIngredientSnapshot: String
    let concentrationValueSnapshot: Double
    let concentrationMillilitersSnapshot: Double
    let concentrationUnitSnapshot: String
    let formSnapshot: String
    let brandSnapshot: String
    let ruleVersionSnapshot: String?
    let sourceVersionSnapshot: String?
    let volumeMilliliters: Double
    let calculatedMilligrams: Double?
    let calculatedMilligramsPerKilogram: Double?
    let weightUsedForCalculation: Double?
    let weightUnitUsedForCalculation: String?
    let calculationStatus: String
    let administeredAt: Date
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case childID = "child_id"
        case medicationDefinitionID = "medication_definition_id"
        case activeIngredientSnapshot = "active_ingredient_snapshot"
        case concentrationValueSnapshot = "concentration_value_snapshot"
        case concentrationMillilitersSnapshot = "concentration_milliliters_snapshot"
        case concentrationUnitSnapshot = "concentration_unit_snapshot"
        case formSnapshot = "form_snapshot"
        case brandSnapshot = "brand_snapshot"
        case ruleVersionSnapshot = "rule_version_snapshot"
        case sourceVersionSnapshot = "source_version_snapshot"
        case volumeMilliliters = "volume_milliliters"
        case calculatedMilligrams = "calculated_milligrams"
        case calculatedMilligramsPerKilogram = "calculated_milligrams_per_kilogram"
        case weightUsedForCalculation = "weight_used_for_calculation"
        case weightUnitUsedForCalculation = "weight_unit_used_for_calculation"
        case calculationStatus = "calculation_status"
        case administeredAt = "administered_at"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct SymptomRemoteRecord: Codable {
    let id: UUID
    let childID: UUID
    let symptomIdentifiers: [String]
    let recordedAt: Date
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case childID = "child_id"
        case symptomIdentifiers = "symptom_identifiers"
        case recordedAt = "recorded_at"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct NoteRemoteRecord: Codable {
    let id: UUID
    let childID: UUID
    let text: String
    let recordedAt: Date
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case childID = "child_id"
        case text
        case recordedAt = "recorded_at"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}
