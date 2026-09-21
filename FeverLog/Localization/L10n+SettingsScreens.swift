import Foundation

// Phase 10 Settings screens (Household, Children, Medication Library,
// Units, About, Privacy) — split from `L10n`/`L10n+Sync` for the same
// type-body-length reason documented there.
extension L10n {
    enum HouseholdSettings {
        static var title: String { localized("householdSettings.title") }
        static var nameLabel: String { localized("householdSettings.name.label") }
        static var save: String { localized("householdSettings.save") }
        static var membersTitle: String { localized("householdSettings.members.title") }
        static var roleOwner: String { localized("householdSettings.role.owner") }
        static var roleMember: String { localized("householdSettings.role.member") }
    }

    enum ChildrenSettings {
        static var title: String { localized("childrenSettings.title") }
        static var addButton: String { localized("childrenSettings.addButton") }
        static var emptyTitle: String { localized("childrenSettings.empty.title") }
        static var emptyMessage: String { localized("childrenSettings.empty.message") }
    }

    enum MedicationLibrarySettings {
        static var title: String { localized("medicationLibrarySettings.title") }
        static var searchPlaceholder: String { localized("medicationLibrarySettings.searchPlaceholder") }
        static var emptyTitle: String { localized("medicationLibrarySettings.empty.title") }
        static var emptyMessage: String { localized("medicationLibrarySettings.empty.message") }
        static var singleDoseTitle: String { localized("medicationLibrarySettings.singleDose.title") }
        static var dailyMaximumTitle: String { localized("medicationLibrarySettings.dailyMaximum.title") }
        static var notConfigured: String { localized("medicationLibrarySettings.notConfigured") }
        static var sourceLabel: String { localized("medicationLibrarySettings.source.label") }

        static var brandLabel: String { localized("medicationLibrarySettings.brand.label") }
        static var activeIngredientLabel: String { localized("medicationLibrarySettings.activeIngredient.label") }
        static var strengthLabel: String { localized("medicationLibrarySettings.strength.label") }
        static var formLabel: String { localized("medicationLibrarySettings.form.label") }

        static var minLabel: String { localized("medicationLibrarySettings.min.label") }
        static var maxLabel: String { localized("medicationLibrarySettings.max.label") }
        static var maxPerDoseLabel: String { localized("medicationLibrarySettings.maxPerDose.label") }
        static var maxPerDayPerKgLabel: String { localized("medicationLibrarySettings.maxPerDayPerKg.label") }
        static var maxPerDayLabel: String { localized("medicationLibrarySettings.maxPerDay.label") }
        static var maxDosesPerDayLabel: String { localized("medicationLibrarySettings.maxDosesPerDay.label") }
        static var minIntervalLabel: String { localized("medicationLibrarySettings.minInterval.label") }
    }

    enum UnitsSettings {
        static var title: String { localized("unitsSettings.title") }
        static var weightUnitTitle: String { localized("unitsSettings.weightUnit.title") }
    }

    enum About {
        static var title: String { localized("about.title") }
        static var versionLabel: String { localized("about.version.label") }
        static var offlineFirstMessage: String { localized("about.offlineFirst.message") }
        static var disclaimerTitle: String { localized("about.disclaimer.title") }
        static var disclaimerMessage: String { localized("about.disclaimer.message") }
    }

    enum Privacy {
        static var title: String { localized("privacy.title") }
        static var dataStorageTitle: String { localized("privacy.dataStorage.title") }
        static var dataStorageMessage: String { localized("privacy.dataStorage.message") }
        static var syncTitle: String { localized("privacy.sync.title") }
        static var syncMessage: String { localized("privacy.sync.message") }
        static var noTelemetryTitle: String { localized("privacy.noTelemetry.title") }
        static var noTelemetryMessage: String { localized("privacy.noTelemetry.message") }
    }
}
