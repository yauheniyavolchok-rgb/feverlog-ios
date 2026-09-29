import SwiftUI

/// Editing an existing quick-log entry — unlike the fast popup used to
/// create one (see `QuickAddSheet`), this is a normal pushed screen,
/// matching every other entry type's edit flow reached from Timeline.
struct QuickLogEntryEditScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    let existingEntry: QuickLogEntry
    var onSaved: () -> Void = {}

    @State private var degree: Int
    @State private var recordedAt: Date
    @State private var errorMessage: String?

    init(existingEntry: QuickLogEntry, onSaved: @escaping () -> Void = {}) {
        self.existingEntry = existingEntry
        self.onSaved = onSaved
        _degree = State(initialValue: existingEntry.degree)
        _recordedAt = State(initialValue: existingEntry.recordedAt)
    }

    var body: some View {
        Form {
            Section(existingEntry.type.localizedLabel) {
                degreePicker
            }

            Section {
                DatePicker(L10n.QuickLog.dateLabel, selection: $recordedAt, in: ...Date.now)
                    .accessibilityIdentifier("quickLogEdit.date")
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(palette.danger)
            }
        }
        .navigationTitle(existingEntry.type.localizedLabel)
        .announcesAccessibilityErrors(errorMessage)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.QuickLog.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.QuickLog.save, action: save)
                    .accessibilityIdentifier("quickLogEdit.save")
            }
        }
    }

    private var degreePicker: some View {
        ForEach(1...3, id: \.self) { candidateDegree in
            Button {
                degree = candidateDegree
            } label: {
                HStack {
                    Text(existingEntry.type.degreeLabel(for: candidateDegree))
                    Spacer()
                    if degree == candidateDegree {
                        Image(systemName: "checkmark")
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(Rectangle())
                .frame(minHeight: Spacing.xl)
            }
            .buttonStyle(.plain)
            .foregroundStyle(palette.primaryText)
            .accessibilityIdentifier("quickLogEdit.degree\(candidateDegree)")
            .accessibilityAddTraits(degree == candidateDegree ? [.isButton, .isSelected] : [.isButton])
        }
    }

    private func save() {
        do {
            existingEntry.degree = degree
            existingEntry.recordedAt = recordedAt
            try SwiftDataQuickLogEntryRepository(context: modelContext).update(existingEntry)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
