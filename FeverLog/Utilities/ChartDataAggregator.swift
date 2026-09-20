import Foundation

/// A single medication administration event, decoupled from SwiftData so
/// the aggregator below stays pure and independently testable — mirrors
/// `TemperatureReading` in `FeverInsights.swift`.
struct MedicationEvent: Equatable, Sendable, Identifiable {
    let id: UUID
    let administeredAt: Date
    let medicationName: String
}

/// A single symptom-category observation, one per selected category per
/// logged entry (an entry with three categories contributes three of these).
struct SymptomObservation: Equatable, Sendable {
    let category: SymptomCategory
    let recordedAt: Date
}

struct SymptomFrequency: Equatable, Sendable, Identifiable {
    var id: SymptomCategory { category }
    let category: SymptomCategory
    let count: Int
}

/// Deterministic, local-only chart data preparation. No AI, no machine
/// learning, no external services — every result is reproducible from the
/// same records and time range. Filtering bounds are inclusive on both ends.
enum ChartDataAggregator {
    static func temperatureReadings(
        _ readings: [TemperatureReading],
        in range: ChartTimeRange,
        referenceDate: Date = .now
    ) -> [TemperatureReading] {
        let bounds = range.bounds(endingAt: referenceDate)
        return readings
            .filter { $0.recordedAt >= bounds.start && $0.recordedAt <= bounds.end }
            .sorted { $0.recordedAt < $1.recordedAt }
    }

    static func medicationEvents(
        _ events: [MedicationEvent],
        in range: ChartTimeRange,
        referenceDate: Date = .now
    ) -> [MedicationEvent] {
        let bounds = range.bounds(endingAt: referenceDate)
        return events
            .filter { $0.administeredAt >= bounds.start && $0.administeredAt <= bounds.end }
            .sorted { $0.administeredAt < $1.administeredAt }
    }

    /// Counts observations per category within the range, omitting
    /// categories with zero occurrences. Order follows `SymptomCategory`'s
    /// declaration order for a stable, deterministic chart axis.
    static func symptomFrequency(
        _ observations: [SymptomObservation],
        in range: ChartTimeRange,
        referenceDate: Date = .now
    ) -> [SymptomFrequency] {
        let bounds = range.bounds(endingAt: referenceDate)
        let filtered = observations.filter { $0.recordedAt >= bounds.start && $0.recordedAt <= bounds.end }
        var counts: [SymptomCategory: Int] = [:]
        for observation in filtered {
            counts[observation.category, default: 0] += 1
        }
        return SymptomCategory.allCases.compactMap { category in
            guard let count = counts[category], count > 0 else { return nil }
            return SymptomFrequency(category: category, count: count)
        }
    }
}
