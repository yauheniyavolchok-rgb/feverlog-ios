import Charts
import SwiftUI

/// A swimlane-style timeline: one categorical row per medication name, with
/// a bar marking each administration time along the shared time axis.
struct MedicationTimelineChartView: View {
    @Environment(\.feverPalette) private var palette

    let events: [MedicationEvent]

    private var medicationNames: [String] {
        Array(Set(events.map(\.medicationName))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: L10n.Charts.medicationTitle)
            if events.isEmpty {
                Text(L10n.Charts.medicationEmpty)
                    .font(Typography.body)
                    .foregroundStyle(palette.secondaryText)
            } else {
                chart
            }
        }
    }

    private var chart: some View {
        Chart(events) { event in
            BarMark(
                x: .value("Time", event.administeredAt),
                y: .value("Medication", event.medicationName),
                width: .fixed(6)
            )
            .foregroundStyle(color(for: event.medicationName))
            .accessibilityLabel(Text(accessibilityLabel(for: event)))
        }
        .frame(height: max(140, CGFloat(medicationNames.count) * 44))
    }

    private func color(for medicationName: String) -> Color {
        guard let index = medicationNames.firstIndex(of: medicationName) else { return palette.chartColors[0] }
        return palette.chartColors[index % palette.chartColors.count]
    }

    private func accessibilityLabel(for event: MedicationEvent) -> String {
        let date = event.administeredAt.formatted(date: .abbreviated, time: .shortened)
        return "\(L10n.Charts.medicationBarAccessibility): \(event.medicationName), \(date)"
    }
}
