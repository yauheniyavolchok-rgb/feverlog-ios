import Foundation

struct TimelineDayGroup<Item>: Identifiable {
    let day: Date
    let items: [Item]

    var id: Date { day }
}

enum TimelineGrouping {
    /// Groups items by calendar day (newest day first, newest item first
    /// within a day) using the given calendar — which reflects the current
    /// display timezone. Event timestamps remain absolute instants; only
    /// grouping/display uses the current calendar and timezone.
    static func groupByDay<Item>(
        _ items: [Item],
        date: (Item) -> Date,
        calendar: Calendar = .current
    ) -> [TimelineDayGroup<Item>] {
        let grouped = Dictionary(grouping: items) { calendar.startOfDay(for: date($0)) }
        return grouped.keys
            .sorted(by: >)
            .map { day in
                let dayItems = (grouped[day] ?? []).sorted { date($0) > date($1) }
                return TimelineDayGroup(day: day, items: dayItems)
            }
    }
}
