import Testing
@testable import FeverLog

@Suite("MedicationCatalog")
struct MedicationCatalogTests {
    @Test("loads the bundled medication reference database")
    func loadsBundledMedications() {
        let medications = MedicationCatalog.loadBundled()
        #expect(!medications.isEmpty)
    }

    @Test("empty query returns all medications")
    func emptyQueryReturnsAll() {
        let medications = MedicationCatalog.loadBundled()
        #expect(MedicationCatalog.search(medications, query: "").count == medications.count)
        #expect(MedicationCatalog.search(medications, query: "   ").count == medications.count)
    }

    @Test("search matches by brand, case-insensitively")
    func searchMatchesByBrand() {
        let medications = MedicationCatalog.loadBundled()
        let results = MedicationCatalog.search(medications, query: "tylenol")
        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.brand.lowercased().contains("tylenol") })
    }

    @Test("search matches by active ingredient")
    func searchMatchesByActiveIngredient() {
        let medications = MedicationCatalog.loadBundled()
        let results = MedicationCatalog.search(medications, query: "ibuprofen")
        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.activeIngredient.lowercased().contains("ibuprofen") })
    }

    @Test("search with no matches returns an empty array")
    func searchWithNoMatchesReturnsEmpty() {
        let medications = MedicationCatalog.loadBundled()
        #expect(MedicationCatalog.search(medications, query: "not-a-real-medication-xyz").isEmpty)
    }
}
