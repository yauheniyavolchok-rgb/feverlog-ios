import SwiftUI

struct TemperatureHeroCard: View {
    @Environment(\.feverPalette) private var palette

    /// `nil` when the child has no temperature readings yet.
    let latestLog: TemperatureLog?

    var body: some View {
        Card {
            VStack(spacing: Spacing.xs) {
                if let latestLog {
                    let status = TemperatureClassifier.classify(celsius: latestLog.temperatureCelsius)
                    Text(String(format: "%.1f°C", latestLog.temperatureCelsius))
                        .font(Typography.largeTemperature)
                        .foregroundStyle(palette.color(for: status))
                    Text(statusLabel(for: status))
                        .font(Typography.caption)
                        .foregroundStyle(palette.secondaryText)
                    Text(latestLog.recordedAt, style: .relative)
                        .font(Typography.caption)
                        .foregroundStyle(palette.secondaryText)
                } else {
                    Text(L10n.Home.noReadingsYet)
                        .font(Typography.body)
                        .foregroundStyle(palette.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
    }

    private func statusLabel(for status: TemperatureStatus) -> String {
        switch status {
        case .normal: L10n.TemperatureStatusText.normal
        case .elevated: L10n.TemperatureStatusText.elevated
        case .high: L10n.TemperatureStatusText.high
        case .veryHigh: L10n.TemperatureStatusText.veryHigh
        case .critical: L10n.TemperatureStatusText.critical
        }
    }
}

#Preview {
    TemperatureHeroCard(latestLog: nil)
        .padding()
        .feverThemed()
}
