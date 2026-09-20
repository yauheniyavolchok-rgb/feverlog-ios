import Foundation

/// Typed access to localization keys. Every user-facing string must be added
/// here rather than referenced by raw string literal in views/services.
enum L10n {
    /// See `L10nLocale.bundle`'s doc comment for why this reads from a
    /// specific `.lproj` bundle rather than using `String(localized:locale:)`.
    /// Only a scoped subset of keys have a translation for every supported
    /// language (see AppLanguage's release-blocker note); unlike
    /// `String(localized:)`, `Bundle.localizedString` doesn't fall back to
    /// the base language on a miss — it returns `key` verbatim — so that
    /// fallback is reimplemented here explicitly.
    static func localized(_ key: String) -> String {
        let value = L10nLocale.bundle.localizedString(forKey: key, value: nil, table: "Localizable")
        guard value == key,
              let basePath = Bundle.main.path(forResource: "en", ofType: "lproj"),
              let baseBundle = Bundle(path: basePath) else {
            return value
        }
        return baseBundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }

    enum Root {
        static var appName: String { localized("root.appName") }
        static var developmentStatus: String { localized("root.developmentStatus") }
    }

    enum Nav {
        static var home: String { localized("nav.home") }
        static var timeline: String { localized("nav.timeline") }
        static var charts: String { localized("nav.charts") }
        static var settings: String { localized("nav.settings") }
    }

    enum Appearance {
        static var system: String { localized("appearance.system") }
        static var light: String { localized("appearance.light") }
        static var dark: String { localized("appearance.dark") }
        static var calmNight: String { localized("appearance.calmNight") }
    }

    enum Settings {
        static var appearanceTitle: String { localized("settings.appearance.title") }
    }

    enum LanguageSettings {
        static var title: String { localized("languageSettings.title") }
        static var system: String { localized("languageSettings.system") }
    }

    enum Household {
        static var defaultDisplayName: String { localized("household.defaultDisplayName") }
    }

    enum Screens {
        static var homeTitle: String { localized("screens.home.title") }
        static var homePlaceholderMessage: String { localized("screens.home.placeholderMessage") }

        static var timelineTitle: String { localized("screens.timeline.title") }
        static var timelinePlaceholderMessage: String { localized("screens.timeline.placeholderMessage") }

        static var chartsTitle: String { localized("screens.charts.title") }
        static var chartsPlaceholderMessage: String { localized("screens.charts.placeholderMessage") }
    }

    enum Onboarding {
        static var welcomeTitle: String { localized("onboarding.welcome.title") }
        static var welcomeMessage: String { localized("onboarding.welcome.message") }
        static var familySharingTitle: String { localized("onboarding.familySharing.title") }
        static var familySharingMessage: String { localized("onboarding.familySharing.message") }
        static var medicationSafetyTitle: String { localized("onboarding.medicationSafety.title") }
        static var medicationSafetyMessage: String { localized("onboarding.medicationSafety.message") }
        static var skip: String { localized("onboarding.skip") }
        static var next: String { localized("onboarding.next") }
        static var getStarted: String { localized("onboarding.getStarted") }
    }

    enum Home {
        static var noChildTitle: String { localized("home.noChild.title") }
        static var noChildMessage: String { localized("home.noChild.message") }
        static var addChildButton: String { localized("home.addChildButton") }
        static var childSelectorLabel: String { localized("home.childSelector.label") }
        static var noReadingsYet: String { localized("home.noReadingsYet") }
        static var todayTitle: String { localized("home.today.title") }
        static var todayEmpty: String { localized("home.today.empty") }
        static var medicationsTitle: String { localized("home.medications.title") }
        static var medicationsEmpty: String { localized("home.medications.empty") }
        static var symptomsTitle: String { localized("home.symptoms.title") }
        static var symptomsEmpty: String { localized("home.symptoms.empty") }
    }

    enum QuickAdd {
        static var title: String { localized("quickAdd.title") }
        static var temperature: String { localized("quickAdd.temperature") }
        static var medication: String { localized("quickAdd.medication") }
        static var symptoms: String { localized("quickAdd.symptoms") }
        static var note: String { localized("quickAdd.note") }
    }

