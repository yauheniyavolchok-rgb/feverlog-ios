import Foundation

enum TemperatureValidationError: Error, Equatable, Sendable {
    case outOfRange
}

enum TemperatureValidator {
    static let validRange: ClosedRange<Double> = 34.0...42.0

    /// Rounds to one decimal place (tenths precision, matching how the app
    /// stores and displays temperatures) and validates the supported range.
    static func validate(_ celsius: Double) -> Result<Double, TemperatureValidationError> {
        let rounded = (celsius * 10).rounded() / 10
        guard validRange.contains(rounded) else { return .failure(.outOfRange) }
        return .success(rounded)
    }
}
