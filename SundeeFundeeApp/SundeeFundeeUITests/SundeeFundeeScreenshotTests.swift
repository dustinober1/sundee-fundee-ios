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
        snapshot("01_today_decision")

        captureCoachPlanBenefit()
        captureProgramAdaptationSurface()
        captureDataTrustCenter()
        capture(tab: "Cycle", title: "Cycle", name: "02_recovery_pain_energy")
        capture(tab: "Progress", title: "Progress", name: "03_progress_lifting")
        captureProgramsHub()
        captureWorkoutHistory()
        captureEquipmentConversionAndSwapSurface()
    }

    func testRussianSquatProgramAndVanessaBenchmark() {
        app.launchArguments += ["--seed-screenshots"]
        setupSnapshot(app)
        app.launch()

        XCTAssertTrue(waitForScreen(title: "Today", timeout: 20), "Missing Today screen")

        let programsRow = openProgramsFromTrain()
        XCTAssertTrue(programsRow, "Missing Programs screen")

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
        let trainButton = tabButton(named: "Train")
        XCTAssertTrue(trainButton.waitForExistence(timeout: 10), "Missing Train tab")
        trainButton.tap()
        XCTAssertTrue(waitForScreen(title: "Train", timeout: 10), "Missing Train screen")

        let button = app.buttons["Build Coach Plan"].firstMatch
        XCTAssertTrue(
            scrollToElement(button, in: app.tables.firstMatch),
            "Missing Build Coach Plan entry point"
        )
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
        XCTAssertTrue(waitForScreen(title: "Train", timeout: 10), "Did not return to Train screen")

        let todayButton = tabButton(named: "Today")
        XCTAssertTrue(todayButton.waitForExistence(timeout: 10), "Missing Today tab")
        todayButton.tap()
        XCTAssertTrue(waitForScreen(title: "Today", timeout: 10), "Did not return to Today screen")
    }

    private func captureProgramAdaptationSurface() {
        guard openProgramsFromTrain() else { return }

        let viewProgram = app.buttons["View Program"].firstMatch
        if viewProgram.waitForExistence(timeout: 5) {
            viewProgram.tap()
            if waitForScreen(title: "Russian Squat", timeout: 10) || app.staticTexts["Week 1"].firstMatch.waitForExistence(timeout: 5) {
                snapshot("06_program_adaptation")
            }
        }

        _ = returnToTrainRoot()
    }

    private func captureDataTrustCenter() {
        let todayButton = tabButton(named: "Today")
        guard todayButton.waitForExistence(timeout: 10) else { return }
        todayButton.tap()
        guard waitForScreen(title: "Today", timeout: 10) else { return }

        let settingsButton = app.buttons["Settings"].firstMatch
        guard settingsButton.waitForExistence(timeout: 5) else { return }
        settingsButton.tap()
        guard waitForScreen(title: "Settings", timeout: 10) else { return }

        let supportDeveloper = app.staticTexts["Support the Developer"].firstMatch
        XCTAssertTrue(
            scrollToElement(supportDeveloper, in: app.tables.firstMatch),
            "Missing Support the Developer row in Settings"
        )

        let trustCenter = app.staticTexts["Data Trust Center"].firstMatch
        if scrollToElement(trustCenter, in: app.tables.firstMatch), trustCenter.isHittable {
            trustCenter.tap()
            if waitForScreen(title: "Data Trust Center", timeout: 10) {
                snapshot("07_data_trust_center")
            }
        }
    }

    private func captureEquipmentConversionAndSwapSurface() {
        guard openProgramsFromTrain() else { return }

        let viewProgram = app.buttons["View Program"].firstMatch
        guard viewProgram.waitForExistence(timeout: 5) else { return }
        viewProgram.tap()
        guard waitForScreen(title: "Russian Squat", timeout: 10) || app.staticTexts["Week 1"].firstMatch.waitForExistence(timeout: 5) else {
            return
        }

        let startSession = app.buttons["Start Session"].firstMatch
        guard startSession.waitForExistence(timeout: 5) else { return }
        startSession.tap()

        let workoutOptions = app.buttons["Workout options"].firstMatch
        guard workoutOptions.waitForExistence(timeout: 10) else { return }

        workoutOptions.tap()
        let convertEquipment = app.buttons["Convert Equipment"].firstMatch
        if convertEquipment.waitForExistence(timeout: 5) {
            convertEquipment.tap()
            let bandsOnly = app.buttons["Bands Only"].firstMatch
            if bandsOnly.waitForExistence(timeout: 5) {
                bandsOnly.tap()
                if app.staticTexts["Equipment Conversion Applied"].firstMatch.waitForExistence(timeout: 5) {
                    snapshot("08_equipment_conversion")
                }
            }
        }

        let exerciseOptions = app.buttons["Exercise options"].firstMatch
        if exerciseOptions.waitForExistence(timeout: 5) {
            exerciseOptions.tap()
            let swapExercise = app.buttons["Swap exercise"].firstMatch
            if swapExercise.waitForExistence(timeout: 5) {
                swapExercise.tap()
                if app.staticTexts["Swap Exercise"].firstMatch.waitForExistence(timeout: 5) ||
                    app.buttons["Cancel"].firstMatch.waitForExistence(timeout: 5) {
                    snapshot("09_pain_swap_surface")
                }
            }
        }

        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.waitForExistence(timeout: 2) {
            cancel.tap()
        }

        let close = app.buttons["Close"].firstMatch
        if close.waitForExistence(timeout: 3) {
            close.tap()
            let abandon = app.buttons["Abandon"].firstMatch
            if abandon.waitForExistence(timeout: 3) {
                abandon.tap()
            } else {
                let keepGoing = app.buttons["Keep Going"].firstMatch
                if keepGoing.waitForExistence(timeout: 3) {
                    keepGoing.tap()
                }
            }
        }
    }

    private func capture(tab: String, title: String, name: String) {
        let button = tabButton(named: tab)
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing \(tab) tab")
        button.tap()

        XCTAssertTrue(waitForScreen(title: title, timeout: 10), "Missing \(title) screen")
        snapshot(name)
    }

    private func captureProgramsHub() {
        XCTAssertTrue(openProgramsFromTrain(), "Missing Programs screen")
        snapshot("04_programs")
        _ = returnToTrainRoot()
    }

    private func captureWorkoutHistory() {
        XCTAssertTrue(returnToTrainRoot(), "Missing Train screen")

        let workoutHistory = app.staticTexts["Workout History"].firstMatch
        XCTAssertTrue(
            scrollToElement(workoutHistory, in: app.tables.firstMatch),
            "Missing Workout History row"
        )
        workoutHistory.tap()
        XCTAssertTrue(waitForScreen(title: "Workouts", timeout: 10), "Missing Workouts screen")
        snapshot("05_workouts")
    }

    private func openProgramsFromTrain() -> Bool {
        guard returnToTrainRoot() else { return false }

        let programsRow = app.staticTexts["Programs"].firstMatch
        guard scrollToElement(programsRow, in: app.tables.firstMatch) else { return false }
        programsRow.tap()
        return waitForScreen(title: "Programs", timeout: 10)
    }

    private func returnToTrainRoot() -> Bool {
        let trainButton = tabButton(named: "Train")
        guard trainButton.waitForExistence(timeout: 10) else { return false }
        trainButton.tap()

        if waitForScreen(title: "Train", timeout: 5) {
            return true
        }

        let backTargets = ["Programs", "Train"]
        for title in backTargets {
            let backButton = app.navigationBars.buttons[title].firstMatch
            if backButton.waitForExistence(timeout: 2) {
                backButton.tap()
                if waitForScreen(title: "Train", timeout: 5) {
                    return true
                }
            }
        }

        return waitForScreen(title: "Train", timeout: 5)
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

        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable {
                return true
            }
            scrollView.swipeDown()
        }

        return element.exists
    }
}
