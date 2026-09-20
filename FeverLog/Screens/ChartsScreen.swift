import SwiftUI

struct ChartsScreen: View {
    @Environment(ChildStore.self) private var childStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    @State private var range: ChartTimeRange = .hours24
    @State private var readings: [TemperatureReading] = []
    @State private var medicationEvents: [MedicationEvent] = []
    @State private var symptomObservations: [SymptomObservation] = []

    private var filteredReadings: [TemperatureReading] {
        ChartDataAggregator.temperatureReadings(readings, in: range)
    }

    private var filteredMedicationEvents: [MedicationEvent] {
        ChartDataAggregator.medicationEvents(medicationEvents, in: range)
    }

    private var symptomFrequencies: [SymptomFrequency] {
        ChartDataAggregator.symptomFrequency(symptomObservations, in: range)
    }

    var body: some View {
        Group {
            if childStore.children.isEmpty {
                PlaceholderScreen(
                    systemImage: Icon.charts,
                    title: L10n.Charts.noChildTitle,
                    message: L10n.Charts.noChildMessage
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        rangePicker
                        TemperatureChartView(readings: filteredReadings, medicationEvents: filteredMedicationEvents)
                        MedicationTimelineChartView(events: filteredMedicationEvents)
                        SymptomFrequencyChartView(frequencies: symptomFrequencies)
                    }
                    .padding(Spacing.md)
                }
                .background(palette.background)
            }
        }
        .onAppear { OrientationManager.allowsLandscape = true }
        .onDisappear { OrientationManager.allowsLandscape = false }
        .task(id: childStore.selectedChildID) { await reload() }
    }

    private var rangePicker: some View {
        Picker(L10n.Charts.rangeLabel, selection: $range) {
            ForEach(ChartTimeRange.allCases) { range in
                Text(range.localizedLabel).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("charts.rangeMode")
    }

    private func reload() async {
        guard let child = childStore.selectedChild else {
            readings = []
            medicationEvents = []
            symptomObservations = []
            return
        }

        let temperatureLogs = (try? SwiftDataTemperatureLogRepository(context: modelContext).fetchAll(for: child)) ?? []
        readings = temperatureLogs.map { TemperatureReading(celsius: $0.temperatureCelsius, recordedAt: $0.recordedAt) }

        let medicationLogs = (try? SwiftDataMedicationLogRepository(context: modelContext).fetchAll(for: child)) ?? []
        medicationEvents = medicationLogs.map {
            MedicationEvent(id: $0.id, administeredAt: $0.administeredAt, medicationName: $0.brandSnapshot)
        }

        let symptomEntries = (try? SwiftDataSymptomEntryRepository(context: modelContext).fetchAll(for: child)) ?? []
        symptomObservations = symptomEntries.flatMap { entry in
            entry.symptomIdentifiers.compactMap { identifier in
                SymptomCategory(rawValue: identifier).map { SymptomObservation(category: $0, recordedAt: entry.recordedAt) }
            }
        }
    }
}

#Preview {
    NavigationStack { ChartsScreen() }
        .feverThemed()
}
