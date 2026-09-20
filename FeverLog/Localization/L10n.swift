import Foundation

/// Typed access to localization keys. Every user-facing string must be added
/// here rather than referenced by raw string literal in views/services.
enum L10n {
    enum Root {
        static var appName: String {
            String(localized: "root.appName")
        }

        static var developmentStatus: String {
            String(localized: "root.developmentStatus")
        }
    }

    enum Nav {
        static var home: String { String(localized: "nav.home") }
        static var timeline: String { String(localized: "nav.timeline") }
        static var charts: String { String(localized: "nav.charts") }
        static var settings: String { String(localized: "nav.settings") }
    }

    enum Appearance {
        static var system: String { String(localized: "appearance.system") }
        static var light: String { String(localized: "appearance.light") }
        static var dark: String { String(localized: "appearance.dark") }
        static var calmNight: String { String(localized: "appearance.calmNight") }
    }

    enum Settings {
        static var appearanceTitle: String { String(localized: "settings.appearance.title") }
    }

    enum Household {
        static var defaultDisplayName: String { String(localized: "household.defaultDisplayName") }
    }

    enum Screens {
        static var homeTitle: String { String(localized: "screens.home.title") }
        static var homePlaceholderMessage: String { String(localized: "screens.home.placeholderMessage") }

        static var timelineTitle: String { String(localized: "screens.timeline.title") }
        static var timelinePlaceholderMessage: String { String(localized: "screens.timeline.placeholderMessage") }

        static var chartsTitle: String { String(localized: "screens.charts.title") }
        static var chartsPlaceholderMessage: String { String(localized: "screens.charts.placeholderMessage") }
    }

    enum Onboarding {
        static var welcomeTitle: String { String(localized: "onboarding.welcome.title") }
        static var welcomeMessage: String { String(localized: "onboarding.welcome.message") }
        static var familySharingTitle: String { String(localized: "onboarding.familySharing.title") }
        static var familySharingMessage: String { String(localized: "onboarding.familySharing.message") }
        static var medicationSafetyTitle: String { String(localized: "onboarding.medicationSafety.title") }
        static var medicationSafetyMessage: String { String(localized: "onboarding.medicationSafety.message") }
        static var skip: String { String(localized: "onboarding.skip") }
        static var next: String { String(localized: "onboarding.next") }
        static var getStarted: String { String(localized: "onboarding.getStarted") }
    }

    enum Home {
        static var noChildTitle: String { String(localized: "home.noChild.title") }
        static var noChildMessage: String { String(localized: "home.noChild.message") }
        static var addChildButton: String { String(localized: "home.addChildButton") }
        static var childSelectorLabel: String { String(localized: "home.childSelector.label") }
        static var noReadingsYet: String { String(localized: "home.noReadingsYet") }
        static var todayTitle: String { String(localized: "home.today.title") }
        static var todayEmpty: String { String(localized: "home.today.empty") }
        static var medicationsTitle: String { String(localized: "home.medications.title") }
        static var medicationsEmpty: String { String(localized: "home.medications.empty") }
        static var symptomsTitle: String { String(localized: "home.symptoms.title") }
        static var symptomsEmpty: String { String(localized: "home.symptoms.empty") }
    }

    enum QuickAdd {
        static var title: String { String(localized: "quickAdd.title") }
        static var temperature: String { String(localized: "quickAdd.temperature") }
        static var medication: String { String(localized: "quickAdd.medication") }
        static var symptoms: String { String(localized: "quickAdd.symptoms") }
        static var note: String { String(localized: "quickAdd.note") }
    }

    enum TemperatureEntry {
        static var addTitle: String { String(localized: "temperatureEntry.addTitle") }
        static var editTitle: String { String(localized: "temperatureEntry.editTitle") }
        static var valueLabel: String { String(localized: "temperatureEntry.value.label") }
        static var methodLabel: String { String(localized: "temperatureEntry.method.label") }
        static var dateLabel: String { String(localized: "temperatureEntry.date.label") }
        static var noteLabel: String { String(localized: "temperatureEntry.note.label") }
        static var save: String { String(localized: "temperatureEntry.save") }
        static var cancel: String { String(localized: "temperatureEntry.cancel") }
        static var outOfRangeError: String { String(localized: "temperatureEntry.outOfRangeError") }
    }

