import Foundation
import Testing
@testable import FeverLogEngine

@Suite("MedicationSafetyEngine grouping, historical weight, and determinism")
struct MedicationSafetyEngineGroupingTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeRule(
        id: String,
        activeIngredient: String,
        concentrationMilligrams: Decimal = 160,
        concentrationMilliliters: Decimal = 5,
        singleDoseRule: SingleDoseRule? = SingleDoseRule(
            minMilligramsPerKilogram: 10,
            maxMilligramsPerKilogram: 15,
            maxMilligramsPerDose: nil
        )
    ) -> MedicationRule {
        MedicationSafetyEngineTestFixtures.makeRule(
            id: id,
            activeIngredient: activeIngredient,
            concentrationMilligrams: concentrationMilligrams,
            concentrationMilliliters: concentrationMilliliters,
            singleDoseRule: singleDoseRule
        )
    }

    private func priorDose(_ milligrams: Decimal, at date: Date, rule: MedicationRule) -> DoseAdministration {
        MedicationSafetyEngineTestFixtures.priorDose(milligrams, at: date, rule: rule)
    }

    // MARK: - Grouping across brands/forms/concentrations, never across ingredients

    @Test("prior doses of a different brand/concentration but same active ingredient still count toward the rolling total")
    func groupsAcrossBrandsAndConcentrations() {
        let ruleA = makeRule(
            id: "brand-a",
            activeIngredient: "Acetaminophen",
            concentrationMilligrams: 160,
            concentrationMilliliters: 5
        )
        let ruleB = makeRule(
            id: "brand-b",
            activeIngredient: "Paracetamol",
            concentrationMilligrams: 250,
            concentrationMilliliters: 5
        )

        let input = MedicationDoseEvaluationInput(
            rule: ruleA,
            volumeMilliliters: 5, // 160mg
            weight: .known(kilograms: 100),
            administrationTime: now,
            priorDoses: [priorDose(250, at: now.addingTimeInterval(-3600), rule: ruleB)]
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.doseCount == 2)
        #expect(result.rollingTotalMilligrams == 410)
    }

    @Test("prior doses of a different active ingredient never count toward the rolling total")
    func neverGroupsDifferentActiveIngredients() {
        let paracetamol = makeRule(id: "para", activeIngredient: "Paracetamol")
        let ibuprofen = makeRule(id: "ibu", activeIngredient: "Ibuprofen")

        let input = MedicationDoseEvaluationInput(
            rule: paracetamol,
            volumeMilliliters: 5,
            weight: .known(kilograms: 100),
            administrationTime: now,
            priorDoses: [priorDose(999, at: now.addingTimeInterval(-3600), rule: ibuprofen)]
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.doseCount == 1)
        #expect(result.rollingTotalMilligrams == 160)
    }

    // MARK: - Historical weight

    @Test("the engine uses exactly the weight it is given, not any notion of a 'current' weight")
    func usesSuppliedWeightExactly() {
        let rule = makeRule(id: "para", activeIngredient: "Paracetamol", singleDoseRule: nil) // avoid unusualDose noise
        let historicalWeightInput = MedicationDoseEvaluationInput(
            rule: rule, volumeMilliliters: 5, weight: .known(kilograms: 8), administrationTime: now, priorDoses: []
        )
        let currentWeightInput = MedicationDoseEvaluationInput(
            rule: rule, volumeMilliliters: 5, weight: .known(kilograms: 12), administrationTime: now, priorDoses: []
        )

        let historicalResult = MedicationSafetyEngine.evaluate(historicalWeightInput)
        let currentResult = MedicationSafetyEngine.evaluate(currentWeightInput)

        #expect(historicalResult.calculatedMilligramsPerKilogram == Decimal(160) / Decimal(8))
        #expect(currentResult.calculatedMilligramsPerKilogram == Decimal(160) / Decimal(12))
        #expect(historicalResult.calculatedMilligramsPerKilogram != currentResult.calculatedMilligramsPerKilogram)
    }

    // MARK: - Determinism

    @Test("evaluating the same input twice produces identical results")
    func isDeterministic() {
        let rule = makeRule(id: "para", activeIngredient: "Paracetamol")
        let input = MedicationDoseEvaluationInput(
            rule: rule,
            volumeMilliliters: 5,
            weight: .known(kilograms: 12),
            administrationTime: now,
            priorDoses: [priorDose(100, at: now.addingTimeInterval(-3600), rule: rule)]
        )

        let first = MedicationSafetyEngine.evaluate(input)
        let second = MedicationSafetyEngine.evaluate(input)

        #expect(first == second)
    }
}
