import Foundation

/// Reference-data dosing rule as published by the medication's source. This
/// is application-layer reference data — the deterministic engine in
/// FeverLogEngine (Phase 5) is the sole authority for actually evaluating a
/// dose against these numbers.
struct SingleDoseRule: Codable, Equatable, Sendable {
    var minMilligramsPerKilogram: Double?
    var maxMilligramsPerKilogram: Double?
    var maxMilligramsPerDose: Double?
}

struct DailyMaximumRule: Codable, Equatable, Sendable {
    var maxMilligramsPerKilogramPerDay: Double?
    var maxMilligramsPerDay: Double?
    var maxDosesPerDay: Int?
    var minimumIntervalSeconds: Double?
}

enum MedicationReviewStatus: String, Codable, Sendable {
    case unreviewed
    case reviewed
    case deprecated
}
