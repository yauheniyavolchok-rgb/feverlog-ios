import SwiftUI

struct TemperatureLogRow: View {
    @Environment(\.feverPalette) private var palette

    let log: TemperatureLog
    /// When set (e.g. in a household-wide timeline), shows the owning
    /// child's avatar so entries from multiple kids stay distinguishable.
    var owner: Child?

    private var status: TemperatureStatus {
        TemperatureClassifier.classify(celsius: log.temperatureCelsius)
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: CornerRadiusToken.sm, style: .continuous)
                .fill(palette.color(for: status))
                .frame(width: 4)

            if let owner {
                Image(systemName: ChildAvatarOption(rawValue: owner.avatarIdentifier)?.rawValue ?? "star.fill")
                    .foregroundStyle((ChildAvatarColorOption(rawValue: owner.avatarColorIdentifier) ?? .mint).color(in: palette))
                    .frame(width: Spacing.lg, height: Spacing.lg)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Text(String(format: "%.1f°C", log.temperatureCelsius))
                        .font(Typography.body.weight(.semibold))
                    Text(statusLabel)
                        .font(Typography.caption)
                        .foregroundStyle(palette.secondaryText)
                }
                Text(log.recordedAt, style: .time)
                    .font(Typography.caption)
                    .foregroundStyle(palette.secondaryText)
                if let note = log.note, !note.isEmpty {
                    Text(note)
                        .font(Typography.caption)
                        .foregroundStyle(palette.secondaryText)
                }
            }
            Spacer()
        }
        .padding(Spacing.sm)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadiusToken.md, style: .continuous))
    }

    private var statusLabel: String {
        switch status {
        case .normal: L10n.TemperatureStatusText.normal
        case .elevated: L10n.TemperatureStatusText.elevated
        case .high: L10n.TemperatureStatusText.high
        case .veryHigh: L10n.TemperatureStatusText.veryHigh
        case .critical: L10n.TemperatureStatusText.critical
        }
    }
}
