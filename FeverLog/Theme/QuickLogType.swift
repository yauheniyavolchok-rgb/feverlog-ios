import Foundation

/// A quick, single-tap log entry type: no free-form fields, just a type and
/// a 3-option severity/quantity scale chosen from a popup at log time. Each
/// type's three degree labels are its own scale — they are not comparable
/// across types (e.g. pee's degrees describe color, not intensity).
enum QuickLogType: String, CaseIterable, Identifiable, Codable, Sendable {
    case food
    case drink
    case pee
    case poop
    case vomit
    case breath

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .food: "fork.knife"
        case .drink: "cup.and.saucer.fill"
        case .pee: "drop.fill"
        case .poop: "toilet.fill"
        case .vomit: "exclamationmark.triangle.fill"
        case .breath: "lungs.fill"
        }
    }

    var localizedLabel: String {
        switch self {
        case .food: L10n.QuickLog.food
        case .drink: L10n.QuickLog.drink
        case .pee: L10n.QuickLog.pee
        case .poop: L10n.QuickLog.poop
        case .vomit: L10n.QuickLog.vomit
        case .breath: L10n.QuickLog.breath
        }
    }

    /// The three degree options for this type, in display order. `degree`
    /// on `QuickLogEntry` is a 1-based index into this array.
    var degreeLabels: [String] {
        switch self {
        case .food: [L10n.QuickLog.foodDegree1, L10n.QuickLog.foodDegree2, L10n.QuickLog.foodDegree3]
        case .drink: [L10n.QuickLog.drinkDegree1, L10n.QuickLog.drinkDegree2, L10n.QuickLog.drinkDegree3]
        case .pee: [L10n.QuickLog.peeDegree1, L10n.QuickLog.peeDegree2, L10n.QuickLog.peeDegree3]
        case .poop: [L10n.QuickLog.poopDegree1, L10n.QuickLog.poopDegree2, L10n.QuickLog.poopDegree3]
        case .vomit: [L10n.QuickLog.vomitDegree1, L10n.QuickLog.vomitDegree2, L10n.QuickLog.vomitDegree3]
        case .breath: [L10n.QuickLog.breathDegree1, L10n.QuickLog.breathDegree2, L10n.QuickLog.breathDegree3]
        }
    }

    /// `degree` is 1-based (matches how it's presented and stored); out-of-range
    /// values fall back to the raw "degree N" so a corrupt/future value never
    /// crashes or shows blank text.
    func degreeLabel(for degree: Int) -> String {
        guard degree >= 1, degree <= degreeLabels.count else { return "\(rawValue) \(degree)" }
        return degreeLabels[degree - 1]
    }
}