    enum TemperatureStatusText {
        static var normal: String { String(localized: "temperatureStatus.normal") }
        static var elevated: String { String(localized: "temperatureStatus.elevated") }
        static var high: String { String(localized: "temperatureStatus.high") }
        static var veryHigh: String { String(localized: "temperatureStatus.veryHigh") }
        static var critical: String { String(localized: "temperatureStatus.critical") }
    }

    enum Timeline {
        static var emptyTitle: String { String(localized: "timeline.empty.title") }
        static var emptyMessage: String { String(localized: "timeline.empty.message") }
        static var today: String { String(localized: "timeline.today") }
        static var yesterday: String { String(localized: "timeline.yesterday") }
        static var edit: String { String(localized: "timeline.edit") }
        static var duplicate: String { String(localized: "timeline.duplicate") }
        static var delete: String { String(localized: "timeline.delete") }
        static var sortLabel: String { String(localized: "timeline.sort.label") }
        static var sortByTime: String { String(localized: "timeline.sort.byTime") }
        static var sortByChild: String { String(localized: "timeline.sort.byChild") }
    }

    enum ChildForm {
        static var titleNew: String { String(localized: "childForm.title.new") }
        static var titleEdit: String { String(localized: "childForm.title.edit") }
        static var nameLabel: String { String(localized: "childForm.name.label") }
        static var birthdayLabel: String { String(localized: "childForm.birthday.label") }
        static var avatarLabel: String { String(localized: "childForm.avatar.label") }
        static var avatarColorLabel: String { String(localized: "childForm.avatarColor.label") }
        static var weightLabel: String { String(localized: "childForm.weight.label") }
        static var weightOptionalHint: String { String(localized: "childForm.weight.optionalHint") }
        static var save: String { String(localized: "childForm.save") }
        static var cancel: String { String(localized: "childForm.cancel") }
    }

    enum ChildProfile {
        static func ageYears(_ count: Int) -> String {
            String(format: String(localized: "childProfile.age.years"), count)
        }

        static func ageMonths(_ count: Int) -> String {
            String(format: String(localized: "childProfile.age.months"), count)
        }

        static var weightLabel: String { String(localized: "childProfile.weight.label") }
        static var weightMissing: String { String(localized: "childProfile.weight.missing") }
        static var weightAddButton: String { String(localized: "childProfile.weight.addButton") }
        static var weightHistoryEmpty: String { String(localized: "childProfile.weightHistory.empty") }

        static var recentIllnessTitle: String { String(localized: "childProfile.recentIllness.title") }
        static var recentIllnessNoReadings: String { String(localized: "childProfile.recentIllness.noRecentReadings") }

        static var insightSpikeCount: String { String(localized: "childProfile.insight.spikeCount") }
        static var insightFeverDuration: String { String(localized: "childProfile.insight.feverDuration") }
        static var insightFeverFreeInterval: String { String(localized: "childProfile.insight.feverFreeInterval") }
        static var insightTemperatureChange: String { String(localized: "childProfile.insight.temperatureChange") }
        static var insightInsufficientData: String { String(localized: "childProfile.insight.insufficientData") }

        static var editButton: String { String(localized: "childProfile.editButton") }
        static var deleteButton: String { String(localized: "childProfile.deleteButton") }
        static var deleteConfirmTitle: String { String(localized: "childProfile.deleteConfirm.title") }
        static var deleteConfirmMessage: String { String(localized: "childProfile.deleteConfirm.message") }
        static var deleteConfirmConfirm: String { String(localized: "childProfile.deleteConfirm.confirm") }
        static var deleteConfirmCancel: String { String(localized: "childProfile.deleteConfirm.cancel") }
    }

    enum Symptom {
        static var breathing: String { String(localized: "symptom.breathing") }
        static var digestive: String { String(localized: "symptom.digestive") }
        static var pain: String { String(localized: "symptom.pain") }
        static var behavior: String { String(localized: "symptom.behavior") }
        static var hydration: String { String(localized: "symptom.hydration") }
        static var sleep: String { String(localized: "symptom.sleep") }
        static var skin: String { String(localized: "symptom.skin") }
        static var general: String { String(localized: "symptom.general") }
    }

