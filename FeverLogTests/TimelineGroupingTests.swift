import Foundation
import Testing
@testable import FeverLog

private struct Entry {
    let recordedAt: Date
}

@Suite("TimelineGrouping")
struct TimelineGroupingTests {
    private let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    private func date(_ iso: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return try #require(formatter.date(from: iso))
    }

    @Test("groups items into separate days, newest day first")
    func groupsIntoSeparateDaysNewestFirst() throws {
        let entries = [
            Entry(recordedAt: try date("2026-01-01T10:00:00Z")),
            Entry(recordedAt: try date("2026-01-02T09:00:00Z")),
            Entry(recordedAt: try date("2026-01-02T15:00:00Z"))
        ]

        let groups = TimelineGrouping.groupByDay(entries, date: \.recordedAt, calendar: utcCalendar)

        #expect(groups.count == 2)
        #expect(groups[0].items.count == 2)
        #expect(groups[1].items.count == 1)
        // Newest item first within a day.
        #expect(groups[0].items[0].recordedAt > groups[0].items[1].recordedAt)
    }

    @Test("a timestamp just before local midnight UTC groups into the earlier day")
    func timezoneBoundaryUTC() throws {
        let entries = [
            Entry(recordedAt: try date("2026-01-01T23:59:00Z")),
            Entry(recordedAt: try date("2026-01-02T00:01:00Z"))
        ]

        let groups = TimelineGrouping.groupByDay(entries, date: \.recordedAt, calendar: utcCalendar)

        #expect(groups.count == 2)
    }

    @Test("day grouping uses the given calendar's timezone, not UTC")
    func usesGivenTimezoneNotUTC() throws {
        // 23:30 UTC on Jan 1 is 00:30 the next day in a UTC+2 zone.
        var plusTwoCalendar = Calendar(identifier: .gregorian)
        plusTwoCalendar.timeZone = try #require(TimeZone(identifier: "Europe/Kyiv"))

        let entries = [Entry(recordedAt: try date("2026-01-01T23:30:00Z"))]

        let utcGroups = TimelineGrouping.groupByDay(entries, date: \.recordedAt, calendar: utcCalendar)
        let plusTwoGroups = TimelineGrouping.groupByDay(entries, date: \.recordedAt, calendar: plusTwoCalendar)

        #expect(Calendar(identifier: .gregorian).component(.day, from: utcGroups[0].day) == 1)
        #expect(plusTwoCalendar.component(.day, from: plusTwoGroups[0].day) == 2)
    }
}
