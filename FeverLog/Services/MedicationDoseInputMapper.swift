import FeverLogEngine
import Foundation

/// Bridges SwiftData's `MedicationLog`/`WeightHistory` (Double-based,
/// app-layer) records to FeverLogEngine's `Decimal`-based input types. The
/// engine itself never sees SwiftData; this is the one place that seam is
/// crossed.
enum MedicationDoseInputMapper {
    static func priorDoseAdministrations(from logs: [MedicationLog]) -> [DoseAdministration] {
        logs.compactMap { log in
            guard let milligrams = log.calculatedMilligrams else { return nil }
            return DoseAdministration(
                id: log.id.uuidString,
                normalizedActiveIngredientKey: ActiveIngredientNormalizer.normalize(log.activeIngredientSnapshot),
                milligrams: Decimal.fromUserInput(milligrams),
                administeredAt: log.administeredAt
            )
        }
    }

    static func weightInput(from weightHistory: WeightHistory?) -> WeightInput {
        guard let weightHistory else { return .missing }
        let kilograms = WeightConversion.kilograms(from: weightHistory.weight, unit: weightHistory.unit)
        guard kilograms > 0 else { return .missing }
        return .known(kilograms: kilograms)
    }
}
