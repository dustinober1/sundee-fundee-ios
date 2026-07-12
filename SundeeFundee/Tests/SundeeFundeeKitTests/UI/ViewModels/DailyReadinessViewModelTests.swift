import XCTest
@testable import SundeeFundeeKit

@MainActor
final class DailyReadinessViewModelTests: XCTestCase {
    func testCurrentAssessmentPublishesContent() async {
        let assessment = makeAssessment(score: 84, confidence: .high)
        let vm = DailyReadinessViewModel(loader: StubReadinessLoader(result: DailyReadinessResult(assessment: assessment, persistence: .saved)))
        await vm.load()
        XCTAssertEqual(vm.state, .content)
        XCTAssertEqual(vm.snapshot?.totalScore, 84)
    }

    func testNoAssessmentPublishesEmpty() async {
        let vm = DailyReadinessViewModel(loader: StubReadinessLoader(result: nil))
        await vm.load()
        XCTAssertEqual(vm.state, .empty)
    }

    func testHealthDeniedLowConfidenceIsActionable() async {
        let assessment = makeAssessment(score: 62, confidence: .low)
        let vm = DailyReadinessViewModel(loader: StubReadinessLoader(result: DailyReadinessResult(assessment: assessment, persistence: .cachedOnly)))
        await vm.load()
        XCTAssertEqual(vm.snapshot?.confidence, .low)
        XCTAssertTrue(vm.guidance.contains("Health"))
    }

    func testStaleSnapshotIsMarkedStale() async {
        let assessment = makeAssessment(score: 72, confidence: .medium, date: Date(timeIntervalSinceNow: -172_800))
        let vm = DailyReadinessViewModel(loader: StubReadinessLoader(result: DailyReadinessResult(assessment: assessment, persistence: .cachedOnly)))
        await vm.load()
        XCTAssertTrue(vm.isStale)
    }

    func testRetryableErrorPublishesErrorAndRetry() async {
        let loader = StubReadinessLoader(error: TestError.failed)
        let vm = DailyReadinessViewModel(loader: loader)
        await vm.load()
        XCTAssertEqual(vm.state, .error)
        XCTAssertTrue(vm.canRetry)
    }

    func testGuestModeSkipsHealthCopy() async {
        let assessment = makeAssessment(score: 70, confidence: .medium)
        let vm = DailyReadinessViewModel(loader: StubReadinessLoader(result: DailyReadinessResult(assessment: assessment, persistence: .saved)), isGuest: true)
        await vm.load()
        XCTAssertTrue(vm.isGuest)
        XCTAssertTrue(vm.guidance.contains("device"))
    }

    private func makeAssessment(score: Int, confidence: ReadinessConfidence, date: Date = Date()) -> ReadinessAssessment {
        ReadinessAssessment(assessmentDate: date, state: ReadinessState.from(score: score), totalScore: score, confidence: confidence, subScores: [:], availableSignals: [], missingSignals: [], staleSignals: [], positiveReasons: [], cautionReasons: [], modelVersion: "test")
    }
}

private enum TestError: Error { case failed }

private actor StubReadinessLoader: DailyReadinessLoading {
    let result: DailyReadinessResult?
    let error: Error?
    init(result: DailyReadinessResult? = nil, error: Error? = nil) { self.result = result; self.error = error }
    func load(assessmentDate: Date, calendar: Calendar, cyclePhase: CyclePhase?, cycleConfidence: Double?) async throws -> DailyReadinessResult? {
        if let error { throw error }
        return result
    }
}
