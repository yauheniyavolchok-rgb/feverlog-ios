import Foundation
@testable import FeverLogEngine

enum MedicationSafetyEngineTestFixtures {
    static func makeRule(
        id: String = "test-med",
        brand: String = "TestBrand",
        activeIngredient: String = "Paracetamol",
        concentrationMilligrams: Decimal = 160,
        concentrationMilliliters: Decimal = 5,
        singleDoseRule: SingleDoseRule? = SingleDoseRule(
            minMilligramsPerKilogram: 10,
            maxMilligramsPerKilogram: 15,
            maxMilligramsPerDose: nil
        ),
        dailyMaximumRule: DailyMaximumRule? = DailyMaximumRule(
            maxMilligramsPerKilogramPerDay: 75,
            maxMilligramsPerDay: 1000,
            maxDosesPerDay: 5,
            minimumIntervalSeconds: 4 * 3600
        )
    ) -> MedicationRule {
        MedicationRule(
            id: id,
            brand: brand,
            activeIngredient: activeIngredient,
            concentration: Concentration(milligrams: concentrationMilligrams, milliliters: concentrationMilliliters),
            form: "oral suspension",
            strength: "\(concentrationMilligrams) mg / \(concentrationMilliliters) mL",
            countryOrLocale: "test",
            singleDoseRule: singleDoseRule,
            dailyMaximumRule: dailyMaximumRule,
            sourceIdentifier: "test-fixture",
            sourceVersion: "1.0",
            reviewStatus: .unreviewed,
            isActive: true,
            databaseSchemaVersion: 1
        )
    }

    static func priorDose(_ milligrams: Decimal, at date: Date, rule: MedicationRule) -> DoseAdministration {
        DoseAdministration(
            id: UUID().uuidString,
            normalizedActiveIngredientKey: rule.normalizedActiveIngredientKey,
            milligrams: milligrams,
            administeredAt: date
        )
    }
}
