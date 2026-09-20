import Foundation

// Phase 8/9 additions split into their own file — `L10n`'s single-file
// body was exceeding SwiftLint's type-body-length limit.
extension L10n {
    enum Charts {
        static var range24h: String { String(localized: "charts.range.24h") }
        static var range3d: String { String(localized: "charts.range.3d") }
        static var range7d: String { String(localized: "charts.range.7d") }
        static var range14d: String { String(localized: "charts.range.14d") }
        static var rangeLabel: String { String(localized: "charts.range.label") }

        static var temperatureTitle: String { String(localized: "charts.temperature.title") }
        static var temperatureEmpty: String { String(localized: "charts.temperature.empty") }
        static var temperatureAxisLabel: String { String(localized: "charts.temperature.axisLabel") }
        static var temperaturePointAccessibility: String { String(localized: "charts.temperature.point.accessibility") }
        static var medicationMarkerAccessibility: String { String(localized: "charts.medicationMarker.accessibility") }

        static var medicationTitle: String { String(localized: "charts.medication.title") }
        static var medicationEmpty: String { String(localized: "charts.medication.empty") }
        static var medicationBarAccessibility: String { String(localized: "charts.medication.bar.accessibility") }

        static var symptomsTitle: String { String(localized: "charts.symptoms.title") }
        static var symptomsEmpty: String { String(localized: "charts.symptoms.empty") }
        static var symptomsBarAccessibility: String { String(localized: "charts.symptoms.bar.accessibility") }

        static var noChildTitle: String { String(localized: "charts.noChild.title") }
        static var noChildMessage: String { String(localized: "charts.noChild.message") }
    }

    enum Reminders {
        static var title: String { String(localized: "reminders.title") }
        static var addButton: String { String(localized: "reminders.addButton") }
        static var emptyTitle: String { String(localized: "reminders.empty.title") }
        static var emptyMessage: String { String(localized: "reminders.empty.message") }
        static var permissionDeniedTitle: String { String(localized: "reminders.permissionDenied.title") }
        static var permissionDeniedMessage: String { String(localized: "reminders.permissionDenied.message") }
        static var openSettingsButton: String { String(localized: "reminders.openSettingsButton") }

        static var typeLabel: String { String(localized: "reminders.type.label") }
        static var typeMedication: String { String(localized: "reminders.type.medication") }
        static var typeTemperature: String { String(localized: "reminders.type.temperature") }
        static var typeHydration: String { String(localized: "reminders.type.hydration") }
        static var typeCustom: String { String(localized: "reminders.type.custom") }

        static var dateLabel: String { String(localized: "reminders.date.label") }
        static var enabledLabel: String { String(localized: "reminders.enabled.label") }
        static var save: String { String(localized: "reminders.save") }
        static var cancel: String { String(localized: "reminders.cancel") }
        static var addTitle: String { String(localized: "reminders.addTitle") }
        static var editTitle: String { String(localized: "reminders.editTitle") }

        static var notificationTitleMedication: String { String(localized: "reminders.notification.title.medication") }
        static var notificationTitleTemperature: String { String(localized: "reminders.notification.title.temperature") }
        static var notificationTitleHydration: String { String(localized: "reminders.notification.title.hydration") }
        static var notificationTitleCustom: String { String(localized: "reminders.notification.title.custom") }
        static var notificationBody: String { String(localized: "reminders.notification.body") }
    }

    enum Account {
        static var title: String { String(localized: "account.title") }

        static var notBackedUpTitle: String { String(localized: "account.notBackedUp.title") }
        static var notBackedUpMessage: String { String(localized: "account.notBackedUp.message") }
        static var continueWithApple: String { String(localized: "account.continueWithApple") }
        static var continueWithGoogle: String { String(localized: "account.continueWithGoogle") }
        static var continueWithEmail: String { String(localized: "account.continueWithEmail") }

        static var emailPromptTitle: String { String(localized: "account.emailPrompt.title") }
        static var emailLabel: String { String(localized: "account.email.label") }
        static var emailSend: String { String(localized: "account.email.send") }
        static var emailCodeSentMessage: String { String(localized: "account.email.codeSent.message") }
        static var emailCodeLabel: String { String(localized: "account.email.code.label") }
        static var emailConfirm: String { String(localized: "account.email.confirm") }
        static var cancel: String { String(localized: "account.cancel") }

        static var linkedTitle: String { String(localized: "account.linked.title") }
        static var linkedMessage: String { String(localized: "account.linked.message") }

        static var householdTitle: String { String(localized: "account.household.title") }
        static var householdInviteCodeLabel: String { String(localized: "account.household.inviteCode.label") }
        static var householdGenerateInvite: String { String(localized: "account.household.generateInvite") }
        static var householdJoinTitle: String { String(localized: "account.household.join.title") }
        static var householdJoinCodeLabel: String { String(localized: "account.household.join.codeLabel") }
        static var householdJoinButton: String { String(localized: "account.household.join.button") }
        static var householdJoinSuccessMessage: String { String(localized: "account.household.join.successMessage") }

        static var signOut: String { String(localized: "account.signOut") }
        static var signOutConfirmTitle: String { String(localized: "account.signOutConfirm.title") }
        static var signOutConfirmMessage: String { String(localized: "account.signOutConfirm.message") }
        static var signOutConfirmConfirm: String { String(localized: "account.signOutConfirm.confirm") }
        static var signOutConfirmCancel: String { String(localized: "account.signOutConfirm.cancel") }
    }

    enum SyncStatus {
        static var title: String { String(localized: "syncStatus.title") }
        static var syncNow: String { String(localized: "syncStatus.syncNow") }
        static var queueEmptyMessage: String { String(localized: "syncStatus.queueEmpty.message") }
        static var pendingCount: String { String(localized: "syncStatus.pendingCount") }
        static var failedCount: String { String(localized: "syncStatus.failedCount") }
        static var notConfiguredMessage: String { String(localized: "syncStatus.notConfigured.message") }
    }
}
