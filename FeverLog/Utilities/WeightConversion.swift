import Foundation

enum WeightConversion {
    private static let poundsToKilogramsFactor = Decimal(string: "0.45359237") ?? Decimal(0.45359237)

    static func kilograms(from weight: Double, unit: WeightUnit) -> Decimal {
        let value = Decimal.fromUserInput(weight)
        switch unit {
        case .kilograms:
            return value
        case .pounds:
            return value * poundsToKilogramsFactor
        }
    }
}
