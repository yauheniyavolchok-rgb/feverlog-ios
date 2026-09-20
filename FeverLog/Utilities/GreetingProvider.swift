import Foundation

enum Greeting: Equatable, Sendable {
    case morning
    case afternoon
    case evening

    var localized: String {
        switch self {
        case .morning: L10n.Home.greetingMorning
        case .afternoon: L10n.Home.greetingAfternoon
        case .evening: L10n.Home.greetingEvening
        }
    }
}

enum GreetingProvider {
    static func greeting(for date: Date = .now, calendar: Calendar = .current) -> Greeting {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        default: return .evening
        }
    }
}
