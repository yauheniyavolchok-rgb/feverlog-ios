import SwiftUI

struct UnitsSettingsScreen: View {
    @Environment(UnitsManager.self) private var unitsManager

    var body: some View {
        List {
            Section(L10n.UnitsSettings.weightUnitTitle) {
                ForEach(WeightUnit.allCases, id: \.self) { unit in
                    Button {
                        unitsManager.defaultWeightUnit = unit
                    } label: {
                        HStack {
                            Text(unit.rawValue.capitalized)
                            Spacer()
                            if unitsManager.defaultWeightUnit == unit {
                                Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                            }
                        }
                        .contentShape(Rectangle())
                        .frame(minHeight: Spacing.xxl)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("unitsSettings.weightUnit.\(unit.rawValue)")
                    .accessibilityAddTraits(unitsManager.defaultWeightUnit == unit ? [.isButton, .isSelected] : [.isButton])
                }
            }
        }
        .navigationTitle(L10n.UnitsSettings.title)
    }
}

#Preview {
    NavigationStack { UnitsSettingsScreen() }
        .environment(UnitsManager(settingsStore: InMemorySettingsStore()))
        .feverThemed()
}
