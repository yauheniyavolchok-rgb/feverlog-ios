import SwiftData
import SwiftUI
import UIKit

struct SymptomEntryScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    let child: Child
    var existingEntry: SymptomEntry?
    var isDuplicate: Bool = false
    var onSaved: () -> Void = {}

    @State private var selectedCategories: Set<SymptomCategory>
    @State private var recordedAt: Date
    @State private var errorMessage: String?

    init(child: Child, existingEntry: SymptomEntry? = nil, isDuplicate: Bool = false, onSaved: @escaping () -> Void = {}) {
        self.child = child
        self.existingEntry = existingEntry
        self.isDuplicate = isDuplicate
        self.onSaved = onSaved
        let initialCategories = Set((existingEntry?.symptomIdentifiers ?? []).compactMap { SymptomCategory(rawValue: $0) })
        _selectedCategories = State(initialValue: initialCategories)
        _recordedAt = State(initialValue: isDuplicate ? .now : (existingEntry?.recordedAt ?? .now))
    }

    var body: some View {
        Form {
            Section(L10n.SymptomEntry.categoriesLabel) {
                chipGrid
            }

            Section {
                DatePicker(L10n.SymptomEntry.dateLabel, selection: $recordedAt, in: ...Date.now)
                    .accessibilityIdentifier("symptomEntry.date")
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(palette.danger)
            }
        }
        .navigationTitle(existingEntry != nil && !isDuplicate ? L10n.SymptomEntry.editTitle : L10n.SymptomEntry.addTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.SymptomEntry.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.SymptomEntry.save, action: save)
                    .disabled(selectedCategories.isEmpty)
                    .accessibilityIdentifier("symptomEntry.save")
            }
        }
    }

    private var chipGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Spacing.sm) {
            ForEach(SymptomCategory.allCases) { category in
                Chip(
                    title: category.localizedLabel,
                    systemImage: category.systemImage,
                    isSelected: selectedCategories.contains(category)
                ) {
                    toggle(category)
                }
                .accessibilityIdentifier("symptomEntry.category.\(category.rawValue)")
            }
        }
    }

    private func toggle(_ category: SymptomCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    private func save() {
        guard !selectedCategories.isEmpty else { return }
        let identifiers = SymptomCategory.allCases.filter { selectedCategories.contains($0) }.map(\.rawValue)

        do {
            let repository = SwiftDataSymptomEntryRepository(context: modelContext)
            if let existingEntry, !isDuplicate {
                existingEntry.symptomIdentifiers = identifiers
                existingEntry.recordedAt = recordedAt
                try repository.update(existingEntry)
            } else {
                _ = try repository.create(symptomIdentifiers: identifiers, recordedAt: recordedAt, child: child)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
