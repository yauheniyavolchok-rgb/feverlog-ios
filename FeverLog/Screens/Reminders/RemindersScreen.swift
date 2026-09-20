import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct RemindersScreen: View {
    @Environment(ChildStore.self) private var childStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette
    @Environment(\.openURL) private var openURL

    @State private var reminders: [Reminder] = []
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingAddReminder = false
    @State private var editingReminder: Reminder?

    var body: some View {
        Group {
            if authorizationStatus == .denied {
                permissionDeniedState
            } else if reminders.isEmpty {
                EmptyStateView(
                    systemImage: "bell.fill",
                    title: L10n.Reminders.emptyTitle,
                    message: L10n.Reminders.emptyMessage
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.background)
            } else {
                List {
                    ForEach(reminders, id: \.id) { reminder in
                        reminderRow(reminder)
                            .swipeActions(edge: .trailing) { actions(for: reminder) }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(L10n.Reminders.title)
        .toolbar {
            if authorizationStatus != .denied {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddReminder = true
                    } label: {
                        Image(systemName: Icon.add)
                    }
                    .accessibilityLabel(L10n.Reminders.addButton)
                    .accessibilityIdentifier("reminders.addButton")
                }
            }
        }
        .navigationDestination(isPresented: $showingAddReminder) {
            if let child = childStore.selectedChild {
                ReminderFormScreen(child: child) { Task { await reload() } }
            }
        }
        .navigationDestination(item: $editingReminder) { reminder in
            if let child = childStore.selectedChild {
                ReminderFormScreen(child: child, existingReminder: reminder) { Task { await reload() } }
            }
        }
        .task { await reload() }
    }

    private var permissionDeniedState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 40))
                .foregroundStyle(palette.secondaryText)
                .accessibilityHidden(true)
            Text(L10n.Reminders.permissionDeniedTitle)
                .font(Typography.sectionTitle)
                .foregroundStyle(palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            Text(L10n.Reminders.permissionDeniedMessage)
                .font(Typography.body)
                .foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.center)
            Button(L10n.Reminders.openSettingsButton) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .accessibilityIdentifier("reminders.openSettings")
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
    }

    private func reminderRow(_ reminder: Reminder) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: reminder.reminderType.systemImage)
                .foregroundStyle(reminder.isEnabled ? palette.accentBlue : palette.secondaryText)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(reminder.reminderType.localizedLabel)
                    .font(Typography.body.weight(.semibold))
                Text(reminder.scheduleDate, format: .dateTime.month().day().hour().minute())
                    .font(Typography.caption)
                    .foregroundStyle(palette.secondaryText)
            }
            Spacer()
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture { editingReminder = reminder }
    }

    @ViewBuilder
    private func actions(for reminder: Reminder) -> some View {
        Button(role: .destructive) {
            NotificationScheduler().cancel(reminder)
            try? SwiftDataReminderRepository(context: modelContext).softDelete(reminder)
            Task { await reload() }
        } label: {
            Label(L10n.Timeline.delete, systemImage: "trash")
        }
        Button {
            editingReminder = reminder
        } label: {
            Label(L10n.Timeline.edit, systemImage: "pencil")
        }
        .tint(palette.accentLavender)
    }

    private func reload() async {
        #if DEBUG
        if UITestSupport.forcesNotificationsDenied {
            authorizationStatus = .denied
        } else {
            authorizationStatus = await NotificationScheduler().currentAuthorizationStatus()
        }
        #else
        authorizationStatus = await NotificationScheduler().currentAuthorizationStatus()
        #endif
        guard let child = childStore.selectedChild else {
            reminders = []
            return
        }
        reminders = (try? SwiftDataReminderRepository(context: modelContext).fetchAll(for: child)) ?? []
    }
}
