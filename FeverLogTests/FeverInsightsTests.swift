import Foundation
import Testing
@testable import FeverLog

@Suite("FeverInsights")
struct FeverInsightsTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func reading(_ celsius: Double, at date: Date) -> TemperatureReading {
        TemperatureReading(celsius: celsius, recordedAt: date)
    }

    // MARK: - Episodes / spike count

    @Test("readings below the fever threshold produce no episodes")
    func belowThresholdProducesNoEpisodes() {
        let readings = [reading(37.0, at: now), reading(37.4, at: now.addingTimeInterval(3600))]
        #expect(FeverInsights.episodes(from: readings).isEmpty)
        #expect(FeverInsights.spikeCount(from: readings) == 0)
    }

    @Test("readings within the episode gap merge into a single spike")
    func readingsWithinGapMergeIntoOneEpisode() {
        let readings = [
            reading(38.5, at: now),
            reading(38.8, at: now.addingTimeInterval(3600)),
            reading(38.2, at: now.addingTimeInterval(2 * 3600))
        ]
        #expect(FeverInsights.spikeCount(from: readings) == 1)
        let episode = FeverInsights.episodes(from: readings).first
        #expect(episode?.peakCelsius == 38.8)
    }

    @Test("readings beyond the episode gap count as separate spikes")
    func readingsBeyondGapAreSeparateEpisodes() {
        let readings = [
            reading(38.5, at: now),
            reading(38.5, at: now.addingTimeInterval(5 * 3600)) // beyond the 4h default gap
        ]
        #expect(FeverInsights.spikeCount(from: readings) == 2)
    }

    @Test("a reading exactly at the episode gap boundary still merges (inclusive)")
    func exactGapBoundaryMerges() {
        let readings = [
            reading(38.5, at: now),
            reading(38.5, at: now.addingTimeInterval(FeverInsightsConfiguration.v1.episodeGapSeconds))
        ]
        #expect(FeverInsights.spikeCount(from: readings) == 1)
    }

    @Test("normal readings interleaved with fever readings don't break episode grouping")
    func normalReadingsAreIgnoredForGrouping() {
        let readings = [
            reading(38.5, at: now),
            reading(36.8, at: now.addingTimeInterval(3600)), // normal, ignored
            reading(38.6, at: now.addingTimeInterval(2 * 3600))
        ]
        #expect(FeverInsights.spikeCount(from: readings) == 1)
    }

    @Test("no readings at all produces no episodes")
    func noReadingsProducesNoEpisodes() {
        #expect(FeverInsights.episodes(from: []).isEmpty)
        #expect(FeverInsights.spikeCount(from: []) == 0)
    }

    // MARK: - Duration

    @Test("total fever duration sums each episode's span")
    func totalDurationSumsEpisodeSpans() {
        let readings = [
            reading(38.5, at: now),
            reading(38.5, at: now.addingTimeInterval(2 * 3600)), // same episode, 2h span
            reading(38.5, at: now.addingTimeInterval(10 * 3600)), // new episode (>4h gap)
            reading(38.5, at: now.addingTimeInterval(11 * 3600)) // same as above, 1h span
        ]
        #expect(FeverInsights.totalFeverDuration(from: readings) == 3 * 3600)
    }

    @Test("a single-reading episode contributes zero duration")
    func singleReadingEpisodeHasZeroDuration() {
        let readings = [reading(38.5, at: now)]
        #expect(FeverInsights.totalFeverDuration(from: readings) == 0)
    }

    // MARK: - Fever-free interval

    @Test("fewer than two episodes yields insufficient data (nil)")
    func fewerThanTwoEpisodesYieldsNil() {
        #expect(FeverInsights.longestFeverFreeInterval(from: []) == nil)
        #expect(FeverInsights.longestFeverFreeInterval(from: [reading(38.5, at: now)]) == nil)
    }

    @Test("longest fever-free interval is the largest gap between episodes")
    func longestGapBetweenEpisodes() {
        let readings = [
            reading(38.5, at: now),
            reading(38.5, at: now.addingTimeInterval(10 * 3600)), // gap of 10h
            reading(38.5, at: now.addingTimeInterval(30 * 3600)) // gap of 20h
        ]
        let longest = FeverInsights.longestFeverFreeInterval(from: readings)
        let expected: TimeInterval = 20 * 3600
        #expect(longest == expected)
    }

    // MARK: - Temperature change over an interval

    @Test("temperature change compares the nearest readings on each side of the interval")
    func temperatureChangeComparesNearestReadings() {
        let readings = [
            reading(37.0, at: now.addingTimeInterval(-4 * 3600)),
            reading(38.5, at: now)
        ]
        let change = FeverInsights.temperatureChange(readings: readings, overInterval: 4 * 3600, referenceDate: now)
        #expect(change == 1.5)
    }

    @Test("temperature change is nil when there's no reading old enough to compare")
    func temperatureChangeNilWithoutOlderReading() {
        let readings = [reading(38.5, at: now)]
        let change = FeverInsights.temperatureChange(readings: readings, overInterval: 4 * 3600, referenceDate: now)
        #expect(change == nil)
    }

    @Test("temperature change is nil with no readings at all")
    func temperatureChangeNilWithNoReadings() {
        let change = FeverInsights.temperatureChange(readings: [], overInterval: 4 * 3600, referenceDate: now)
        #expect(change == nil)
    }

    // MARK: - Determinism / configuration versioning

    @Test("the same readings and configuration always produce the same result")
    func isDeterministic() {
        let readings = [reading(38.5, at: now), reading(39.0, at: now.addingTimeInterval(3600))]
        let first = FeverInsights.episodes(from: readings)
        let second = FeverInsights.episodes(from: readings)
        #expect(first == second)
    }

    @Test("a different configuration version can change the episode grouping")
    func differentConfigurationChangesGrouping() {
        let readings = [
            reading(38.5, at: now),
            reading(38.5, at: now.addingTimeInterval(5 * 3600))
        ]
        let tightConfig = FeverInsightsConfiguration(version: 2, feverThresholdCelsius: 38.1, episodeGapSeconds: 3600)
        let wideConfig = FeverInsightsConfiguration(version: 3, feverThresholdCelsius: 38.1, episodeGapSeconds: 6 * 3600)

        #expect(FeverInsights.spikeCount(from: readings, configuration: tightConfig) == 2)
        #expect(FeverInsights.spikeCount(from: readings, configuration: wideConfig) == 1)
    }

    // MARK: - Timezone / DST independence

    @Test("episode grouping uses absolute elapsed time, independent of calendar/timezone")
    func isTimezoneIndependent() {
        // These two instants are ~4 hours apart in absolute time regardless
        // of which calendar day or timezone they're interpreted in.
        let readings = [
            reading(38.5, at: Date(timeIntervalSince1970: 1_700_000_000)),
            reading(38.5, at: Date(timeIntervalSince1970: 1_700_000_000 + 3 * 3600))
        ]
        #expect(FeverInsights.spikeCount(from: readings) == 1)
    }
}
