import Testing
@testable import FeverLog

@Suite("TemperatureClassifier")
struct TemperatureClassificationTests {
    @Test(
        "classifies boundary values correctly",
        arguments: [
            (35.0, TemperatureStatus.normal),
            (36.0, TemperatureStatus.normal),
            (37.4, TemperatureStatus.normal),
            (37.5, TemperatureStatus.elevated),
            (38.0, TemperatureStatus.elevated),
            (38.1, TemperatureStatus.high),
            (39.0, TemperatureStatus.high),
            (39.1, TemperatureStatus.veryHigh),
            (40.0, TemperatureStatus.veryHigh),
            (40.1, TemperatureStatus.critical),
            (42.0, TemperatureStatus.critical)
        ]
    )
    func classifiesBoundaries(celsius: Double, expected: TemperatureStatus) {
        #expect(TemperatureClassifier.classify(celsius: celsius) == expected)
    }

    @Test("floating point rounding does not shift a boundary")
    func floatingPointRoundingIsStable() {
        // 37.4999... should round to 37.5 (tenths precision) and classify as elevated,
        // matching how the app stores/displays one-decimal temperatures.
        #expect(TemperatureClassifier.classify(celsius: 37.45) == .elevated)
        #expect(TemperatureClassifier.classify(celsius: 37.44) == .normal)
    }
}
