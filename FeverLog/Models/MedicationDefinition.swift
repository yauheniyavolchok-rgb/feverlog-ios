import Foundation
import SwiftData

/// Reference data, not a user-entered clinical prescription. Definitions are
/// versioned — updating a definition must never mutate the meaning of an
/// existing `MedicationLog`, which stores its own immutable snapshot.
@Model
final class MedicationDefinition {
    var id: UUID

    var brand: String
    var activeIngredient: String
    var concentrationValue: Double
    var concentrationUnit: String
    var form: String
    var strength: String

    var singleDoseRule: SingleDoseRule?
    var dailyMaximumRule: DailyMaximumRule?

    var localeIdentifier: String
    var sourceIdentifier: String
    var sourceVersion: String
    var reviewStatus: MedicationReviewStatus
    var isActive: Bool
    var databaseSchemaVersion: Int

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        brand: String,
        activeIngredient: String,
        concentrationValue: Double,
        concentrationUnit: String,
        form: String,
        strength: String,
        singleDoseRule: SingleDoseRule? = nil,
        dailyMaximumRule: DailyMaximumRule? = nil,
        localeIdentifier: String,
        sourceIdentifier: String,
        sourceVersion: String,
        reviewStatus: MedicationReviewStatus = .unreviewed,
        isActive: Bool = true,
        databaseSchemaVersion: Int = 1,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.brand = brand
        self.activeIngredient = activeIngredient
        self.concentrationValue = concentrationValue
        self.concentrationUnit = concentrationUnit
        self.form = form
        self.strength = strength
        self.singleDoseRule = singleDoseRule
        self.dailyMaximumRule = dailyMaximumRule
        self.localeIdentifier = localeIdentifier
        self.sourceIdentifier = sourceIdentifier
        self.sourceVersion = sourceVersion
        self.reviewStatus = reviewStatus
        self.isActive = isActive
        self.databaseSchemaVersion = databaseSchemaVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
