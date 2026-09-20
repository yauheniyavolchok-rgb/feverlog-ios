import Foundation
import Testing
@testable import FeverLogEngine

@Suite("RollingWindow")
struct RollingWindowTests {
    private let key = "paracetamol"

    private func dose(_ milligrams: Decimal, at date: Date, key: String = "paracetamol") -> DoseAdministration {
        DoseAdministration(id: UUID().uuidString, normalizedActiveIngredientKey: key, milligrams: milligrams, administeredAt: date)
    }

    @Test("aggregates only doses within the trailing 24 hours")
    func aggregatesWithinWindow() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let doses = [
            dose(100, at: now.addingTimeInterval(-2 * 3600)),   // 2h ago: in window
            dose(100, at: now.addingTimeInterval(-23 * 3600)),  // 23h ago: in window
            dose(100, at: now.addingTimeInterval(-25 * 3600))   // 25h ago: outside window
        ]

        let result = RollingWindow.doses(from: doses, matchingNormalizedKey: key, at: now)

        #expect(result.doseCount == 2)
        #expect(result.totalMilligrams == 200)
    }

    @Test("lower boundary is inclusive: exactly 24 hours ago counts")
    func lowerBoundaryIsInclusive() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let exactlyOnBoundary = now.addingTimeInterval(-RollingWindow.defaultDuration)
        let doses = [dose(100, at: exactlyOnBoundary)]

        let result = RollingWindow.doses(from: doses, matchingNormalizedKey: key, at: now)

        #expect(result.doseCount == 1)
    }

    @Test("a dose one second before the lower boundary is excluded")
    func justBeforeLowerBoundaryIsExcluded() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let justOutside = now.addingTimeInterval(-RollingWindow.defaultDuration - 1)
        let doses = [dose(100, at: justOutside)]

        let result = RollingWindow.doses(from: doses, matchingNormalizedKey: key, at: now)

        #expect(result.doseCount == 0)
    }

    @Test("upper boundary is exclusive: a dose at exactly administrationTime is excluded")
    func upperBoundaryIsExclusive() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let doses = [dose(100, at: now)]

        let result = RollingWindow.doses(from: doses, matchingNormalizedKey: key, at: now)

        #expect(result.doseCount == 0)
    }

    @Test("only doses matching the normalized key are included")
    func filtersByNormalizedKey() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let doses = [
            dose(100, at: now.addingTimeInterval(-3600), key: "paracetamol"),
            dose(100, at: now.addingTimeInterval(-3600), key: "ibuprofen")
        ]

        let result = RollingWindow.doses(from: doses, matchingNormalizedKey: "paracetamol", at: now)

        #expect(result.doseCount == 1)
        #expect(result.totalMilligrams == 100)
    }

    @Test("window boundaries use absolute elapsed time, independent of calendar/timezone")
    func timezoneIndependentElapsedTime() {
        // A dose exactly 23h59m59s before "now" is in-window regardless of
        // which calendar day or timezone that instant falls in.
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "Pacific/Kiritimati") ?? .current // UTC+14, crosses date lines readily

        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let justInside = now.addingTimeInterval(-(RollingWindow.defaultDuration - 1))
        let doses = [dose(100, at: justInside)]

        let result = RollingWindow.doses(from: doses, matchingNormalizedKey: key, at: now)

        #expect(result.doseCount == 1)
    }
}

@Suite("MedicationGrouping")
struct MedicationGroupingTests {
    private func dose(_ milligrams: Decimal, at date: Date, key: String) -> DoseAdministration {
        DoseAdministration(id: UUID().uuidString, normalizedActiveIngredientKey: key, milligrams: milligrams, administeredAt: date)
    }

    @Test("normalizes brand-name synonyms to the same key")
    func normalizesSynonyms() {
        #expect(ActiveIngredientNormalizer.normalize("Acetaminophen") == ActiveIngredientNormalizer.normalize("Paracetamol"))
    }

    @Test("is case and whitespace insensitive")
    func isCaseAndWhitespaceInsensitive() {
        #expect(ActiveIngredientNormalizer.normalize("  IBUPROFEN  ") == ActiveIngredientNormalizer.normalize("ibuprofen"))
    }

    @Test("different active ingredients never normalize to the same key")
    func differentIngredientsStayDistinct() {
        #expect(ActiveIngredientNormalizer.normalize("Ibuprofen") != ActiveIngredientNormalizer.normalize("Paracetamol"))
    }

    @Test("groups doses across brands/forms/concentrations by normalized key")
    func groupsAcrossVariants() {
        let now = Date()
        let key = ActiveIngredientNormalizer.normalize("Acetaminophen")
        let doses = [
            dose(100, at: now, key: ActiveIngredientNormalizer.normalize("Acetaminophen")),
            dose(100, at: now, key: ActiveIngredientNormalizer.normalize("Paracetamol")),
            dose(100, at: now, key: ActiveIngredientNormalizer.normalize("Ibuprofen"))
        ]

        let grouped = MedicationGrouping.group(doses)

        #expect(grouped[key]?.count == 2)
        #expect(grouped[ActiveIngredientNormalizer.normalize("Ibuprofen")]?.count == 1)
    }

    @Test("finds the most recent prior dose before the given instant")
    func findsMostRecentPriorDose() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let key = "paracetamol"
        let doses = [
            dose(100, at: now.addingTimeInterval(-7200), key: key),
            dose(100, at: now.addingTimeInterval(-3600), key: key),
            dose(100, at: now.addingTimeInterval(-1800), key: "ibuprofen")
        ]

        let mostRecent = MedicationGrouping.mostRecentPriorDose(in: doses, matchingNormalizedKey: key, before: now)

        #expect(mostRecent?.administeredAt == now.addingTimeInterval(-3600))
    }

    @Test("returns nil when there is no prior dose")
    func returnsNilWithNoPriorDose() {
        let mostRecent = MedicationGrouping.mostRecentPriorDose(in: [], matchingNormalizedKey: "paracetamol", before: .now)
        #expect(mostRecent == nil)
    }
}
