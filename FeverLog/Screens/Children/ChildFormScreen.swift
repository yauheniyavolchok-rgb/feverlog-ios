import SwiftUI

struct ChildFormScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ChildStore.self) private var childStore
    @Environment(\.feverPalette) private var palette

    /// `nil` means creating a new child; non-nil means editing an existing one.
    let existingChild: Child?

    @State private var name: String
    @State private var birthday: Date
    @State private var avatar: ChildAvatarOption
    @State private var avatarColor: ChildAvatarColorOption
    @State private var errorMessage: String?

    init(existingChild: Child? = nil) {
        self.existingChild = existingChild
        _name = State(initialValue: existingChild?.name ?? "")
        _birthday = State(initialValue: existingChild?.birthday ?? .now)
        _avatar = State(initialValue: ChildAvatarOption(rawValue: existingChild?.avatarIdentifier ?? "") ?? .star)
        _avatarColor = State(
            initialValue: ChildAvatarColorOption(rawValue: existingChild?.avatarColorIdentifier ?? "") ?? .mint
        )
    }

    var body: some View {
        Form {
            Section {
                TextField(L10n.ChildForm.nameLabel, text: $name)
                    .accessibilityIdentifier("childForm.name")
                DatePicker(L10n.ChildForm.birthdayLabel, selection: $birthday, displayedComponents: .date)
                    .accessibilityIdentifier("childForm.birthday")
            }

            Section(L10n.ChildForm.avatarLabel) {
                avatarPicker
            }

            Section(L10n.ChildForm.avatarColorLabel) {
                avatarColorPicker
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(palette.danger)
            }
        }
        .navigationTitle(existingChild == nil ? L10n.ChildForm.titleNew : L10n.ChildForm.titleEdit)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.ChildForm.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.ChildForm.save, action: save)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("childForm.save")
            }
        }
    }

    private var avatarPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.sm) {
            ForEach(ChildAvatarOption.allCases) { option in
                Button {
                    avatar = option
                } label: {
                    Image(systemName: option.rawValue)
                        .font(.system(size: 22))
                        .frame(minWidth: Spacing.xxl, minHeight: Spacing.xxl)
                        .background(avatar == option ? avatarColor.color(in: palette).opacity(0.3) : palette.secondarySurface)
                        .clipShape(Circle())
                }
                .accessibilityIdentifier("childForm.avatar.\(option.rawValue)")
                .accessibilityAddTraits(avatar == option ? [.isButton, .isSelected] : [.isButton])
            }
        }
    }

    private var avatarColorPicker: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(ChildAvatarColorOption.allCases) { option in
                Button {
                    avatarColor = option
                } label: {
                    Circle()
                        .fill(option.color(in: palette))
                        .frame(minWidth: Spacing.xxl, minHeight: Spacing.xxl)
                        .overlay {
                            if avatarColor == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .accessibilityIdentifier("childForm.avatarColor.\(option.rawValue)")
                .accessibilityAddTraits(avatarColor == option ? [.isButton, .isSelected] : [.isButton])
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        do {
            if let existingChild {
                existingChild.name = trimmedName
                existingChild.birthday = birthday
                existingChild.avatarIdentifier = avatar.rawValue
                existingChild.avatarColorIdentifier = avatarColor.rawValue
                try childStore.updateChild(existingChild)
            } else {
                try childStore.createChild(
                    name: trimmedName,
                    birthday: birthday,
                    avatarIdentifier: avatar.rawValue,
                    avatarColorIdentifier: avatarColor.rawValue
                )
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