    enum SymptomEntry {
        static var addTitle: String { String(localized: "symptomEntry.addTitle") }
        static var editTitle: String { String(localized: "symptomEntry.editTitle") }
        static var categoriesLabel: String { String(localized: "symptomEntry.categories.label") }
        static var dateLabel: String { String(localized: "symptomEntry.date.label") }
        static var save: String { String(localized: "symptomEntry.save") }
        static var cancel: String { String(localized: "symptomEntry.cancel") }
    }

    enum NoteEntry {
        static var addTitle: String { String(localized: "noteEntry.addTitle") }
        static var editTitle: String { String(localized: "noteEntry.editTitle") }
        static var textLabel: String { String(localized: "noteEntry.text.label") }
        static var dateLabel: String { String(localized: "noteEntry.date.label") }
        static var save: String { String(localized: "noteEntry.save") }
        static var cancel: String { String(localized: "noteEntry.cancel") }
    }

    enum MedicationSearch {
        static var title: String { String(localized: "medicationSearch.title") }
        static var searchPlaceholder: String { String(localized: "medicationSearch.searchPlaceholder") }
        static var emptyTitle: String { String(localized: "medicationSearch.empty.title") }
        static var emptyMessage: String { String(localized: "medicationSearch.empty.message") }
    }

    enum MedicationEntry {
        static var addTitle: String { String(localized: "medicationEntry.addTitle") }
        static var editTitle: String { String(localized: "medicationEntry.editTitle") }
        static var volumeLabel: String { String(localized: "medicationEntry.volume.label") }
        static var dateLabel: String { String(localized: "medicationEntry.date.label") }
        static var calculationTitle: String { String(localized: "medicationEntry.calculation.title") }
        static var milligramsLabel: String { String(localized: "medicationEntry.milligrams.label") }
        static var milligramsPerKilogramLabel: String { String(localized: "medicationEntry.milligramsPerKilogram.label") }
        static var recommendedRangeLabel: String { String(localized: "medicationEntry.recommendedRange.label") }
        static var safetyTitle: String { String(localized: "medicationEntry.safety.title") }
        static var save: String { String(localized: "medicationEntry.save") }
        static var cancel: String { String(localized: "medicationEntry.cancel") }
        static var confirmTitle: String { String(localized: "medicationEntry.confirm.title") }
        static var confirmMessage: String { String(localized: "medicationEntry.confirm.message") }
        static var confirmSave: String { String(localized: "medicationEntry.confirm.save") }
        static var confirmCancel: String { String(localized: "medicationEntry.confirm.cancel") }
    }

    enum MedicationSafety {
        static var disclaimer: String { String(localized: "medicationSafety.disclaimer") }
        static var rollingTotalLabel: String { String(localized: "medicationSafety.rollingTotal.label") }
        static var doseCountLabel: String { String(localized: "medicationSafety.doseCount.label") }
        static var nextEligibleLabel: String { String(localized: "medicationSafety.nextEligible.label") }

        static var statusNormal: String { String(localized: "medicationSafety.status.normal") }
        static var statusMissingWeight: String { String(localized: "medicationSafety.status.missingWeight") }
        static var statusMissingRule: String { String(localized: "medicationSafety.status.missingRule") }
        static var statusIntervalWarning: String { String(localized: "medicationSafety.status.intervalWarning") }
        static var statusApproachingMaximum: String { String(localized: "medicationSafety.status.approachingMaximum") }
        static var statusUnusualDose: String { String(localized: "medicationSafety.status.unusualDose") }
        static var statusMaximumExceeded: String { String(localized: "medicationSafety.status.maximumExceeded") }
        static var statusInvalidInput: String { String(localized: "medicationSafety.status.invalidInput") }
    }

    enum WeightForm {
        static var title: String { String(localized: "weightForm.title") }
        static var valueLabel: String { String(localized: "weightForm.value.label") }
        static var unitLabel: String { String(localized: "weightForm.unit.label") }
        static var effectiveDateLabel: String { String(localized: "weightForm.effectiveDate.label") }
        static var save: String { String(localized: "weightForm.save") }
        static var cancel: String { String(localized: "weightForm.cancel") }
    }

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
}
