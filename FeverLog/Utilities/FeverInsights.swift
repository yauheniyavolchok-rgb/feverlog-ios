import Foundation

/// A single temperature observation, decoupled from SwiftData so the
/// calculator below stays pure and independently testable.
struct TemperatureReading: Equatable, Sendable {
    let celsius: Double
    let recordedAt: Date
}

/// Explicit, versioned configuration for fever-insight interpretation.
/// Changing these numbers changes what past insights mean, so the version
/// number must bump whenever they do.
///
/// TODO(Phase 7, fever-spike threshold): Define the exact fever-spike threshold
/// and episode-gap window with product and medical review.
/// Completion: the threshold, configuration version, and nonclinical copy are
/// documented and tested.
/// Release blocker: yes if fever-spike insights are exposed.
struct FeverInsightsConfiguration: Sendable {
    let version: Int
    /// A reading at or above this value counts toward a fever episode. This
    /// intentionally reuses `TemperatureClassifier`'s "high" boundary as a
    /// starting point — it is a display/insight threshold, never a
    /// medication safety threshold.
    let feverThresholdCelsius: Double
    /// Readings this close together (or closer) are treated as the same
    /// ongoing episode rather than two separate spikes.
    let episodeGapSeconds: TimeInterval

    static let v1 = FeverInsightsConfiguration(version: 1, feverThresholdCelsius: 38.1, episodeGapSeconds: 4 * 3600)
}

struct FeverEpisode: Equatable, Sendable {
    let start: Date
    let end: Date
    let peakCelsius: Double
}

/// Deterministic, local-only temperature history analysis. No AI, no
/// machine learning, no external services — every result is reproducible
/// from the same readings and configuration version. None of this is a
/// diagnosis; it only describes what was already recorded.
enum FeverInsights {
    /// Groups fever-range readings into episodes, merging readings that are
    /// within `episodeGapSeconds` of the previous one in the same episode.
    static func episodes(
        from readings: [TemperatureReading],
        configuration: FeverInsightsConfiguration = .v1
    ) -> [FeverEpisode] {
        let feverReadings = readings
            .filter { $0.celsius >= configuration.feverThresholdCelsius }
            .sorted { $0.recordedAt < $1.recordedAt }
        guard let first = feverReadings.first else { return [] }

        var result: [FeverEpisode] = []
        var currentStart = first.recordedAt
        var currentEnd = first.recordedAt
        var currentPeak = first.celsius

        for reading in feverReadings.dropFirst() {
            if reading.recordedAt.timeIntervalSince(currentEnd) <= configuration.episodeGapSeconds {
                currentEnd = reading.recordedAt
                currentPeak = max(currentPeak, reading.celsius)
            } else {
                result.append(FeverEpisode(start: currentStart, end: currentEnd, peakCelsius: currentPeak))
                currentStart = reading.recordedAt
                currentEnd = reading.recordedAt
                currentPeak = reading.celsius
            }
        }
        result.append(FeverEpisode(start: currentStart, end: currentEnd, peakCelsius: currentPeak))
        return result
    }

    static func spikeCount(from readings: [TemperatureReading], configuration: FeverInsightsConfiguration = .v1) -> Int {
        episodes(from: readings, configuration: configuration).count
    }

    /// Sum of each episode's span (last reading minus first reading in that
    /// episode). A fever represented by a single reading contributes zero
    /// duration — there is no second reading to bound an end. This is an
    /// inherent limitation of discrete, parent-entered readings rather than
    /// continuous monitoring, and should be reflected in how this value is
    /// presented (e.g. "at least" phrasing), not hidden.
    static func totalFeverDuration(
        from readings: [TemperatureReading],
        configuration: FeverInsightsConfiguration = .v1
    ) -> TimeInterval {
        episodes(from: readings, configuration: configuration).reduce(0) { $0 + $1.end.timeIntervalSince($1.start) }
    }

    /// The longest fully-observed fever-free span, measured strictly
    /// between the end of one episode and the start of the next. Returns
    /// `nil` when there are fewer than two episodes — a single episode (or
    /// none) never establishes a bounded fever-free interval, and callers
    /// must present that as an explicit insufficient-data state rather than
    /// a zero or missing value.
    static func longestFeverFreeInterval(
        from readings: [TemperatureReading],
        configuration: FeverInsightsConfiguration = .v1
    ) -> TimeInterval? {
        let allEpisodes = episodes(from: readings, configuration: configuration)
        guard allEpisodes.count >= 2 else { return nil }
        var longest: TimeInterval = 0
        for index in 1..<allEpisodes.count {
            let gap = allEpisodes[index].start.timeIntervalSince(allEpisodes[index - 1].end)
            longest = max(longest, gap)
        }
        return longest
    }

    /// The change in temperature between the reading nearest `referenceDate`
    /// (at or before it) and the reading nearest `referenceDate - interval`
    /// (at or before that). `nil` when there isn't a reading on each side —
    /// an explicit insufficient-data signal rather than a guess.
    static func temperatureChange(
        readings: [TemperatureReading],
        overInterval interval: TimeInterval,
        referenceDate: Date = .now
    ) -> Double? {
        let sorted = readings.sorted { $0.recordedAt < $1.recordedAt }
        guard let current = sorted.last(where: { $0.recordedAt <= referenceDate }) else { return nil }
        let targetDate = referenceDate.addingTimeInterval(-interval)
        guard let past = sorted.last(where: { $0.recordedAt <= targetDate }) else { return nil }
        return current.celsius - past.celsius
    }
}
