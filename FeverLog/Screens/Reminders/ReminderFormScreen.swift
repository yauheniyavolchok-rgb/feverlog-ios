import SwiftData
import SwiftUI
import UIKit

struct ReminderFormScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    let child: Child
    var existingReminder: Reminder?
    var onSaved: () -> Void = {}

    @State private var reminderType: ReminderType
    @State private var scheduleDate: Date
    @State private var isEnabled: Bool
    @State private var errorMessage: String?

    init(child: Child, existingReminder: Reminder? = nil, onSaved: @escaping () -> Void = {}) {
        self.child = child
        self.existingReminder = existingReminder
        self.onSaved = onSaved
        _reminderType = State(initialValue: existingReminder?.reminderType ?? .medication)
        _scheduleDate = State(initialValue: existingReminder?.scheduleDate ?? .now.addingTimeInterval(3600))
        _isEnabled = State(initialValue: existingReminder?.isEnabled ?? true)
    }

    var body: some View {
        Form {
            Section(L10n.Reminders.typeLabel) {
                Picker(L10n.Reminders.typeLabel, selection: $reminderType) {
                    ForEach(ReminderType.allCases, id: \.self) { type in
                        Text(type.localizedLabel).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("reminderForm.type")
            }

            Section {
                DatePicker(L10n.Reminders.dateLabel, selection: $scheduleDate, in: Date.now...)
                    .accessibilityIdentifier("reminderForm.date")
                Toggle(L10n.Reminders.enabledLabel, isOn: $isEnabled)
                    .accessibilityIdentifier("reminderForm.enabled")
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(palette.danger)
            }
        }
        .navigationTitle(existingReminder != nil ? L10n.Reminders.editTitle : L10n.Reminders.addTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.Reminders.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.Reminders.save, action: save)
                    .accessibilityIdentifier("reminderForm.save")
            }
        }
    }

    private func save() {
        do {
            let repository = SwiftDataReminderRepository(context: modelContext)
            let reminder: Reminder
            if let existingReminder {
                existingReminder.reminderType = reminderType
                existingReminder.scheduleDate = scheduleDate
                existingReminder.isEnabled = isEnabled
                try repository.update(existingReminder)
                reminder = existingReminder
            } else {
                reminder = try repository.create(
                    reminderType: reminderType,
                    scheduleDate: scheduleDate,
                    isEnabled: isEnabled,
                    child: child
                )
            }

            Task {
                let scheduler = NotificationScheduler()
                await scheduler.requestAuthorizationIfNeeded()
                try? await scheduler.schedule(reminder)
            }

            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
