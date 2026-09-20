import FeverLogEngine
import SwiftUI

// TODO(Phase 7, Quick Add symptoms/note): Enable Symptoms and Note options once those flows ship.
// Completion: tapping either option opens its Phase 7 entry flow.
// Release blocker: yes if either option remains visibly enabled but non-functional in a release.
struct QuickAddSheet: View {
    @Environment(\.feverPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    let child: Child
    let onLogged: () -> Void

    @State private var showingTemperatureEntry = false
    @State private var showingMedicationSearch = false
    @State private var showingMedicationDoseEntry = false
    @State private var selectedMedicationRule: MedicationRule?

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                quickAddOption(
                    title: L10n.QuickAdd.temperature,
                    systemImage: Icon.temperature,
                    identifier: "quickAdd.temperature"
                ) {
                    showingTemperatureEntry = true
                }

                quickAddOption(
                    title: L10n.QuickAdd.medication,
                    systemImage: "cross.case.fill",
                    identifier: "quickAdd.medication"
                ) {
                    showingMedicationSearch = true
                }

                quickAddOption(
                    title: L10n.QuickAdd.symptoms,
                    systemImage: "list.bullet.clipboard.fill",
                    identifier: "quickAdd.symptoms",
                    isEnabled: false
                ) {}

                quickAddOption(
                    title: L10n.QuickAdd.note,
                    systemImage: "note.text",
                    identifier: "quickAdd.note",
                    isEnabled: false
                ) {}

                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle(L10n.QuickAdd.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.TemperatureEntry.cancel) { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showingTemperatureEntry) {
                TemperatureEntryScreen(child: child) {
                    onLogged()
                    dismiss()
                }
            }
            .navigationDestination(isPresented: $showingMedicationSearch) {
                MedicationSearchScreen { rule in
                    selectedMedicationRule = rule
                    showingMedicationDoseEntry = true
                }
            }
            .navigationDestination(isPresented: $showingMedicationDoseEntry) {
                if let selectedMedicationRule {
                    MedicationDoseEntryScreen(child: child, rule: selectedMedicationRule) {
                        onLogged()
                        dismiss()
                    }
                }
            }
        }
    }

    private func quickAddOption(
        title: String,
        systemImage: String,
        identifier: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                    .frame(width: Spacing.xxl, height: Spacing.xxl)
                    .background(palette.secondarySurface)
                    .clipShape(Circle())
                Text(title)
                    .font(Typography.body)
                Spacer()
            }
            .foregroundStyle(isEnabled ? palette.primaryText : palette.secondaryText)
            .frame(minHeight: Spacing.xxl)
        }
        .disabled(!isEnabled)
        .accessibilityIdentifier(identifier)
    }
}
