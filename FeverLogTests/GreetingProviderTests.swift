import Foundation
import Testing
@testable import FeverLog

@Suite("GreetingProvider")
struct GreetingProviderTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(hour: Int) throws -> Date {
        try #require(DateComponents(calendar: calendar, year: 2026, month: 6, day: 1, hour: hour).date)
    }

    @Test(
        "maps hour of day to the expected greeting",
        arguments: [
            (5, Greeting.morning),
            (11, Greeting.morning),
            (12, Greeting.afternoon),
            (16, Greeting.afternoon),
            (17, Greeting.evening),
            (23, Greeting.evening),
            (2, Greeting.evening)
        ]
    )
    func mapsHourToGreeting(hour: Int, expected: Greeting) throws {
        let greeting = GreetingProvider.greeting(for: try date(hour: hour), calendar: calendar)
        #expect(greeting == expected)
    }
}
