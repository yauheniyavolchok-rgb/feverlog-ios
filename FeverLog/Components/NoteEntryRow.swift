import SwiftUI

struct NoteEntryRow: View {
    @Environment(\.feverPalette) private var palette

    let entry: NoteEntry
    var owner: Child?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: CornerRadiusToken.sm, style: .continuous)
                .fill(palette.accentPeach)
                .frame(width: 4)

            if let owner {
                Image(systemName: ChildAvatarOption(rawValue: owner.avatarIdentifier)?.rawValue ?? "star.fill")
                    .foregroundStyle((ChildAvatarColorOption(rawValue: owner.avatarColorIdentifier) ?? .mint).color(in: palette))
                    .frame(width: Spacing.lg, height: Spacing.lg)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "note.text")
                        .foregroundStyle(palette.accentPeach)
                    Text(entry.text)
                        .font(Typography.body.weight(.semibold))
                        .lineLimit(2)
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
