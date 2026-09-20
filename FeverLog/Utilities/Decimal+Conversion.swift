import Foundation

extension Decimal {
    /// Converts a `Double` sourced from user input (e.g. a SwiftData field
    /// that was originally typed as text) via its string representation, to
    /// avoid the binary floating-point drift that `Decimal(_ double: Double)`
    /// can introduce (e.g. `Decimal(0.1) != Decimal(string: "0.1")`).
    static func fromUserInput(_ value: Double) -> Decimal {
        Decimal(string: String(value)) ?? Decimal(value)
    }

    /// Display-only conversion back to `Double`, for formatting an
    /// already-computed, already-rounded value. Never use this to feed a
    /// value into a new calculation.
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
