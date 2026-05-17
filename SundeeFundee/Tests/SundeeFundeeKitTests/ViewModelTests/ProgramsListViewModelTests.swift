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
}
