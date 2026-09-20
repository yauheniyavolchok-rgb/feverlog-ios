import SwiftUI

// TODO(Phase 6, Quick Add medication): Enable the Medication option once medication logging ships.
// Completion: tapping Medication opens the Phase 6 medication entry flow.
// Release blocker: yes if the option remains visibly enabled but non-functional in a release.
// TODO(Phase 7, Quick Add symptoms/note): Enable Symptoms and Note options once those flows ship.
// Completion: tapping either option opens its Phase 7 entry flow.
// Release blocker: yes if either option remains visibly enabled but non-functional in a release.
struct QuickAddSheet: View {
    @Environment(\.feverPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    let child: Child
    let onLoggedTemperature: () -> Void

    @State private var showingTemperatureEntry = false

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
                    identifier: "quickAdd.medication",
                    isEnabled: false
                ) {}

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
                    onLoggedTemperature()
                    dismiss()
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
