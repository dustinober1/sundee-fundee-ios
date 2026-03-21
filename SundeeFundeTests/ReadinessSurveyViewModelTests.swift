import XCTest
@testable import SundeeFundee

@MainActor
final class ReadinessSurveyViewModelTests: XCTestCase {

    private func freshDefaults() -> UserDefaults {
        let name = "test-survey-vm-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testInitialSliderValues() {
        let vm = ReadinessSurveyViewModel(defaults: freshDefaults())
        XCTAssertEqual(vm.sleepQuality, 5)
        XCTAssertEqual(vm.stressLevel, 5)
        XCTAssertEqual(vm.sorenessLevel, 5)
    }

    func testLivePreviewUpdatesOnSliderChange() {
        let vm = ReadinessSurveyViewModel(defaults: freshDefaults())
        vm.sleepQuality = 9
        vm.stressLevel = 2
        vm.sorenessLevel = 2
        let preview = vm.livePreview
        XCTAssertTrue(preview.score > 7)
        XCTAssertEqual(preview.tier, .high)
    }

    func testSubmitSavesToDefaults() {
        let defaults = freshDefaults()
        let vm = ReadinessSurveyViewModel(defaults: defaults)
        vm.sleepQuality = 8
        vm.stressLevel = 3
        vm.sorenessLevel = 3
        vm.submit()
        let loaded = ReadinessSurvey.loadTodayResult(defaults: defaults)
        XCTAssertNotNil(loaded)
        XCTAssertTrue(loaded!.score > 6)
    }

    func testSubmitWithHealthKitBlending() {
        let defaults = freshDefaults()
        let vm = ReadinessSurveyViewModel(defaults: defaults, healthKitScore: 4.0)
        vm.sleepQuality = 8
        vm.stressLevel = 3
        vm.sorenessLevel = 3
        vm.submit()
        let loaded = ReadinessSurvey.loadTodayResult(defaults: defaults)
        XCTAssertNotNil(loaded)
        let pureResult = ReadinessSurvey.score(sleepQuality: 8, stressLevel: 3, sorenessLevel: 3)
        XCTAssertTrue(loaded!.score < pureResult.score)
    }

    func testAutoFillSleepFromHealthKit() {
        let vm = ReadinessSurveyViewModel(defaults: freshDefaults(), healthKitSleepHours: 7.5)
        XCTAssertEqual(vm.sleepQuality, 8)
    }

    func testReadinessTierStringForAIContext() {
        XCTAssertEqual(ReadinessSurvey.tierStringForAI(.low), "fatigued")
        XCTAssertEqual(ReadinessSurvey.tierStringForAI(.neutral), "normal")
        XCTAssertEqual(ReadinessSurvey.tierStringForAI(.high), "prime")
        XCTAssertNil(ReadinessSurvey.todayTierStringForAI(defaults: freshDefaults()))
    }

    func testHasExistingScoreToday() {
        let defaults = freshDefaults()
        XCTAssertFalse(ReadinessSurveyViewModel.hasScoreToday(defaults: defaults))
        let result = ReadinessResult(score: 5.0, tier: .neutral)
        ReadinessSurvey.saveTodayResult(result, defaults: defaults)
        XCTAssertTrue(ReadinessSurveyViewModel.hasScoreToday(defaults: defaults))
    }
}
