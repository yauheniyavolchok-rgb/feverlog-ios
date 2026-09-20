import Foundation

enum SymptomCategory: String, CaseIterable, Identifiable, Sendable {
    case breathing
    case digestive
    case pain
    case behavior
    case hydration
    case sleep
    case skin
    case general

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .breathing: "lungs.fill"
        case .digestive: "fork.knife"
        case .pain: "bolt.heart.fill"
        case .behavior: "face.smiling.fill"
        case .hydration: "drop.fill"
        case .sleep: "moon.zzz.fill"
        case .skin: "hand.raised.fill"
        case .general: "cross.case.fill"
        }
    }

    var localizedLabel: String {
        switch self {
        case .breathing: L10n.Symptom.breathing
        case .digestive: L10n.Symptom.digestive
        case .pain: L10n.Symptom.pain
        case .behavior: L10n.Symptom.behavior
        case .hydration: L10n.Symptom.hydration
        case .sleep: L10n.Symptom.sleep
        case .skin: L10n.Symptom.skin
        case .general: L10n.Symptom.general
        }
    }
}
