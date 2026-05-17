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

    func testRussianSquatProgramAndVanessaBenchmark() {
        app.launchArguments += ["--seed-screenshots"]
        setupSnapshot(app)
        app.launch()

        XCTAssertTrue(waitForScreen(title: "Today", timeout: 20), "Missing Today screen")

        let programsButton = tabButton(named: "Programs")
        XCTAssertTrue(programsButton.waitForExistence(timeout: 10), "Missing Programs tab")
        programsButton.tap()
        XCTAssertTrue(waitForScreen(title: "Programs", timeout: 10), "Missing Programs screen")

        let russianSquat = app.staticTexts["Russian Squat"].firstMatch
        XCTAssertTrue(scrollToElement(russianSquat, in: app.scrollViews.firstMatch), "Missing Russian Squat program")

        let viewProgram = app.buttons["View Program"].firstMatch
        XCTAssertTrue(viewProgram.waitForExistence(timeout: 5), "Missing View Program button")
        viewProgram.tap()

        XCTAssertTrue(waitForScreen(title: "Russian Squat", timeout: 10), "Missing Russian Squat detail screen")
        XCTAssertTrue(app.buttons["Printable PDF"].firstMatch.waitForExistence(timeout: 5), "Missing printable PDF action")
        XCTAssertTrue(app.staticTexts["Week 1"].firstMatch.waitForExistence(timeout: 5), "Missing Week 1 section")
        XCTAssertTrue(app.staticTexts["Day 1 - Session 1"].firstMatch.waitForExistence(timeout: 5), "Missing first Russian Squat session")

        let programsBackButton = app.navigationBars.buttons["Programs"].firstMatch
        XCTAssertTrue(programsBackButton.waitForExistence(timeout: 5), "Missing back button to Programs")
        programsBackButton.tap()
        XCTAssertTrue(waitForScreen(title: "Programs", timeout: 10), "Did not return to Programs")

        let todayButton = tabButton(named: "Today")
        XCTAssertTrue(todayButton.waitForExistence(timeout: 10), "Missing Today tab")
        todayButton.tap()
        XCTAssertTrue(waitForScreen(title: "Today", timeout: 10), "Did not return to Today")

        let benchmarksButton = app.buttons["Benchmarks"].firstMatch
        XCTAssertTrue(scrollToElement(benchmarksButton, in: app.scrollViews.firstMatch), "Missing Benchmarks shortcut")
        benchmarksButton.tap()
        XCTAssertTrue(waitForScreen(title: "Benchmarks", timeout: 10), "Missing Benchmarks screen")

        let vanessa = app.staticTexts["Vanessa"].firstMatch
        XCTAssertTrue(scrollToElement(vanessa, in: app.scrollViews.firstMatch), "Missing Vanessa benchmark")
        vanessa.tap()

        XCTAssertTrue(waitForScreen(title: "Vanessa", timeout: 10), "Missing Vanessa benchmark detail")
        let updatedWorkout = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "3-6-9-12-9-6-3 reps")
        ).firstMatch
        XCTAssertTrue(scrollToElement(updatedWorkout, in: app.scrollViews.firstMatch), "Missing updated Vanessa workout description")
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "10 cal BikeERG")
        ).firstMatch.exists, "Missing BikeERG interval copy")
    }

    private func captureCoachPlanBenefit() {
        let button = app.buttons["Build Coach Plan"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing Build Coach Plan entry point")
        button.tap()

        XCTAssertTrue(waitForScreen(title: "Coach Plan", timeout: 10), "Missing Coach Plan screen")

        let resistanceBands = app.staticTexts["Bands Only"].firstMatch
        let scrollView = app.scrollViews.firstMatch
        for _ in 0..<6 where !resistanceBands.isHittable {
            XCTAssertTrue(scrollView.waitForExistence(timeout: 2), "Missing Coach Plan scroll view")
            scrollView.swipeUp()
        }
        XCTAssertTrue(resistanceBands.isHittable, "Missing visible Bands Only option")
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

    private func scrollToElement(_ element: XCUIElement, in scrollView: XCUIElement, maxSwipes: Int = 8) -> Bool {
        if element.waitForExistence(timeout: 5), element.isHittable {
            return true
        }

        guard scrollView.waitForExistence(timeout: 5) else {
            return element.exists
        }

        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable {
                return true
            }
            scrollView.swipeUp()
        }

        return element.exists
    }
}
