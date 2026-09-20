import Foundation
import Testing
@testable import FeverLog

@Suite("AgeCalculator")
struct AgeCalculatorTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(year: Int, month: Int, day: Int) throws -> Date {
        try #require(DateComponents(calendar: calendar, year: year, month: month, day: day).date)
    }

    @Test("computes whole years and months between two dates")
    func computesYearsAndMonths() throws {
        let birthday = try date(year: 2024, month: 3, day: 15)
        let reference = try date(year: 2026, month: 5, day: 20)

        let age = AgeCalculator.age(from: birthday, to: reference, calendar: calendar)

        #expect(age.years == 2)
        #expect(age.months == 2)
    }

    @Test("newborn is 0 years 0 months on the birthday itself")
    func newbornIsZero() throws {
        let birthday = try date(year: 2026, month: 1, day: 1)

        let age = AgeCalculator.age(from: birthday, to: birthday, calendar: calendar)

        #expect(age.years == 0)
        #expect(age.months == 0)
    }

    @Test("just under a full month rounds down to 0 months")
    func justUnderAMonthRoundsDown() throws {
        let birthday = try date(year: 2026, month: 1, day: 15)
        let reference = try date(year: 2026, month: 2, day: 10)

        let age = AgeCalculator.age(from: birthday, to: reference, calendar: calendar)

        #expect(age.years == 0)
        #expect(age.months == 0)
    }
}