    enum TemperatureEntry {
        static var addTitle: String { localized("temperatureEntry.addTitle") }
        static var editTitle: String { localized("temperatureEntry.editTitle") }
        static var valueLabel: String { localized("temperatureEntry.value.label") }
        static var methodLabel: String { localized("temperatureEntry.method.label") }
        static var dateLabel: String { localized("temperatureEntry.date.label") }
        static var noteLabel: String { localized("temperatureEntry.note.label") }
        static var save: String { localized("temperatureEntry.save") }
        static var cancel: String { localized("temperatureEntry.cancel") }
        static var outOfRangeError: String { localized("temperatureEntry.outOfRangeError") }
    }

    enum TemperatureStatusText {
        static var normal: String { localized("temperatureStatus.normal") }
        static var elevated: String { localized("temperatureStatus.elevated") }
        static var high: String { localized("temperatureStatus.high") }
        static var veryHigh: String { localized("temperatureStatus.veryHigh") }
        static var critical: String { localized("temperatureStatus.critical") }
    }

    enum Timeline {
        static var emptyTitle: String { localized("timeline.empty.title") }
        static var emptyMessage: String { localized("timeline.empty.message") }
        static var today: String { localized("timeline.today") }
        static var yesterday: String { localized("timeline.yesterday") }
        static var edit: String { localized("timeline.edit") }
        static var duplicate: String { localized("timeline.duplicate") }
        static var delete: String { localized("timeline.delete") }
        static var sortLabel: String { localized("timeline.sort.label") }
        static var sortByTime: String { localized("timeline.sort.byTime") }
        static var sortByChild: String { localized("timeline.sort.byChild") }
    }

    enum ChildForm {
        static var titleNew: String { localized("childForm.title.new") }
        static var titleEdit: String { localized("childForm.title.edit") }
        static var nameLabel: String { localized("childForm.name.label") }
        static var birthdayLabel: String { localized("childForm.birthday.label") }
        static var avatarLabel: String { localized("childForm.avatar.label") }
        static var avatarColorLabel: String { localized("childForm.avatarColor.label") }
        static var weightLabel: String { localized("childForm.weight.label") }
        static var weightOptionalHint: String { localized("childForm.weight.optionalHint") }
        static var save: String { localized("childForm.save") }
        static var cancel: String { localized("childForm.cancel") }
    }

    enum ChildProfile {
        static func ageYears(_ count: Int) -> String {
            String(format: localized("childProfile.age.years"), count)
        }

        static func ageMonths(_ count: Int) -> String {
            String(format: localized("childProfile.age.months"), count)
        }

        static var weightLabel: String { localized("childProfile.weight.label") }
        static var weightMissing: String { localized("childProfile.weight.missing") }
        static var weightAddButton: String { localized("childProfile.weight.addButton") }
        static var weightHistoryEmpty: String { localized("childProfile.weightHistory.empty") }

        static var recentIllnessTitle: String { localized("childProfile.recentIllness.title") }
        static var recentIllnessNoReadings: String { localized("childProfile.recentIllness.noRecentReadings") }

        static var insightSpikeCount: String { localized("childProfile.insight.spikeCount") }
        static var insightFeverDuration: String { localized("childProfile.insight.feverDuration") }
        static var insightFeverFreeInterval: String { localized("childProfile.insight.feverFreeInterval") }
        static var insightTemperatureChange: String { localized("childProfile.insight.temperatureChange") }
        static var insightInsufficientData: String { localized("childProfile.insight.insufficientData") }

        static var editButton: String { localized("childProfile.editButton") }
        static var deleteButton: String { localized("childProfile.deleteButton") }
        static var deleteConfirmTitle: String { localized("childProfile.deleteConfirm.title") }
        static var deleteConfirmMessage: String { localized("childProfile.deleteConfirm.message") }
        static var deleteConfirmConfirm: String { localized("childProfile.deleteConfirm.confirm") }
        static var deleteConfirmCancel: String { localized("childProfile.deleteConfirm.cancel") }
    }

