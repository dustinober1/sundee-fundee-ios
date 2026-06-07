import XCTest
@_spi(Testing) @testable import SundeeFundeeKit

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
final class ProgramsListViewModelTests: XCTestCase {

    func testEnrollInProgram_SavesRecord() async {
        let mockDataClient = MockCloudKitClient()
        let viewModel = await ProgramsListViewModel(
            dataClient: mockDataClient,
            contentClient: MockContentClient()
        )

        await viewModel.loadPrograms()
        let programs = await viewModel.programs
        XCTAssertFalse(programs.isEmpty, "Need at least one program to test enrollment")

        let programId = programs.first!.id
        await viewModel.enrollInProgram(programId)

        let errorMessage = await viewModel.errorMessage
        XCTAssertNil(errorMessage)

        let enrolled: [EnrolledProgramRecord] = try! await mockDataClient.fetch(
            recordType: "EnrolledProgramRecord",
            predicate: NSPredicate(value: true),
            sortDescriptors: nil
        )
        XCTAssertEqual(enrolled.count, 1)
        XCTAssertEqual(enrolled.first?.id, programId)
        XCTAssertEqual(enrolled.first?.isActive, true)
    }

    func testReEnrollInProgram_UpdatesRecordWithoutDuplicate() async {
        let mockDataClient = MockCloudKitClient()
        let viewModel = await ProgramsListViewModel(
            dataClient: mockDataClient,
            contentClient: MockContentClient()
        )

        await viewModel.loadPrograms()
        let programId = await viewModel.programs.first!.id

        await viewModel.enrollInProgram(programId)
        var errorMessage = await viewModel.errorMessage
        XCTAssertNil(errorMessage)

        await viewModel.enrollInProgram(programId)
        errorMessage = await viewModel.errorMessage
        XCTAssertNil(errorMessage)

        let enrolled: [EnrolledProgramRecord] = try! await mockDataClient.fetch(
            recordType: "EnrolledProgramRecord",
            predicate: NSPredicate(value: true),
            sortDescriptors: nil
        )
        XCTAssertEqual(enrolled.count, 1)
        XCTAssertEqual(enrolled.first?.isActive, true)
    }

    func testEnrollInMultiplePrograms_CreatesSeparateRecords() async {
        let mockDataClient = MockCloudKitClient()
        let viewModel = await ProgramsListViewModel(
            dataClient: mockDataClient,
            contentClient: MockContentClient()
        )

        await viewModel.loadPrograms()
        let programs = await viewModel.programs
        guard programs.count >= 2 else {
            XCTFail("Need at least 2 programs to test")
            return
        }

        await viewModel.enrollInProgram(programs[0].id)
        await viewModel.enrollInProgram(programs[1].id)

        let enrolled: [EnrolledProgramRecord] = try! await mockDataClient.fetch(
            recordType: "EnrolledProgramRecord",
            predicate: NSPredicate(value: true),
            sortDescriptors: nil
        )
        XCTAssertEqual(enrolled.count, 2)
    }

    func testLegacyGenericEnrollmentDoesNotAppearInCurrentCatalog() async throws {
        let mockDataClient = MockCloudKitClient()
        try await mockDataClient.save(
            EnrolledProgramRecord(id: "template-strength", name: "Strength Basics", isActive: true),
            recordType: "EnrolledProgramRecord"
        )
        let viewModel = await ProgramsListViewModel(
            dataClient: mockDataClient,
            contentClient: MockContentClient()
        )

        await viewModel.loadPrograms()
        let programs = await viewModel.programs

        XCTAssertEqual(programs.count, ProgramTemplate.allCases.count)
        XCTAssertFalse(programs.contains { $0.id == "template-strength" })
        XCTAssertTrue(programs.allSatisfy { !$0.isEnrolled })
    }

