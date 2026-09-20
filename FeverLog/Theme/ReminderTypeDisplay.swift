import Foundation

extension ReminderType {
    var localizedLabel: String {
        switch self {
        case .medication: L10n.Reminders.typeMedication
        case .temperature: L10n.Reminders.typeTemperature
        case .hydration: L10n.Reminders.typeHydration
        case .custom: L10n.Reminders.typeCustom
        }
    }

    var notificationTitle: String {
        switch self {
        case .medication: L10n.Reminders.notificationTitleMedication
        case .temperature: L10n.Reminders.notificationTitleTemperature
        case .hydration: L10n.Reminders.notificationTitleHydration
        case .custom: L10n.Reminders.notificationTitleCustom
        }
    }

    var systemImage: String {
        switch self {
        case .medication: "cross.case.fill"
        case .temperature: Icon.temperature
        case .hydration: "drop.fill"
        case .custom: "bell.fill"
        }
    }
}
