import Foundation
import SwiftData

/// A deterministic, non-diagnostic summary of a child's recent temperature
/// history. Every field is reproducible from the same local records and
/// `FeverInsightsConfiguration` version — nothing here is inferred,
/// predicted, or fetched from a network service.
struct ChildFeverInsightsSummary: Equatable, Sendable {
    let hasAnyReadings: Bool
    let spikeCount: Int
    let totalFeverDuration: TimeInterval
    /// `nil` means insufficient data (fewer than two fever episodes in the
    /// window), not zero.
    let longestFeverFreeInterval: TimeInterval?
    /// `nil` means insufficient data (no reading old enough to compare
    /// against), not "no change".
    let temperatureChangeOverFourHours: Double?
}

@MainActor
protocol ChildFeverInsightsProviding {
    func summary(for child: Child, withinDays days: Int) throws -> ChildFeverInsightsSummary
}

@MainActor
final class SwiftDataChildFeverInsightsProvider: ChildFeverInsightsProviding {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func summary(for child: Child, withinDays days: Int = 30) throws -> ChildFeverInsightsSummary {
        let childID = child.id
        let cutoff = Calendar(identifier: .gregorian).date(byAdding: .day, value: -days, to: .now) ?? .now
        let predicate = #Predicate<TemperatureLog> {
            $0.childID == childID && $0.deletedAt == nil && $0.recordedAt >= cutoff
        }
        let logs = try context.fetch(FetchDescriptor<TemperatureLog>(predicate: predicate))
        let readings = logs.map { TemperatureReading(celsius: $0.temperatureCelsius, recordedAt: $0.recordedAt) }

        return ChildFeverInsightsSummary(
            hasAnyReadings: !readings.isEmpty,
            spikeCount: FeverInsights.spikeCount(from: readings),
            totalFeverDuration: FeverInsights.totalFeverDuration(from: readings),
            longestFeverFreeInterval: FeverInsights.longestFeverFreeInterval(from: readings),
            temperatureChangeOverFourHours: FeverInsights.temperatureChange(readings: readings, overInterval: 4 * 3600)
        )
    }
}
