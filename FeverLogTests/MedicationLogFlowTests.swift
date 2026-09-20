import FeverLogEngine
import Foundation
import SwiftData
import Testing
@testable import FeverLog

/// End-to-end tests exercising the full app-layer pipeline: catalog lookup
/// -> weight/prior-dose resolution -> engine evaluation -> SwiftData
/// snapshot persistence. The engine's own calculation correctness is
/// covered exhaustively in FeverLogEngine's own test target — these tests
/// only verify the app-layer wiring around it.
@MainActor
@Suite("Medication logging flow")
struct MedicationLogFlowTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainerFactory.makeInMemoryContainer()
    }

    private func makeChild(in container: ModelContainer) throws -> Child {
        let context = container.mainContext
        let household = try SwiftDataHouseholdRepository(context: context).createGuestHouseholdIfNeeded()
        return try SwiftDataChildRepository(context: context).create(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: ChildAvatarOption.star.rawValue,
            avatarColorIdentifier: ChildAvatarColorOption.mint.rawValue,
            household: household
        )
    }

    private func paracetamolRule() throws -> MedicationRule {
        let medications = MedicationCatalog.loadBundled()
        return try #require(medications.first { $0.id == "paracetamol-generic-160-5-suspension-example" })
    }

    private func evaluate(
        rule: MedicationRule,
        volume: Decimal,
        weight: WeightInput,
        at time: Date,
        priorLogs: [MedicationLog]
    ) -> MedicationSafetyResult {
        let input = MedicationDoseEvaluationInput(
            rule: rule,
            volumeMilliliters: volume,
            weight: weight,
            administrationTime: time,
            priorDoses: MedicationDoseInputMapper.priorDoseAdministrations(from: priorLogs)
        )
        return MedicationSafetyEngine.evaluate(input)
    }

    private func status(for result: MedicationSafetyResult) -> MedicationCalculationStatus {
        if result.statuses.contains(.invalidInput) { return .invalidInput }
        if result.statuses.contains(.missingWeight) { return .missingWeight }
        if result.statuses.contains(.missingRule) { return .missingRule }
        return .calculated
    }

    private func makeLog(
        child: Child,
        rule: MedicationRule,
        volumeMilliliters: Double,
        result: MedicationSafetyResult,
        weightKilograms: Double?,
        administeredAt: Date = .now
    ) -> MedicationLog {
        MedicationLog(
            child: child,
            medicationDefinitionID: rule.id,
            activeIngredientSnapshot: rule.activeIngredient,
            concentrationValueSnapshot: rule.concentration.milligrams.doubleValue,
            concentrationMillilitersSnapshot: rule.concentration.milliliters.doubleValue,
            concentrationUnitSnapshot: "mg/mL",
            formSnapshot: rule.form,
            brandSnapshot: rule.brand,
            ruleVersionSnapshot: "\(rule.databaseSchemaVersion)",
            sourceVersionSnapshot: rule.sourceVersion,
            volumeMilliliters: volumeMilliliters,
            calculatedMilligrams: result.calculatedMilligrams?.doubleValue,
            calculatedMilligramsPerKilogram: result.calculatedMilligramsPerKilogram?.doubleValue,
            weightUsedForCalculation: weightKilograms,
            weightUnitUsedForCalculation: weightKilograms != nil ? .kilograms : nil,
            calculationStatus: status(for: result),
            administeredAt: administeredAt
        )
    }

    @Test("missing weight is presented and saved without crashing")
    func missingWeightPresentation() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let rule = try paracetamolRule()

        let result = evaluate(rule: rule, volume: 5, weight: .missing, at: .now, priorLogs: [])
        #expect(result.statuses.contains(.missingWeight))
        #expect(result.calculatedMilligrams == 160)
        #expect(result.calculatedMilligramsPerKilogram == nil)

        let repository = SwiftDataMedicationLogRepository(context: container.mainContext)
        let log = makeLog(
            child: child, rule: rule, volumeMilliliters: 5, result: result,
            weightKilograms: nil, administeredAt: .now
        )
        try repository.create(log)

        let fetched = try repository.fetchAll(for: child)
        #expect(fetched.first?.calculationStatus == .missingWeight)
        #expect(fetched.first?.calculatedMilligrams == 160)
    }

    @Test("missing rule is presented without blocking the calculation")
    func missingRulePresentation() {
        let ruleWithoutConfig = MedicationRule(
            id: "no-rule-example",
            brand: "Unconfigured",
            activeIngredient: "Simethicone",
            concentration: Concentration(milligrams: 40, milliliters: 1),
            form: "drops",
            strength: "40 mg/mL",
            countryOrLocale: "example",
            singleDoseRule: nil,
            dailyMaximumRule: nil,
            sourceIdentifier: "example-reference-only",
            sourceVersion: "1.0",
            reviewStatus: .unreviewed,
            isActive: true,
            databaseSchemaVersion: 1
        )

        let result = evaluate(rule: ruleWithoutConfig, volume: 1, weight: .known(kilograms: 8), at: .now, priorLogs: [])

        #expect(result.statuses.contains(.missingRule))
        #expect(result.calculatedMilligrams == 40)
    }

    @Test("saved records preserve calculation inputs, outputs, rule version, and source version")
    func savedRecordPreservesSnapshot() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let rule = try paracetamolRule()
        let result = evaluate(rule: rule, volume: 5, weight: .known(kilograms: 12), at: .now, priorLogs: [])

        let repository = SwiftDataMedicationLogRepository(context: container.mainContext)
        let log = makeLog(
            child: child, rule: rule, volumeMilliliters: 5, result: result,
            weightKilograms: 12, administeredAt: .now
        )
        try repository.create(log)

        let fetched = try #require(try repository.fetchAll(for: child).first)
        #expect(fetched.medicationDefinitionID == rule.id)
        #expect(fetched.sourceVersionSnapshot == rule.sourceVersion)
        #expect(fetched.concentrationValueSnapshot == 160)
        #expect(fetched.concentrationMillilitersSnapshot == 5)
        #expect(fetched.calculatedMilligrams == 160)
        #expect(fetched.weightUsedForCalculation == 12)
    }

    @Test("editing one log recalculates only that record, leaving other historical logs untouched")
    func editingRecalculatesOnlyThatRecord() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let rule = try paracetamolRule()
        let repository = SwiftDataMedicationLogRepository(context: container.mainContext)

        let firstResult = evaluate(rule: rule, volume: 5, weight: .known(kilograms: 12), at: .now, priorLogs: [])
        let firstLog = makeLog(
            child: child, rule: rule, volumeMilliliters: 5, result: firstResult,
            weightKilograms: 12, administeredAt: .now.addingTimeInterval(-3600)
        )
        try repository.create(firstLog)

        let secondResult = evaluate(rule: rule, volume: 5, weight: .known(kilograms: 12), at: .now, priorLogs: [firstLog])
        let secondLog = makeLog(
            child: child, rule: rule, volumeMilliliters: 5, result: secondResult,
            weightKilograms: 12, administeredAt: .now
        )
        try repository.create(secondLog)

        // Edit the second log's volume — only its own snapshot should change.
        secondLog.volumeMilliliters = 10
        secondLog.calculatedMilligrams = 320
        try repository.update(secondLog)

        let allLogs = try repository.fetchAll(for: child)
        #expect(allLogs.count == 2)
        let unchangedFirst = try #require(allLogs.first { $0.id == firstLog.id })
        #expect(unchangedFirst.volumeMilliliters == 5)
        #expect(unchangedFirst.calculatedMilligrams == 160)
    }

    @Test("a local write is immediately queryable with no network or async dependency")
    func localWriteIsImmediatelyQueryable() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let rule = try paracetamolRule()
        let repository = SwiftDataMedicationLogRepository(context: container.mainContext)

        #expect(try repository.fetchAll(for: child).isEmpty)

        let result = evaluate(rule: rule, volume: 5, weight: .missing, at: .now, priorLogs: [])
        let log = makeLog(
            child: child, rule: rule, volumeMilliliters: 5, result: result,
            weightKilograms: nil, administeredAt: .now
        )
        // `create` is a synchronous, throwing call — no queue, no network,
        // no completion handler. Immediately after it returns, the record
        // is already visible to reads.
        try repository.create(log)

        #expect(try repository.fetchAll(for: child).count == 1)
    }
}
