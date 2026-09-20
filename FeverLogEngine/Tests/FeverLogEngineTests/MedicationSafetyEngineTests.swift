import Foundation
import Testing
@testable import FeverLogEngine

@Suite("MedicationSafetyEngine")
struct MedicationSafetyEngineTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeRule(
        id: String = "test-med",
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
        MedicationSafetyEngineTestFixtures.makeRule(
            id: id,
            activeIngredient: activeIngredient,
            concentrationMilligrams: concentrationMilligrams,
            concentrationMilliliters: concentrationMilliliters,
            singleDoseRule: singleDoseRule,
            dailyMaximumRule: dailyMaximumRule
        )
    }

    private func priorDose(_ milligrams: Decimal, at date: Date, rule: MedicationRule) -> DoseAdministration {
        MedicationSafetyEngineTestFixtures.priorDose(milligrams, at: date, rule: rule)
    }

    // MARK: - Basic calculation

    @Test("calculates milligrams and mg/kg for a normal dose")
    func calculatesNormalDose() {
        let rule = makeRule()
        let input = MedicationDoseEvaluationInput(
            rule: rule,
            volumeMilliliters: 5, // 160 mg
            weight: .known(kilograms: 12),
            administrationTime: now,
            priorDoses: []
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.calculatedMilligrams == 160)
        #expect(result.calculatedMilligramsPerKilogram == Decimal(160) / Decimal(12))
        #expect(result.statuses == [.normal])
        #expect(result.doseCount == 1)
    }

    // MARK: - Invalid input

    @Test("invalid volume yields invalidInput status and no calculated values")
    func invalidVolumeYieldsInvalidInput() {
        let rule = makeRule()
        let input = MedicationDoseEvaluationInput(
            rule: rule, volumeMilliliters: -1, weight: .known(kilograms: 10), administrationTime: now, priorDoses: []
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.statuses == [.invalidInput])
        #expect(result.calculatedMilligrams == nil)
        #expect(result.explanationCodes == [.invalidVolumeOrConcentration])
    }

    @Test("invalid concentration yields invalidInput status")
    func invalidConcentrationYieldsInvalidInput() {
        let rule = makeRule(concentrationMilligrams: 0, concentrationMilliliters: 5)
        let input = MedicationDoseEvaluationInput(
            rule: rule, volumeMilliliters: 5, weight: .known(kilograms: 10), administrationTime: now, priorDoses: []
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.statuses == [.invalidInput])
    }

    // MARK: - Missing weight / rule

    @Test("missing weight is reported without crashing, calculation still returns milligrams")
    func missingWeightIsReported() {
        let rule = makeRule()
        let input = MedicationDoseEvaluationInput(
            rule: rule, volumeMilliliters: 5, weight: .missing, administrationTime: now, priorDoses: []
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.statuses.contains(.missingWeight))
        #expect(result.calculatedMilligrams == 160)
        #expect(result.calculatedMilligramsPerKilogram == nil)
        #expect(result.explanationCodes.contains(.missingWeightForCalculation))
    }

    @Test("a medication with no configured rule at all reports missingRule explicitly")
    func missingRuleIsReportedExplicitly() {
        let rule = makeRule(singleDoseRule: nil, dailyMaximumRule: nil)
        let input = MedicationDoseEvaluationInput(
            rule: rule, volumeMilliliters: 5, weight: .known(kilograms: 12), administrationTime: now, priorDoses: []
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.statuses.contains(.missingRule))
        #expect(result.explanationCodes.contains(.missingConfiguredRule))
        // Calculated values are still returned — the engine never blocks a
        // calculation just because there's no rule to check it against.
        #expect(result.calculatedMilligrams == 160)
    }

    // MARK: - Minimum interval

    @Test("a dose at exactly the minimum interval is allowed (no interval warning)")
    func exactMinimumIntervalIsAllowed() throws {
        let rule = makeRule()
        let minInterval = try #require(rule.dailyMaximumRule?.minimumIntervalSeconds)
        let priorTime = now.addingTimeInterval(-minInterval)
        let input = MedicationDoseEvaluationInput(
            rule: rule,
            volumeMilliliters: 5,
            weight: .known(kilograms: 12),
            administrationTime: now,
            priorDoses: [priorDose(160, at: priorTime, rule: rule)]
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(!result.statuses.contains(.intervalWarning))
    }

    @Test("a dose one second before the minimum interval triggers an interval warning")
    func belowMinimumIntervalTriggersWarning() throws {
        let rule = makeRule()
        let minInterval = try #require(rule.dailyMaximumRule?.minimumIntervalSeconds)
        let priorTime = now.addingTimeInterval(-minInterval + 1)
        let input = MedicationDoseEvaluationInput(
            rule: rule,
            volumeMilliliters: 5,
            weight: .known(kilograms: 12),
            administrationTime: now,
            priorDoses: [priorDose(160, at: priorTime, rule: rule)]
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.statuses.contains(.intervalWarning))
        #expect(result.explanationCodes.contains(.intervalNotElapsed))
    }

    @Test("next eligible dose time is the prior dose time plus the minimum interval")
    func nextEligibleDateCalculation() throws {
        let rule = makeRule()
        let minInterval = try #require(rule.dailyMaximumRule?.minimumIntervalSeconds)
        let priorTime = now.addingTimeInterval(-3600)
        let input = MedicationDoseEvaluationInput(
            rule: rule,
            volumeMilliliters: 5,
            weight: .known(kilograms: 12),
            administrationTime: now,
            priorDoses: [priorDose(160, at: priorTime, rule: rule)]
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.nextEligibleDate == priorTime.addingTimeInterval(minInterval))
    }

    @Test("no prior dose yields no next eligible date and a noPriorDose explanation")
    func noPriorDoseYieldsNoNextEligibleDate() {
        let rule = makeRule()
        let input = MedicationDoseEvaluationInput(
            rule: rule, volumeMilliliters: 5, weight: .known(kilograms: 12), administrationTime: now, priorDoses: []
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.nextEligibleDate == nil)
        #expect(result.explanationCodes.contains(.noPriorDose))
    }

    // MARK: - Approaching / exceeding maximums

    @Test("projected total approaching the daily maximum reports approachingMaximum")
    func approachingDailyMaximum() {
        let rule = makeRule()
        // Daily max is 1000mg. Prior total 700mg + this 160mg dose = 860mg (86%, over the 80% threshold, under 100%).
        let input = MedicationDoseEvaluationInput(
            rule: rule,
            volumeMilliliters: 5,
            weight: .known(kilograms: 100), // large weight so the per-kg rule doesn't also trip
            administrationTime: now,
            priorDoses: [priorDose(700, at: now.addingTimeInterval(-3600), rule: rule)]
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.statuses.contains(.approachingMaximum))
        #expect(!result.statuses.contains(.maximumExceeded))
        #expect(result.explanationCodes.contains(.approachingDailyMaximum))
    }

    @Test("projected total over the daily maximum reports maximumExceeded")
    func exceedsDailyMaximum() {
        let rule = makeRule()
        let input = MedicationDoseEvaluationInput(
            rule: rule,
            volumeMilliliters: 5,
            weight: .known(kilograms: 100),
            administrationTime: now,
            priorDoses: [priorDose(900, at: now.addingTimeInterval(-3600), rule: rule)]
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.statuses.contains(.maximumExceeded))
        #expect(result.explanationCodes.contains(.dailyMaximumExceeded))
    }

    @Test("projected dose count over the configured maximum reports maximumExceeded")
    func exceedsMaximumDoseCount() {
        let rule = makeRule()
        let priorDoses = (1...5).map { index in
            priorDose(50, at: now.addingTimeInterval(-Double(index) * 3600), rule: rule)
        }
        let input = MedicationDoseEvaluationInput(
            rule: rule,
            volumeMilliliters: 5,
            weight: .known(kilograms: 100),
            administrationTime: now,
            priorDoses: priorDoses
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.doseCount == 6)
        #expect(result.statuses.contains(.maximumExceeded))
    }

    @Test("a rule with no daily maximum configured never reports approachingMaximum or maximumExceeded")
    func noDailyMaximumConfiguredNeverExceeds() {
        let rule = makeRule(dailyMaximumRule: nil)
        let input = MedicationDoseEvaluationInput(
            rule: rule,
            volumeMilliliters: 5,
            weight: .known(kilograms: 1), // tiny weight, would blow any real per-kg rule
            administrationTime: now,
            priorDoses: []
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(!result.statuses.contains(.approachingMaximum))
        #expect(!result.statuses.contains(.maximumExceeded))
    }

    // MARK: - Unusual single dose

    @Test("a dose above the recommended per-kg range is flagged as unusual")
    func aboveRecommendedRangeIsUnusual() {
        let rule = makeRule()
        // 160mg / 5kg = 32 mg/kg, well above the 15 mg/kg max.
        let input = MedicationDoseEvaluationInput(
            rule: rule, volumeMilliliters: 5, weight: .known(kilograms: 5), administrationTime: now, priorDoses: []
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.statuses.contains(.unusualDose))
    }

    @Test("a dose below the recommended per-kg range is flagged as unusual")
    func belowRecommendedRangeIsUnusual() {
        let rule = makeRule()
        // 160mg / 50kg = 3.2 mg/kg, below the 10 mg/kg minimum.
        let input = MedicationDoseEvaluationInput(
            rule: rule, volumeMilliliters: 5, weight: .known(kilograms: 50), administrationTime: now, priorDoses: []
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(result.statuses.contains(.unusualDose))
    }

    @Test("a dose within the recommended per-kg range is not flagged as unusual")
    func withinRecommendedRangeIsNotUnusual() {
        let rule = makeRule()
        // 160mg / 12kg ≈ 13.3 mg/kg, within 10-15.
        let input = MedicationDoseEvaluationInput(
            rule: rule, volumeMilliliters: 5, weight: .known(kilograms: 12), administrationTime: now, priorDoses: []
        )

        let result = MedicationSafetyEngine.evaluate(input)

        #expect(!result.statuses.contains(.unusualDose))
    }
}
