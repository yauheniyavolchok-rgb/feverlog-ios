import Charts
import SwiftUI

/// Bar chart of how often each symptom category was logged within the
/// selected range. Categories with zero occurrences are omitted rather than
/// shown as empty bars.
struct SymptomFrequencyChartView: View {
    @Environment(\.feverPalette) private var palette

    let frequencies: [SymptomFrequency]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: L10n.Charts.symptomsTitle)
            if frequencies.isEmpty {
                Text(L10n.Charts.symptomsEmpty)
                    .font(Typography.body)
                    .foregroundStyle(palette.secondaryText)
            } else {
                chart
            }
        }
    }

    private var chart: some View {
        Chart(frequencies) { frequency in
            BarMark(
                x: .value("Category", frequency.category.localizedLabel),
                y: .value("Count", frequency.count)
            )
            .foregroundStyle(palette.accentLavender)
            .accessibilityLabel(Text(accessibilityLabel(for: frequency)))
        }
        .frame(height: 200)
    }

    private func accessibilityLabel(for frequency: SymptomFrequency) -> String {
        "\(frequency.category.localizedLabel): \(L10n.Charts.symptomsBarAccessibility) \(frequency.count)"
    }
}
