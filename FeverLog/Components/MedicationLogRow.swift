import SwiftUI

struct MedicationLogRow: View {
    @Environment(\.feverPalette) private var palette

    let log: MedicationLog

    var body: some View {
        HStack(spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: CornerRadiusToken.sm, style: .continuous)
                .fill(accentColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(log.brandSnapshot)
                    .font(Typography.body.weight(.semibold))
                if let milligrams = log.calculatedMilligrams {
                    Text(String(format: "%.1f mg", milligrams))
                        .font(Typography.caption)
                        .foregroundStyle(palette.secondaryText)
                }
                Text(log.administeredAt, style: .time)
                    .font(Typography.caption)
                    .foregroundStyle(palette.secondaryText)
            }
            Spacer()
        }
        .padding(Spacing.sm)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadiusToken.md, style: .continuous))
    }

    private var accentColor: Color {
        switch log.calculationStatus {
        case .calculated: palette.success
        case .missingWeight, .missingRule: palette.warning
        case .invalidInput: palette.danger
        }
    }
}
