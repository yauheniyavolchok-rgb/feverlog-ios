import Foundation

/// Presentation-only temperature classification. These thresholds are
/// display thresholds and must never be reused as medication safety rules —
/// that logic lives entirely in the independent FeverLogEngine package.
enum TemperatureStatus: String, CaseIterable, Equatable, Sendable {
    case normal
    case elevated
    case high
    case veryHigh
    case critical
}

enum TemperatureClassifier {
    /// Classifies a Celsius temperature into a presentation status.
    ///
    /// | Range (°C)     | Status    |
    /// |----------------|-----------|
    /// | 36.0–37.4      | normal    |
    /// | 37.5–38.0      | elevated  |
    /// | 38.1–39.0      | high      |
    /// | 39.1–40.0      | veryHigh  |
    /// | 40.1 and above | critical  |
    ///
    /// Values below 36.0 are classified as `normal` (no distinct "low"
    /// status is defined in v1).
    ///
    /// Comparison is done in tenths-of-a-degree integers to avoid
    /// floating-point boundary ambiguity at the 0.1°C precision the app
    /// stores temperatures at.
    static func classify(celsius: Double) -> TemperatureStatus {
        let tenths = Int((celsius * 10).rounded())
        switch tenths {
        case ..<375: return .normal
        case 375..<381: return .elevated
        case 381..<391: return .high
        case 391..<401: return .veryHigh
        default: return .critical
        }
    }
}
