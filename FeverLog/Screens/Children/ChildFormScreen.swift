import SwiftData
import SwiftUI

struct ChildFormScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ChildStore.self) private var childStore
    @Environment(UnitsManager.self) private var unitsManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    /// `nil` means creating a new child; non-nil means editing an existing one.
    let existingChild: Child?

    @State private var name: String
    @State private var birthday: Date
    @State private var avatar: ChildAvatarOption
    @State private var avatarColor: ChildAvatarColorOption
    @State private var weightValue: Double = 0
    @State private var weightUnit: WeightUnit = .kilograms
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
            } footer: {
                Text(ageSummaryText)
            }

            if existingChild == nil {
                Section {
                    HStack {
                        Text(L10n.ChildForm.weightLabel)
                        Spacer()
                        TextField(
                            L10n.ChildForm.weightLabel,
                            value: $weightValue,
                            format: .number.precision(.fractionLength(0...2))
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("childForm.weight")
                    }

                    Picker(L10n.WeightForm.unitLabel, selection: $weightUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                    .accessibilityIdentifier("childForm.weightUnit")
                } footer: {
                    Text(L10n.ChildForm.weightOptionalHint)
                }
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
        .task {
            if existingChild == nil {
                weightUnit = unitsManager.defaultWeightUnit
            }
        }
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

    private var ageSummaryText: String {
        let age = AgeCalculator.age(from: birthday)
        return "\(L10n.ChildProfile.ageYears(age.years)) \(L10n.ChildProfile.ageMonths(age.months))"
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
                .buttonStyle(.plain)
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
                .buttonStyle(.plain)
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
                let newChild = try childStore.createChild(
                    name: trimmedName,
                    birthday: birthday,
                    avatarIdentifier: avatar.rawValue,
                    avatarColorIdentifier: avatarColor.rawValue
                )
                if let newChild, weightValue > 0 {
                    let weightRepository = SwiftDataWeightHistoryRepository(context: modelContext)
                    _ = try weightRepository.addWeight(weightValue, unit: weightUnit, effectiveDate: .now, child: newChild)
                }
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
