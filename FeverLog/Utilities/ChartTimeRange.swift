import Foundation

/// The selectable lookback windows for the Charts screen. Each range ends at
/// "now" and looks backward — there is no forward-looking window.
enum ChartTimeRange: String, CaseIterable, Identifiable, Sendable {
    case hours24
    case days3
    case days7
    case days14

    var id: String { rawValue }

    var durationSeconds: TimeInterval {
        switch self {
        case .hours24: 24 * 3600
        case .days3: 3 * 24 * 3600
        case .days7: 7 * 24 * 3600
        case .days14: 14 * 24 * 3600
        }
    }

    /// Start and end bounds for this range, inclusive on both ends.
    func bounds(endingAt referenceDate: Date = .now) -> (start: Date, end: Date) {
        (referenceDate.addingTimeInterval(-durationSeconds), referenceDate)
    }

    var localizedLabel: String {
        switch self {
        case .hours24: L10n.Charts.range24h
        case .days3: L10n.Charts.range3d
        case .days7: L10n.Charts.range7d
        case .days14: L10n.Charts.range14d
        }
    }
}
