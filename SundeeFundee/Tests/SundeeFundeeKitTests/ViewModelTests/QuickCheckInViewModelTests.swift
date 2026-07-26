import XCTest
@testable import SundeeFundeeKit

@MainActor
final class QuickCheckInViewModelTests: XCTestCase {
    func testSaveSymptomOnlyCheckIn() async {
        let dataClient = MockCloudKitClient()
        let viewModel = QuickCheckInViewModel(dataClient: dataClient)
        let completionExpectation = expectation(
            forNotification: .dailyCheckInCompleted,
            object: nil
        )
        viewModel.energy = 7
        viewModel.fatigue = 3
        viewModel.soreness = 4
        viewModel.cramps = 1

        await viewModel.save()

        XCTAssertNil(viewModel.errorMessage)
        await fulfillment(of: [completionExpectation], timeout: 0.1)
        XCTAssertEqual(dataClient.recordCount(for: "SymptomCheckInRecord"), 1)
        XCTAssertEqual(dataClient.recordCount(for: "DailyPainLog"), 0)
        XCTAssertEqual(dataClient.recordCount(for: "PeriodLogRecord"), 0)
    }

    func testSavePainAndPeriodCheckIn() async {
        let dataClient = MockCloudKitClient()
        let viewModel = QuickCheckInViewModel(dataClient: dataClient)
        viewModel.energy = 5
        viewModel.fatigue = 6
        viewModel.soreness = 5
        viewModel.cramps = 4
        viewModel.hasPain = true
        viewModel.painIntensity = 6
        viewModel.painType = .soreness
        viewModel.isPeriodActive = true

        await viewModel.save()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(dataClient.recordCount(for: "SymptomCheckInRecord"), 1)
        XCTAssertEqual(dataClient.recordCount(for: "DailyPainLog"), 1)
        XCTAssertEqual(dataClient.recordCount(for: "PeriodLogRecord"), 1)
    }
}
