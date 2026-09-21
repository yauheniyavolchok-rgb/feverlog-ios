import SwiftData
import SwiftUI
import UIKit

struct NoteEntryScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    let child: Child
    var existingEntry: NoteEntry?
    var isDuplicate: Bool = false
    var onSaved: () -> Void = {}

    @State private var text: String
    @State private var recordedAt: Date
    @State private var errorMessage: String?

    init(child: Child, existingEntry: NoteEntry? = nil, isDuplicate: Bool = false, onSaved: @escaping () -> Void = {}) {
        self.child = child
        self.existingEntry = existingEntry
        self.isDuplicate = isDuplicate
        self.onSaved = onSaved
        _text = State(initialValue: existingEntry?.text ?? "")
        _recordedAt = State(initialValue: isDuplicate ? .now : (existingEntry?.recordedAt ?? .now))
    }

    var body: some View {
        Form {
            Section(L10n.NoteEntry.textLabel) {
                TextEditor(text: $text)
                    .frame(minHeight: 120)
                    .accessibilityIdentifier("noteEntry.text")
            }

            Section {
                DatePicker(L10n.NoteEntry.dateLabel, selection: $recordedAt, in: ...Date.now)
                    .accessibilityIdentifier("noteEntry.date")
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(palette.danger)
            }
        }
        .navigationTitle(existingEntry != nil && !isDuplicate ? L10n.NoteEntry.editTitle : L10n.NoteEntry.addTitle)
        .announcesAccessibilityErrors(errorMessage)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.NoteEntry.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.NoteEntry.save, action: save)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("noteEntry.save")
            }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let repository = SwiftDataNoteEntryRepository(context: modelContext)
            if let existingEntry, !isDuplicate {
                existingEntry.text = trimmed
                existingEntry.recordedAt = recordedAt
                try repository.update(existingEntry)
            } else {
                _ = try repository.create(text: trimmed, recordedAt: recordedAt, child: child)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
