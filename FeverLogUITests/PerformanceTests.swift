import XCTest

/// Performance measurement harness. See the "Performance" section of
/// README.md for how to run these, read the results, and set baselines —
/// baselines are a local, per-machine Xcode setting and deliberately not
/// committed to the repo, since they're specific to the hardware/OS
/// combination they were captured on.
final class PerformanceTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Cold app launch, from process start to the first frame being drawn.
    /// This intentionally launches with no seeded data — launch time should
    /// be dominated by fixed startup cost (SwiftData container setup,
    /// initial view construction), not by data volume.
    @MainActor
    func testColdLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state"]
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }

    /// Scrolling the Timeline with several months of history (300 entries
    /// for one child — see `UITestSupport.seedLargeDatasetIfRequested`).
    /// Measures CPU and memory during a representative scroll gesture, the
    /// two resources most likely to regress if a future change makes the
    /// day-grouping or row rendering less efficient.
    @MainActor
    func testTimelineScrollWithLargeDataset() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state", "--uitest-seed-large-dataset"]
        app.launch()
        app.buttons["onboarding.skip"].tap()
        app.tabBars.buttons["Timeline"].tap()
        XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 5))

        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            for _ in 0..<5 {
                app.swipeUp(velocity: .fast)
            }
            for _ in 0..<5 {
                app.swipeDown(velocity: .fast)
            }
        }
    }
}
