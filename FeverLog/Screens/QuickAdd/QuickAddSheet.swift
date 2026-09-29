import FeverLogEngine
import SwiftData
import SwiftUI
import UIKit

struct QuickAddSheet: View {
    @Environment(\.feverPalette) private var palette
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let child: Child
    let onLogged: () -> Void

    @State private var showingTemperatureEntry = false
    @State private var showingMedicationSearch = false
    @State private var showingMedicationDoseEntry = false
    @State private var selectedMedicationRule: MedicationRule?
    @State private var showingSymptomEntry = false
    @State private var showingNoteEntry = false
    @State private var selectedQuickLogType: QuickLogType?

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
                    identifier: "quickAdd.symptoms"
                ) {
                    showingSymptomEntry = true
                }

                quickAddOption(
                    title: L10n.QuickAdd.note,
                    systemImage: "note.text",
                    identifier: "quickAdd.note"
                ) {
                    showingNoteEntry = true
                }

                Divider()

                ForEach(QuickLogType.allCases) { type in
                    quickAddOption(
                        title: type.localizedLabel,
                        systemImage: type.systemImage,
                        identifier: "quickAdd.\(type.rawValue)"
                    ) {
                        selectedQuickLogType = type
                    }
                }

                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle(L10n.QuickAdd.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.TemperatureEntry.cancel) { dismiss() }
                }
            }
            .confirmationDialog(
                selectedQuickLogType?.localizedLabel ?? "",
                isPresented: Binding(
                    get: { selectedQuickLogType != nil },
                    set: { isPresented in if !isPresented { selectedQuickLogType = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let selectedQuickLogType {
                    ForEach(1...3, id: \.self) { degree in
                        degreeButton(selectedQuickLogType, degree: degree)
                    }
                    Button(L10n.QuickLog.cancel, role: .cancel) { self.selectedQuickLogType = nil }
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
            .navigationDestination(isPresented: $showingSymptomEntry) {
                SymptomEntryScreen(child: child) {
                    onLogged()
                    dismiss()
                }
            }
            .navigationDestination(isPresented: $showingNoteEntry) {
                NoteEntryScreen(child: child) {
                    onLogged()
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

    private func degreeButton(_ type: QuickLogType, degree: Int) -> some View {
        Button(type.degreeLabel(for: degree)) {
            logQuickEntry(type: type, degree: degree)
        }
        .accessibilityIdentifier("quickLog.\(type.rawValue).degree\(degree)")
    }

    private func logQuickEntry(type: QuickLogType, degree: Int) {
        let repository = SwiftDataQuickLogEntryRepository(context: modelContext)
        _ = try? repository.create(type: type, degree: degree, recordedAt: .now, child: child)
        selectedQuickLogType = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onLogged()
        dismiss()
    }
}
