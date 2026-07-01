import XCTest
@testable import SundeeFundeeKit

@MainActor
final class WorkoutCompletionCheckInViewModelTests: XCTestCase {
    func testSubmitSavesCheckInAndTracksEvent() async throws {
        let client = MockCloudKitClient()
        let viewModel = WorkoutCompletionCheckInViewModel(workoutID: "workout-1", dataClient: client)
        viewModel.sessionRPE = 8
        viewModel.soreness = 4
        viewModel.pain = 2
        viewModel.wasRightForToday = true

        await viewModel.submit()

        let records: [WorkoutCompletionCheckInRecord] = try await client.fetchAll(recordType: "WorkoutCompletionCheckIn")
        XCTAssertEqual(records.first?.workoutID, "workout-1")
        XCTAssertEqual(records.first?.sessionRPE, 8)
        XCTAssertEqual(records.first?.soreness, 4)
        XCTAssertEqual(records.first?.pain, 2)
        XCTAssertEqual(records.first?.wasRightForToday, true)
    }
}
