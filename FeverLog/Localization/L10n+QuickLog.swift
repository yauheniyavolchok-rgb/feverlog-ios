import Foundation

// Quick log types (food/drink/pee/poop/vomit/breath) — split from L10n for
// the same type-body-length reason documented there.
extension L10n {
    enum QuickLog {
        static var cancel: String { localized("quickLog.cancel") }
        static var save: String { localized("quickLog.save") }
        static var dateLabel: String { localized("quickLog.date.label") }
        static var editTitle: String { localized("quickLog.editTitle") }

        static var food: String { localized("quickLog.food") }
        static var foodDegree1: String { localized("quickLog.food.degree1") }
        static var foodDegree2: String { localized("quickLog.food.degree2") }
        static var foodDegree3: String { localized("quickLog.food.degree3") }

        static var drink: String { localized("quickLog.drink") }
        static var drinkDegree1: String { localized("quickLog.drink.degree1") }
        static var drinkDegree2: String { localized("quickLog.drink.degree2") }
        static var drinkDegree3: String { localized("quickLog.drink.degree3") }

        static var pee: String { localized("quickLog.pee") }
        static var peeDegree1: String { localized("quickLog.pee.degree1") }
        static var peeDegree2: String { localized("quickLog.pee.degree2") }
        static var peeDegree3: String { localized("quickLog.pee.degree3") }

        static var poop: String { localized("quickLog.poop") }
        static var poopDegree1: String { localized("quickLog.poop.degree1") }
        static var poopDegree2: String { localized("quickLog.poop.degree2") }
        static var poopDegree3: String { localized("quickLog.poop.degree3") }

        static var vomit: String { localized("quickLog.vomit") }
        static var vomitDegree1: String { localized("quickLog.vomit.degree1") }
        static var vomitDegree2: String { localized("quickLog.vomit.degree2") }
        static var vomitDegree3: String { localized("quickLog.vomit.degree3") }

        static var breath: String { localized("quickLog.breath") }
        static var breathDegree1: String { localized("quickLog.breath.degree1") }
        static var breathDegree2: String { localized("quickLog.breath.degree2") }
        static var breathDegree3: String { localized("quickLog.breath.degree3") }
    }
}
