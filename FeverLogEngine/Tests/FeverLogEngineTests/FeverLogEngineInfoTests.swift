import Testing
@testable import FeverLogEngine

@Suite("FeverLogEngineInfo")
struct FeverLogEngineInfoTests {
    @Test("version is set")
    func versionIsSet() {
        #expect(!FeverLogEngineInfo.version.isEmpty)
    }
}
