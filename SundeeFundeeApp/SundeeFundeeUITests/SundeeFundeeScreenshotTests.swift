import XCTest

@MainActor
final class SundeeFundeeScreenshotTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAppStoreScreenshots() {
        app.launchArguments += ["--seed-screenshots"]
        setupSnapshot(app)
        app.launch()

        XCTAssertTrue(waitForScreen(title: "Today", timeout: 20), "Missing Today screen")

        captureCoachPlanBenefit()
        capture(tab: "Cycle", title: "Cycle", name: "02_recovery_pain_energy")
        capture(tab: "Progress", title: "Progress", name: "03_progress_lifting")
        capture(tab: "Programs", title: "Programs", name: "04_programs")
        capture(tab: "Workouts", title: "Workouts", name: "05_workouts")
    }

    private func captureCoachPlanBenefit() {
        let button = app.buttons["Build Coach Plan"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing Build Coach Plan entry point")
        button.tap()

        XCTAssertTrue(waitForScreen(title: "Coach Plan", timeout: 10), "Missing Coach Plan screen")

        let resistanceBands = app.staticTexts["Resistance Bands"].firstMatch
        let scrollView = app.scrollViews.firstMatch
        for _ in 0..<6 where !resistanceBands.isHittable {
            XCTAssertTrue(scrollView.waitForExistence(timeout: 2), "Missing Coach Plan scroll view")
            scrollView.swipeUp()
        }
        XCTAssertTrue(resistanceBands.isHittable, "Missing visible Resistance Bands option")
        snapshot("01_coach_plan")

        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "Missing Coach Plan cancel button")
        cancel.tap()
        XCTAssertTrue(waitForScreen(title: "Today", timeout: 10), "Did not return to Today screen")
    }

    private func capture(tab: String, title: String, name: String) {
        let button = tabButton(named: tab)
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing \(tab) tab")
        button.tap()

        XCTAssertTrue(waitForScreen(title: title, timeout: 10), "Missing \(title) screen")
        snapshot(name)
    }

    private func tabButton(named name: String) -> XCUIElement {
        let tabBarButton = app.tabBars.buttons[name].firstMatch
        if tabBarButton.exists {
            return tabBarButton
        }

        return app.buttons[name].firstMatch
    }

    private func waitForScreen(title: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if app.navigationBars[title].firstMatch.exists || app.staticTexts[title].firstMatch.exists {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        return false
    }
}
