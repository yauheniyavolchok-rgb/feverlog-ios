import Foundation
import Testing
@testable import FeverLog

@Suite("ChartDataAggregator")
struct ChartDataAggregatorTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Temperature date-range filtering

    @Test("excludes readings outside the selected range")
    func excludesReadingsOutsideRange() {
        let readings = [
            TemperatureReading(celsius: 37.0, recordedAt: now),
            TemperatureReading(celsius: 38.0, recordedAt: now.addingTimeInterval(-48 * 3600))
        ]
        let result = ChartDataAggregator.temperatureReadings(readings, in: .hours24, referenceDate: now)
        #expect(result.count == 1)
        #expect(result.first?.celsius == 37.0)
    }

    @Test("includes readings exactly at the range boundary")
    func includesBoundaryReadings() {
        let readings = [
            TemperatureReading(celsius: 36.5, recordedAt: now.addingTimeInterval(-24 * 3600)),
            TemperatureReading(celsius: 37.0, recordedAt: now)
        ]
        let result = ChartDataAggregator.temperatureReadings(readings, in: .hours24, referenceDate: now)
        #expect(result.count == 2)
    }

    @Test("sorts filtered readings chronologically")
    func sortsChronologically() {
        let readings = [
            TemperatureReading(celsius: 38.0, recordedAt: now),
            TemperatureReading(celsius: 37.0, recordedAt: now.addingTimeInterval(-3600))
        ]
        let result = ChartDataAggregator.temperatureReadings(readings, in: .hours24, referenceDate: now)
        #expect(result.map(\.celsius) == [37.0, 38.0])
    }

    @Test("a wider range includes readings a narrower range excludes")
    func widerRangeIncludesMore() {
        let readings = [TemperatureReading(celsius: 37.0, recordedAt: now.addingTimeInterval(-5 * 24 * 3600))]
        #expect(ChartDataAggregator.temperatureReadings(readings, in: .hours24, referenceDate: now).isEmpty)
        #expect(ChartDataAggregator.temperatureReadings(readings, in: .days7, referenceDate: now).count == 1)
    }

    @Test("sparse data — a single reading passes through untouched")
    func sparseDataSingleReading() {
        let readings = [TemperatureReading(celsius: 37.2, recordedAt: now)]
        let result = ChartDataAggregator.temperatureReadings(readings, in: .days14, referenceDate: now)
        #expect(result == readings)
    }

    @Test("empty temperature data produces an empty result without crashing")
    func emptyTemperatureData() {
        #expect(ChartDataAggregator.temperatureReadings([], in: .days14, referenceDate: now).isEmpty)
    }

    // MARK: - Medication event filtering

    @Test("filters and sorts medication events within range")
    func filtersMedicationEvents() {
        let events = [
            MedicationEvent(id: UUID(), administeredAt: now, medicationName: "Paracetamol"),
            MedicationEvent(id: UUID(), administeredAt: now.addingTimeInterval(-3600), medicationName: "Ibuprofen"),
            MedicationEvent(id: UUID(), administeredAt: now.addingTimeInterval(-30 * 24 * 3600), medicationName: "Old dose")
        ]
        let result = ChartDataAggregator.medicationEvents(events, in: .days7, referenceDate: now)
        #expect(result.map(\.medicationName) == ["Ibuprofen", "Paracetamol"])
    }

    @Test("empty medication data produces an empty result without crashing")
    func emptyMedicationData() {
        #expect(ChartDataAggregator.medicationEvents([], in: .hours24, referenceDate: now).isEmpty)
    }

    // MARK: - Symptom frequency aggregation

    @Test("counts observations per category and omits zero-count categories")
    func countsPerCategory() {
        let observations = [
            SymptomObservation(category: .breathing, recordedAt: now),
            SymptomObservation(category: .breathing, recordedAt: now.addingTimeInterval(-3600)),
            SymptomObservation(category: .pain, recordedAt: now)
        ]
        let result = ChartDataAggregator.symptomFrequency(observations, in: .days3, referenceDate: now)
        let byCategory = Dictionary(uniqueKeysWithValues: result.map { ($0.category, $0.count) })
        #expect(byCategory[.breathing] == 2)
        #expect(byCategory[.pain] == 1)
        #expect(byCategory[.sleep] == nil)
    }

    @Test("symptom frequency result is ordered by category declaration order")
    func orderedByDeclarationOrder() {
        let observations = [
            SymptomObservation(category: .general, recordedAt: now),
            SymptomObservation(category: .breathing, recordedAt: now)
        ]
        let result = ChartDataAggregator.symptomFrequency(observations, in: .days3, referenceDate: now)
        #expect(result.map(\.category) == [.breathing, .general])
    }

    @Test("observations outside the range are excluded from frequency counts")
    func excludesOldObservationsFromFrequency() {
        let observations = [SymptomObservation(category: .pain, recordedAt: now.addingTimeInterval(-30 * 24 * 3600))]
        #expect(ChartDataAggregator.symptomFrequency(observations, in: .days14, referenceDate: now).isEmpty)
    }

    @Test("empty symptom data produces an empty result without crashing")
    func emptySymptomData() {
        #expect(ChartDataAggregator.symptomFrequency([], in: .hours24, referenceDate: now).isEmpty)
    }
}
