import Charts
import SwiftUI

/// Bar chart of how often each quick-log type (food/drink/pee/poop/vomit/
/// breath) was logged within the selected range. Types with zero
/// occurrences are omitted rather than shown as empty bars.
struct QuickLogFrequencyChartView: View {
    @Environment(\.feverPalette) private var palette

    let frequencies: [QuickLogFrequency]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: L10n.Charts.quickLogTitle)
            if frequencies.isEmpty {
                Text(L10n.Charts.quickLogEmpty)
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
                x: .value("Type", frequency.type.localizedLabel),
                y: .value("Count", frequency.count)
            )
            .foregroundStyle(palette.accentPeach)
            .accessibilityLabel(Text(accessibilityLabel(for: frequency)))
        }
        .frame(height: 200)
    }

    private func accessibilityLabel(for frequency: QuickLogFrequency) -> String {
        "\(frequency.type.localizedLabel): \(L10n.Charts.quickLogBarAccessibility) \(frequency.count)"
    }
}
