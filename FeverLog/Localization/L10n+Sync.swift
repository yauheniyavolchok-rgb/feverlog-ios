import Foundation

// Phase 8/9 additions split into their own file — `L10n`'s single-file
// body was exceeding SwiftLint's type-body-length limit.
extension L10n {
    enum Charts {
        static var range24h: String { localized("charts.range.24h") }
        static var range3d: String { localized("charts.range.3d") }
        static var range7d: String { localized("charts.range.7d") }
        static var range14d: String { localized("charts.range.14d") }
        static var rangeLabel: String { localized("charts.range.label") }

        static var temperatureTitle: String { localized("charts.temperature.title") }
        static var temperatureEmpty: String { localized("charts.temperature.empty") }
        static var temperatureAxisLabel: String { localized("charts.temperature.axisLabel") }
        static var temperaturePointAccessibility: String { localized("charts.temperature.point.accessibility") }
        static var medicationMarkerAccessibility: String { localized("charts.medicationMarker.accessibility") }

        static var medicationTitle: String { localized("charts.medication.title") }
        static var medicationEmpty: String { localized("charts.medication.empty") }
        static var medicationBarAccessibility: String { localized("charts.medication.bar.accessibility") }

        static var symptomsTitle: String { localized("charts.symptoms.title") }
        static var symptomsEmpty: String { localized("charts.symptoms.empty") }
        static var symptomsBarAccessibility: String { localized("charts.symptoms.bar.accessibility") }

        static var noChildTitle: String { localized("charts.noChild.title") }
        static var noChildMessage: String { localized("charts.noChild.message") }
    }

    enum Reminders {
        static var title: String { localized("reminders.title") }
        static var addButton: String { localized("reminders.addButton") }
        static var emptyTitle: String { localized("reminders.empty.title") }
        static var emptyMessage: String { localized("reminders.empty.message") }
        static var permissionDeniedTitle: String { localized("reminders.permissionDenied.title") }
        static var permissionDeniedMessage: String { localized("reminders.permissionDenied.message") }
        static var openSettingsButton: String { localized("reminders.openSettingsButton") }

        static var typeLabel: String { localized("reminders.type.label") }
        static var typeMedication: String { localized("reminders.type.medication") }
        static var typeTemperature: String { localized("reminders.type.temperature") }
        static var typeHydration: String { localized("reminders.type.hydration") }
        static var typeCustom: String { localized("reminders.type.custom") }

        static var dateLabel: String { localized("reminders.date.label") }
        static var enabledLabel: String { localized("reminders.enabled.label") }
        static var save: String { localized("reminders.save") }
        static var cancel: String { localized("reminders.cancel") }
        static var addTitle: String { localized("reminders.addTitle") }
        static var editTitle: String { localized("reminders.editTitle") }

        static var notificationTitleMedication: String { localized("reminders.notification.title.medication") }
        static var notificationTitleTemperature: String { localized("reminders.notification.title.temperature") }
        static var notificationTitleHydration: String { localized("reminders.notification.title.hydration") }
        static var notificationTitleCustom: String { localized("reminders.notification.title.custom") }
        static var notificationBody: String { localized("reminders.notification.body") }
    }

    enum Account {
        static var title: String { localized("account.title") }

        static var notBackedUpTitle: String { localized("account.notBackedUp.title") }
        static var notBackedUpMessage: String { localized("account.notBackedUp.message") }
        static var continueWithApple: String { localized("account.continueWithApple") }
        static var continueWithGoogle: String { localized("account.continueWithGoogle") }
        static var continueWithEmail: String { localized("account.continueWithEmail") }

        static var emailPromptTitle: String { localized("account.emailPrompt.title") }
        static var emailLabel: String { localized("account.email.label") }
        static var emailSend: String { localized("account.email.send") }
        static var emailCodeSentMessage: String { localized("account.email.codeSent.message") }
        static var emailCodeLabel: String { localized("account.email.code.label") }
        static var emailConfirm: String { localized("account.email.confirm") }
        static var cancel: String { localized("account.cancel") }

        static var linkedTitle: String { localized("account.linked.title") }
        static var linkedMessage: String { localized("account.linked.message") }

        static var householdTitle: String { localized("account.household.title") }
        static var householdInviteCodeLabel: String { localized("account.household.inviteCode.label") }
        static var householdGenerateInvite: String { localized("account.household.generateInvite") }
        static var householdJoinTitle: String { localized("account.household.join.title") }
        static var householdJoinCodeLabel: String { localized("account.household.join.codeLabel") }
        static var householdJoinButton: String { localized("account.household.join.button") }
        static var householdJoinSuccessMessage: String { localized("account.household.join.successMessage") }

        static var signOut: String { localized("account.signOut") }
        static var signOutConfirmTitle: String { localized("account.signOutConfirm.title") }
        static var signOutConfirmMessage: String { localized("account.signOutConfirm.message") }
        static var signOutConfirmConfirm: String { localized("account.signOutConfirm.confirm") }
        static var signOutConfirmCancel: String { localized("account.signOutConfirm.cancel") }
    }

    enum SyncStatus {
        static var title: String { localized("syncStatus.title") }
        static var syncNow: String { localized("syncStatus.syncNow") }
        static var queueEmptyMessage: String { localized("syncStatus.queueEmpty.message") }
        static var pendingCount: String { localized("syncStatus.pendingCount") }
        static var failedCount: String { localized("syncStatus.failedCount") }
        static var notConfiguredMessage: String { localized("syncStatus.notConfigured.message") }
    }
}
