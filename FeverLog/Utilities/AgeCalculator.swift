import Foundation

struct AgeComponents: Equatable, Sendable {
    let years: Int
    let months: Int
}

enum AgeCalculator {
    /// Whole years and remaining whole months between a birthday and a
    /// reference date (defaults to now), using the given calendar.
    static func age(
        from birthday: Date,
        to referenceDate: Date = .now,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> AgeComponents {
        let components = calendar.dateComponents([.year, .month], from: birthday, to: referenceDate)
        return AgeComponents(years: max(0, components.year ?? 0), months: max(0, components.month ?? 0))
    }
}
