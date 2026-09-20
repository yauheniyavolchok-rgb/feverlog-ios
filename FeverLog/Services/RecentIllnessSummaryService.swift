import Foundation
import SwiftData

/// A deterministic, non-diagnostic summary of recent temperature readings.
/// This never interprets, diagnoses, or predicts — it only counts locally
/// stored records that a presentation-layer classifier already flagged as
/// above the "normal" display threshold.
enum RecentIllnessSummary: Equatable, Sendable {
    case noRecentReadings
    case elevatedReadings(count: Int, sinceDays: Int)
}

@MainActor
protocol RecentIllnessSummaryProviding {
    func summary(for child: Child, withinDays days: Int) throws -> RecentIllnessSummary
}

@MainActor
final class SwiftDataRecentIllnessSummaryProvider: RecentIllnessSummaryProviding {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func summary(for child: Child, withinDays days: Int = 7) throws -> RecentIllnessSummary {
        let childID = child.id
        let cutoff = Calendar(identifier: .gregorian).date(byAdding: .day, value: -days, to: .now) ?? .now
        let predicate = #Predicate<TemperatureLog> {
            $0.childID == childID && $0.deletedAt == nil && $0.recordedAt >= cutoff
        }
        let logs = try context.fetch(FetchDescriptor<TemperatureLog>(predicate: predicate))
        let elevatedCount = logs.filter { TemperatureClassifier.classify(celsius: $0.temperatureCelsius) != .normal }.count

        guard elevatedCount > 0 else { return .noRecentReadings }
        return .elevatedReadings(count: elevatedCount, sinceDays: days)
    }
}
