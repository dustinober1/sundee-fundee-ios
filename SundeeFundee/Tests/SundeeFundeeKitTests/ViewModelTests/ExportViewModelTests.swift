import XCTest
@testable import SundeeFundeeKit

@MainActor
final class ExportViewModelTests: XCTestCase {
    func testLoadCategoryCountsPrefillsVisibleCounts() async throws {
        let client = MockCloudKitClient()
        try await client.save(
            Workout(
                id: "w1",
                date: Date(),
                name: "Test Workout",
                exercises: []
            ),
            recordType: "Workout"
        )
        try await client.save(
            OneRepMaxRecord(
                id: "orm1",
                exerciseName: "Back Squat",
                weight: 185,
                unit: .lbs,
                date: Date()
            ),
            recordType: "OneRepMaxRecord"
        )
        try await client.save(
            CycleSettingsRecord(
                averageCycleLengthDays: 28,
                lastPeriodStart: Date()
            ),
            recordType: "CycleSettings"
        )

        let viewModel = ExportViewModel(dataClient: client)

        await viewModel.loadCategoryCountsIfNeeded()

        XCTAssertEqual(viewModel.categoryCounts["Workouts"], 1)
        XCTAssertEqual(viewModel.categoryCounts["One Rep Maxes"], 1)
        XCTAssertEqual(viewModel.categoryCounts["Cycle Settings"], 1)
        XCTAssertNil(viewModel.exportedData)
    }

    func testLoadExportDataPopulatesExportedDataAndGeneratesFile() async throws {
        let client = MockCloudKitClient()
        try await client.save(
            Workout(
                id: "w1",
                date: Date(),
                name: "Test Workout",
                exercises: []
            ),
            recordType: "Workout"
        )

        let viewModel = ExportViewModel(dataClient: client)

        await viewModel.loadExportData()

        XCTAssertNotNil(viewModel.exportedData)
        let fileURL = viewModel.generateJSONFile()
        XCTAssertNotNil(fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL?.path ?? ""))
    }
}