    enum Symptom {
        static var breathing: String { localized("symptom.breathing") }
        static var digestive: String { localized("symptom.digestive") }
        static var pain: String { localized("symptom.pain") }
        static var behavior: String { localized("symptom.behavior") }
        static var hydration: String { localized("symptom.hydration") }
        static var sleep: String { localized("symptom.sleep") }
        static var skin: String { localized("symptom.skin") }
        static var general: String { localized("symptom.general") }
    }

    enum SymptomEntry {
        static var addTitle: String { localized("symptomEntry.addTitle") }
        static var editTitle: String { localized("symptomEntry.editTitle") }
        static var categoriesLabel: String { localized("symptomEntry.categories.label") }
        static var dateLabel: String { localized("symptomEntry.date.label") }
        static var save: String { localized("symptomEntry.save") }
        static var cancel: String { localized("symptomEntry.cancel") }
    }

    enum NoteEntry {
        static var addTitle: String { localized("noteEntry.addTitle") }
        static var editTitle: String { localized("noteEntry.editTitle") }
        static var textLabel: String { localized("noteEntry.text.label") }
        static var dateLabel: String { localized("noteEntry.date.label") }
        static var save: String { localized("noteEntry.save") }
        static var cancel: String { localized("noteEntry.cancel") }
    }

    enum MedicationSearch {
        static var title: String { localized("medicationSearch.title") }
        static var searchPlaceholder: String { localized("medicationSearch.searchPlaceholder") }
        static var emptyTitle: String { localized("medicationSearch.empty.title") }
        static var emptyMessage: String { localized("medicationSearch.empty.message") }
    }

    enum MedicationEntry {
        static var addTitle: String { localized("medicationEntry.addTitle") }
        static var editTitle: String { localized("medicationEntry.editTitle") }
        static var volumeLabel: String { localized("medicationEntry.volume.label") }
        static var dateLabel: String { localized("medicationEntry.date.label") }
        static var calculationTitle: String { localized("medicationEntry.calculation.title") }
        static var milligramsLabel: String { localized("medicationEntry.milligrams.label") }
        static var milligramsPerKilogramLabel: String { localized("medicationEntry.milligramsPerKilogram.label") }
        static var recommendedRangeLabel: String { localized("medicationEntry.recommendedRange.label") }
        static var safetyTitle: String { localized("medicationEntry.safety.title") }
        static var save: String { localized("medicationEntry.save") }
        static var cancel: String { localized("medicationEntry.cancel") }
        static var confirmTitle: String { localized("medicationEntry.confirm.title") }
        static var confirmMessage: String { localized("medicationEntry.confirm.message") }
        static var confirmSave: String { localized("medicationEntry.confirm.save") }
        static var confirmCancel: String { localized("medicationEntry.confirm.cancel") }
    }

    enum MedicationSafety {
        static var disclaimer: String { localized("medicationSafety.disclaimer") }
        static var rollingTotalLabel: String { localized("medicationSafety.rollingTotal.label") }
        static var doseCountLabel: String { localized("medicationSafety.doseCount.label") }
        static var nextEligibleLabel: String { localized("medicationSafety.nextEligible.label") }

        static var statusNormal: String { localized("medicationSafety.status.normal") }
        static var statusMissingWeight: String { localized("medicationSafety.status.missingWeight") }
        static var statusMissingRule: String { localized("medicationSafety.status.missingRule") }
        static var statusIntervalWarning: String { localized("medicationSafety.status.intervalWarning") }
        static var statusApproachingMaximum: String { localized("medicationSafety.status.approachingMaximum") }
        static var statusUnusualDose: String { localized("medicationSafety.status.unusualDose") }
        static var statusMaximumExceeded: String { localized("medicationSafety.status.maximumExceeded") }
        static var statusInvalidInput: String { localized("medicationSafety.status.invalidInput") }
    }

    enum WeightForm {
        static var title: String { localized("weightForm.title") }
        static var valueLabel: String { localized("weightForm.value.label") }
        static var unitLabel: String { localized("weightForm.unit.label") }
        static var effectiveDateLabel: String { localized("weightForm.effectiveDate.label") }
        static var save: String { localized("weightForm.save") }
        static var cancel: String { localized("weightForm.cancel") }
    }

}
