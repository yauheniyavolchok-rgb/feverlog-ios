import Foundation

public enum DoseCalculationError: Error, Equatable, Sendable {
    case invalidVolume
    case invalidConcentration
}

/// Pure, decimal-safe dose arithmetic. Uses `Decimal` throughout rather than
/// `Double` so that safety-boundary comparisons never shift silently due to
/// binary floating-point rounding.
public enum DoseCalculator {
    public static func milligrams(
        volumeMilliliters: Decimal,
        concentration: Concentration
    ) -> Result<Decimal, DoseCalculationError> {
        guard volumeMilliliters > 0 else { return .failure(.invalidVolume) }
        guard concentration.milligrams > 0, concentration.milliliters > 0,
              let perMilliliter = concentration.milligramsPerMilliliter
        else {
            return .failure(.invalidConcentration)
        }
        return .success(volumeMilliliters * perMilliliter)
    }

    /// `nil` when the weight is not strictly positive — the caller (the
    /// safety engine) is responsible for representing that as a typed
    /// missing-weight finding rather than a crash or an inferred value.
    public static func milligramsPerKilogram(milligrams: Decimal, weightKilograms: Decimal) -> Decimal? {
        guard weightKilograms > 0 else { return nil }
        return milligrams / weightKilograms
    }
}
