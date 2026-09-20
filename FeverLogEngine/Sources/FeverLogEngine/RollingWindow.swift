import Foundation

/// A single prior dose administration, as computed by the application layer
/// from a saved log entry's snapshot. `normalizedActiveIngredientKey` must
/// come from the same `ActiveIngredientNormalizer` the engine uses, so
/// callers should derive it via `MedicationRule.normalizedActiveIngredientKey`
/// rather than recomputing it separately.
public struct DoseAdministration: Equatable, Sendable {
    public let id: String
    public let normalizedActiveIngredientKey: String
    public let milligrams: Decimal
    public let administeredAt: Date

    public init(id: String, normalizedActiveIngredientKey: String, milligrams: Decimal, administeredAt: Date) {
        self.id = id
        self.normalizedActiveIngredientKey = normalizedActiveIngredientKey
        self.milligrams = milligrams
        self.administeredAt = administeredAt
    }
}

public struct RollingWindowResult: Equatable, Sendable {
    public let totalMilligrams: Decimal
    public let doseCount: Int
    public let dosesInWindow: [DoseAdministration]
}

public enum RollingWindow {
    public static let defaultDuration: TimeInterval = 24 * 60 * 60

    /// Doses in the half-open window `[administrationTime - windowDuration,
    /// administrationTime)`, matching the given normalized active-ingredient
    /// key. The dose being evaluated is never included here — callers add it
    /// separately to compute a projected post-save total. All comparisons
    /// use absolute instants; the window is not reset at local midnight and
    /// is unaffected by the calendar or timezone.
    public static func doses(
        from allDoses: [DoseAdministration],
        matchingNormalizedKey key: String,
        at administrationTime: Date,
        windowDuration: TimeInterval = defaultDuration
    ) -> RollingWindowResult {
        let lowerBound = administrationTime.addingTimeInterval(-windowDuration)
        let matching = allDoses.filter {
            $0.normalizedActiveIngredientKey == key
                && $0.administeredAt >= lowerBound
                && $0.administeredAt < administrationTime
        }
        let total = matching.reduce(Decimal(0)) { $0 + $1.milligrams }
        return RollingWindowResult(totalMilligrams: total, doseCount: matching.count, dosesInWindow: matching)
    }
}
