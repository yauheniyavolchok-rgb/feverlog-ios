import SwiftUI

struct SymptomEntryRow: View {
    @Environment(\.feverPalette) private var palette

    let entry: SymptomEntry
    var owner: Child?

    private var categories: [SymptomCategory] {
        entry.symptomIdentifiers.compactMap { SymptomCategory(rawValue: $0) }
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: CornerRadiusToken.sm, style: .continuous)
                .fill(palette.accentLavender)
                .frame(width: 4)

            if let owner {
                Image(systemName: ChildAvatarOption(rawValue: owner.avatarIdentifier)?.rawValue ?? "star.fill")
                    .foregroundStyle((ChildAvatarColorOption(rawValue: owner.avatarColorIdentifier) ?? .mint).color(in: palette))
                    .frame(width: Spacing.lg, height: Spacing.lg)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "list.bullet.clipboard.fill")
                        .foregroundStyle(palette.accentLavender)
                    Text(categories.map(\.localizedLabel).joined(separator: ", "))
                        .font(Typography.body.weight(.semibold))
                }
                Text(entry.recordedAt, style: .time)
                    .font(Typography.caption)
                    .foregroundStyle(palette.secondaryText)
            }
            Spacer()
        }
        .padding(Spacing.sm)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadiusToken.md, style: .continuous))
    }
}
