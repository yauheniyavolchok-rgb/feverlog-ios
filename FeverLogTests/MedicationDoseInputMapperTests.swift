import FeverLogEngine
import Foundation
import SwiftData
import Testing
@testable import FeverLog

@MainActor
@Suite("MedicationDoseInputMapper")
struct MedicationDoseInputMapperTests {
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

    @Test("maps saved medication logs into engine dose administrations")
    func mapsPriorDoses() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let context = container.mainContext

        let log = MedicationLog(
            child: child,
            medicationDefinitionID: "paracetamol-generic-160-5-suspension-example",
            activeIngredientSnapshot: "Paracetamol",
            concentrationValueSnapshot: 160,
            concentrationMillilitersSnapshot: 5,
            concentrationUnitSnapshot: "mg/mL",
            formSnapshot: "oral suspension",
            brandSnapshot: "Generic",
            ruleVersionSnapshot: "1",
            sourceVersionSnapshot: "2026.1-draft",
            volumeMilliliters: 5,
            calculatedMilligrams: 160,
            calculatedMilligramsPerKilogram: 16,
            weightUsedForCalculation: 10,
            weightUnitUsedForCalculation: .kilograms,
            calculationStatus: .calculated,
            administeredAt: .now
        )
        context.insert(log)
        try context.save()

        let administrations = MedicationDoseInputMapper.priorDoseAdministrations(from: [log])

        #expect(administrations.count == 1)
        #expect(administrations.first?.milligrams == 160)
        #expect(administrations.first?.normalizedActiveIngredientKey == ActiveIngredientNormalizer.normalize("Paracetamol"))
    }

    @Test("a log with no calculated milligrams (invalid input) is excluded from prior doses")
    func excludesLogsWithoutCalculatedMilligrams() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)

        let log = MedicationLog(
            child: child,
            medicationDefinitionID: "x",
            activeIngredientSnapshot: "Paracetamol",
            concentrationValueSnapshot: 160,
            concentrationMillilitersSnapshot: 5,
            concentrationUnitSnapshot: "mg/mL",
            formSnapshot: "oral suspension",
            brandSnapshot: "Generic",
            ruleVersionSnapshot: "1",
            sourceVersionSnapshot: "2026.1-draft",
            volumeMilliliters: 0,
            calculatedMilligrams: nil,
            calculatedMilligramsPerKilogram: nil,
            weightUsedForCalculation: nil,
            weightUnitUsedForCalculation: nil,
            calculationStatus: .invalidInput,
            administeredAt: .now
        )

        let administrations = MedicationDoseInputMapper.priorDoseAdministrations(from: [log])

        #expect(administrations.isEmpty)
    }

    @Test("weightInput is .missing when no weight history exists")
    func weightInputIsMissingWithoutHistory() {
        let input = MedicationDoseInputMapper.weightInput(from: nil)
        #expect(input == .missing)
    }

    @Test("weightInput resolves kilograms directly")
    func weightInputResolvesKilograms() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let weight = WeightHistory(child: child, weight: 10.4, unit: .kilograms, effectiveDate: .now)

        let input = MedicationDoseInputMapper.weightInput(from: weight)

        #expect(input == .known(kilograms: Decimal(string: "10.4") ?? 0))
    }

    @Test("weightInput converts pounds to kilograms")
    func weightInputConvertsPounds() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let weight = WeightHistory(child: child, weight: 22, unit: .pounds, effectiveDate: .now)

        let input = MedicationDoseInputMapper.weightInput(from: weight)

        guard case .known(let kilograms) = input else {
            Issue.record("expected .known weight")
            return
        }
        #expect(kilograms > 9.9)
        #expect(kilograms < 10.0)
    }
}