    func testStartSessionReturnsNilWhenAnotherLaunchIsAlreadyInFlight() async {
        let viewModel = await makeProgramDetailViewModel()
        await viewModel.generateSessions()
        guard let session = await viewModel.generatedProgram?.weeks.first?.sessions.first else {
            return XCTFail("Expected generated session")
        }

        await MainActor.run {
            viewModel.startingSessionId = "already-starting"
        }

        let result = await viewModel.startSession(
            session,
            week: 1,
            programName: "Starter",
            quickEdit: nil
        )

        XCTAssertNil(result)
    }

    func testStartSessionSkipsDecisionRecordWhenNothingChanged() async throws {
        let viewModel = await makeProgramDetailViewModel()
        await viewModel.generateSessions()
        guard let session = await viewModel.generatedProgram?.weeks.first?.sessions.first else {
            return XCTFail("Expected generated session")
        }

        let result = await viewModel.startSession(
            session,
            week: 1,
            programName: "Starter",
            quickEdit: nil
        )

        XCTAssertNotNil(result?.workout)
        XCTAssertNil(result?.adaptationDecisionRecord)
    }

    func testUndoRestoresShortenedQuickEditBaseline() async throws {
        let viewModel = await makeProgramDetailViewModel()
        await viewModel.generateSessions()
        guard let session = await viewModel.generatedProgram?.weeks.first?.sessions.first else {
            return XCTFail("Expected generated session")
        }

        let result = await viewModel.startSession(
            session,
            week: 1,
            programName: "Starter",
            quickEdit: .shorten(minutes: 20)
        )
        guard let launchResult = result,
              let decisionRecord = launchResult.adaptationDecisionRecord else {
            return XCTFail("Expected quick-edit decision record")
        }

        let undoResult = WorkoutAdaptationDecisionService.undo(
            record: decisionRecord,
            currentWorkout: launchResult.workout
        )

        guard case .restored(let restoredWorkout) = undoResult else {
            return XCTFail("Expected restored workout")
        }

        XCTAssertEqual(restoredWorkout.exercises.count, 3)
        XCTAssertEqual(restoredWorkout.exercises.map(\.name), launchResult.workout.exercises.map(\.name))
        XCTAssertEqual(
            restoredWorkout.exercises.map { $0.targetSets.count },
            launchResult.workout.exercises.map { $0.targetSets.count }
        )
    }

    func testUndoRestoresReducedVolumeQuickEditBaseline() async throws {
        let viewModel = await makeProgramDetailViewModel()
        await viewModel.generateSessions()
        guard let session = await viewModel.generatedProgram?.weeks.first?.sessions.first else {
            return XCTFail("Expected generated session")
        }

        let result = await viewModel.startSession(
            session,
            week: 1,
            programName: "Starter",
            quickEdit: .reduceVolume
        )
        guard let launchResult = result,
              let decisionRecord = launchResult.adaptationDecisionRecord else {
            return XCTFail("Expected quick-edit decision record")
        }

        let undoResult = WorkoutAdaptationDecisionService.undo(
            record: decisionRecord,
            currentWorkout: launchResult.workout
        )

        guard case .restored(let restoredWorkout) = undoResult else {
            return XCTFail("Expected restored workout")
        }

        XCTAssertEqual(restoredWorkout.exercises.map(\.name), launchResult.workout.exercises.map(\.name))
        XCTAssertEqual(
            restoredWorkout.exercises.map { $0.targetSets.count },
            launchResult.workout.exercises.map { $0.targetSets.count }
        )
    }

    private func makeProgramDetailViewModel() async -> ProgramDetailViewModel {
        await ProgramDetailViewModel(
            program: ProgramListItem(
                id: "starter-program",
                name: "Starter Program",
                category: "Strength",
                description: "Test",
                durationWeeks: 4,
                sessionsPerWeek: 3,
                difficulty: "Beginner",
                isEnrolled: true,
                template: .beginnerStrength,
                printablePDFURL: nil
            ),
            dataClient: MockCloudKitClient(),
            healthClient: MockHealthKitClient()
        )
    }
}
