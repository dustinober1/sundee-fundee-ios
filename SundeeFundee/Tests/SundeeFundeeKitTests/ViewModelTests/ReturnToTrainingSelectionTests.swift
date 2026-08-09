import XCTest
@_spi(Testing) @testable import SundeeFundeeKit

/// Tests for the return-to-training entry point on the Programs tab.
///
/// This block is not part of the printable catalog the content client serves,
/// so it is held separately on the view model rather than in `programs`. These
/// tests pin that separation as well as the enrollment path.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
final class ReturnToTrainingSelectionTests: XCTestCase {

    private func makeViewModel(
        dataClient: MockCloudKitClient = MockCloudKitClient()
    ) async -> ProgramsListViewModel {
        await ProgramsListViewModel(
            dataClient: dataClient,
            contentClient: MockContentClient()
        )
    }

    // MARK: - Preview

    func testDefaultReason_IsTheNeutralOne() async {
        let viewModel = await makeViewModel()
        let reason = await viewModel.returnToTrainingReason

        XCTAssertEqual(reason, .extendedTimeOff,
                       "The default should not presume a personal circumstance")
    }

    func testPreview_TracksTheSelectedReason() async {
        let viewModel = await makeViewModel()

        await MainActor.run { viewModel.returnToTrainingReason = .postpartum }
        let postpartumWeeks = await viewModel.returnToTrainingPreview.durationWeeks

        await MainActor.run { viewModel.returnToTrainingReason = .extendedTimeOff }
        let timeOffWeeks = await viewModel.returnToTrainingPreview.durationWeeks

        XCTAssertGreaterThan(postpartumWeeks, timeOffWeeks,
                             "Changing the reason should change the plan the user is shown")
    }

    func testWeeklyPlan_MatchesThePreviewLength() async {
        let viewModel = await makeViewModel()

        for reason in TrainingBreakReason.allCases {
            await MainActor.run { viewModel.returnToTrainingReason = reason }
            let weeks = await viewModel.returnToTrainingWeeks
            let duration = await viewModel.returnToTrainingPreview.durationWeeks

            XCTAssertEqual(weeks.count, duration,
                           "\(reason.rawValue): the week list and the stated length must agree")
        }
    }

    // MARK: - Catalog Separation

    func testReturnToTraining_IsNotListedAmongCatalogPrograms() async {
        let viewModel = await makeViewModel()
        await viewModel.loadPrograms()
        let programs = await viewModel.programs

        XCTAssertFalse(programs.contains { $0.id == returnToTrainingProgramID },
                       "The generated block must not appear in the printable catalog list")
    }

    // MARK: - Enrollment

    func testEnroll_SavesAnActiveRecord() async throws {
        let mockDataClient = MockCloudKitClient()
        let viewModel = await makeViewModel(dataClient: mockDataClient)

        await viewModel.loadPrograms()
        await MainActor.run { viewModel.returnToTrainingReason = .illness }
        await viewModel.enrollInReturnToTraining()

        let errorMessage = await viewModel.errorMessage
        XCTAssertNil(errorMessage)

        let enrolled: [EnrolledProgramRecord] = try await mockDataClient.fetch(
            recordType: "EnrolledProgramRecord",
            predicate: NSPredicate(value: true),
            sortDescriptors: nil
        )
        XCTAssertEqual(enrolled.count, 1)
        XCTAssertEqual(enrolled.first?.id, returnToTrainingProgramID)
        XCTAssertEqual(enrolled.first?.name, "Return to Training")
        XCTAssertEqual(enrolled.first?.isActive, true)
    }

    func testEnroll_MarksTheProgramAsEnrolled() async {
        let viewModel = await makeViewModel()

        var isEnrolled = await viewModel.isReturnToTrainingEnrolled
        XCTAssertFalse(isEnrolled)

        await viewModel.enrollInReturnToTraining()

        isEnrolled = await viewModel.isReturnToTrainingEnrolled
        XCTAssertTrue(isEnrolled)
    }

    func testEnroll_ClearsTheInFlightFlag() async {
        let viewModel = await makeViewModel()
        await viewModel.enrollInReturnToTraining()

        let inFlight = await viewModel.isEnrollingReturnToTraining
        XCTAssertFalse(inFlight, "The spinner must not be left running after enrollment")
    }

    func testReEnroll_DoesNotDuplicateTheRecord() async throws {
        let mockDataClient = MockCloudKitClient()
        let viewModel = await makeViewModel(dataClient: mockDataClient)

        await MainActor.run { viewModel.returnToTrainingReason = .postpartum }
        await viewModel.enrollInReturnToTraining()
        await MainActor.run { viewModel.returnToTrainingReason = .illness }
        await viewModel.enrollInReturnToTraining()

        let enrolled: [EnrolledProgramRecord] = try await mockDataClient.fetch(
            recordType: "EnrolledProgramRecord",
            predicate: NSPredicate(value: true),
            sortDescriptors: nil
        )
        XCTAssertEqual(enrolled.count, 1, "Changing the reason should update, not duplicate")
    }

    func testEnrollmentSurvivesReload() async {
        let mockDataClient = MockCloudKitClient()
        let viewModel = await makeViewModel(dataClient: mockDataClient)

        await viewModel.enrollInReturnToTraining()
        await viewModel.loadPrograms()

        let isEnrolled = await viewModel.isReturnToTrainingEnrolled
        XCTAssertTrue(isEnrolled,
                      "Enrollment must survive a reload even with CloudKit index lag")
    }

    func testLoadPrograms_LeavesUnenrolledWhenNoRecordExists() async {
        let viewModel = await makeViewModel()
        await viewModel.loadPrograms()

        let isEnrolled = await viewModel.isReturnToTrainingEnrolled
        XCTAssertFalse(isEnrolled)
    }
}
