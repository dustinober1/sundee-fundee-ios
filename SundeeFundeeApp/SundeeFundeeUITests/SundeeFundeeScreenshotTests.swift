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
        snapshot("01_today")

        capture(tab: "Workouts", title: "Workouts", name: "02_workouts")
        capture(tab: "Programs", title: "Programs", name: "03_programs")
        capture(tab: "Cycle", title: "Cycle", name: "04_cycle")
        capture(tab: "Progress", title: "Progress", name: "05_progress")
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
