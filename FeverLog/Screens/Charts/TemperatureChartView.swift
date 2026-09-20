import Charts
import SwiftUI

/// Plots individual temperature readings as discrete points — never a
/// connected line — since readings are sparse, manually-entered
/// observations. A line would visually imply a continuous measurement
/// between two readings that could be hours apart, which the spec
/// explicitly says the chart must not do.
///
/// TODO(Phase 8, chart interpolation): Revisit this decision with
/// product/medical review if a future design wants to show a trend line.
/// Completion: interpolation behavior is documented, tested, and does not
/// imply unobserved measurements.
/// Release blocker: yes.
struct TemperatureChartView: View {
    @Environment(\.feverPalette) private var palette

    let readings: [TemperatureReading]
    let medicationEvents: [MedicationEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: L10n.Charts.temperatureTitle)
            if readings.isEmpty {
                Text(L10n.Charts.temperatureEmpty)
                    .font(Typography.body)
                    .foregroundStyle(palette.secondaryText)
            } else {
                chart
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(readings, id: \.recordedAt) { reading in
                PointMark(
                    x: .value("Time", reading.recordedAt),
                    y: .value("Temperature", reading.celsius)
                )
                .foregroundStyle(palette.color(for: TemperatureClassifier.classify(celsius: reading.celsius)))
                .symbolSize(70)
                .accessibilityLabel(Text(accessibilityLabel(for: reading)))
            }
            ForEach(medicationEvents) { event in
                RuleMark(x: .value("Medication time", event.administeredAt))
                    .foregroundStyle(palette.accentBlue.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .accessibilityLabel(Text(accessibilityLabel(for: event)))
            }
        }
        .chartYAxisLabel(L10n.Charts.temperatureAxisLabel)
        .frame(height: 220)
    }

    private func accessibilityLabel(for reading: TemperatureReading) -> String {
        let value = String(format: "%.1f", reading.celsius)
        let date = reading.recordedAt.formatted(date: .abbreviated, time: .shortened)
        return "\(L10n.Charts.temperaturePointAccessibility) \(value)°C, \(date)"
    }

    private func accessibilityLabel(for event: MedicationEvent) -> String {
        let date = event.administeredAt.formatted(date: .abbreviated, time: .shortened)
        return "\(L10n.Charts.medicationMarkerAccessibility): \(event.medicationName), \(date)"
    }
}
