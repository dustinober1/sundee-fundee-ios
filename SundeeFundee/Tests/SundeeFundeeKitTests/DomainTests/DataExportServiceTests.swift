import Foundation
import Testing
@testable import SundeeFundeeKit

// MARK: - DataExportServiceTests

@Suite("DataExportService")
struct DataExportServiceTests {

    // MARK: - Helper: Seeded Mock

    /// Creates a `MockCloudKitClient` seeded with one record of each type.
    private func seedAllTypes(_ client: MockCloudKitClient) async throws {
        let workout = Workout(
            id: "w1",
            date: Date(),
            name: "Test WOD",
            exercises: [],
            duration: 15
        )
        try await client.save([workout], recordType: "Workout")

        let orm = OneRepMaxRecord(
            id: "orm1",
            exerciseName: "Back Squat",
            weight: 225,
            unit: .lbs,
            date: Date()
        )
        try await client.save([orm], recordType: "OneRepMaxRecord")

        let completed = CompletedWorkoutRecord(
            id: "cw1",
            name: "Fran",
            date: Date(),
            duration: 180,
            exerciseNames: ["Thruster", "Pull-Up"],
            isComplete: true
        )
        try await client.save([completed], recordType: "CompletedWorkoutRecord")

        let phase = CyclePhaseInfo(
            phase: .follicular,
            confidence: 0.9,
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 7)
        )
        try await client.save([phase], recordType: "CyclePhaseInfo")

        let settings = CycleSettingsRecord(
            averageCycleLengthDays: 28,
            lastPeriodStart: Date()
        )
        try await client.save([settings], recordType: "CycleSettings")

        let benchmark = BenchmarkResult(
            id: "br1",
            benchmarkId: "bench-1",
            benchmarkName: "Fran",
            score: 180,
            date: Date()
        )
        try await client.save([benchmark], recordType: "BenchmarkResult")

        let injury = Injury(
            id: "inj1",
            locationIds: "knee",
            name: "Patellar Tendinitis",
            recoveryPhase: .acute,
            dateCreated: Date(),
            phaseUpdated: Date()
        )
        try await client.save([injury], recordType: "Injury")

        let painLog = DailyPainLog(
            id: "pl1",
            locationIds: "knee",
            intensity: 3,
            painType: .dull,
            date: Date()
        )
        try await client.save([painLog], recordType: "DailyPainLog")

        let celebration = CelebrationEventRecord(
            id: "ce1",
            description: "First muscle-up!",
            date: Date()
        )
        try await client.save([celebration], recordType: "CelebrationEventRecord")

        let program = EnrolledProgramRecord(
            id: "ep1",
            name: "Starting Strength",
            isActive: true
        )
        try await client.save([program], recordType: "EnrolledProgramRecord")
    }

    // MARK: - Tests

    @Test("Export all fetches all record types")
    func testExportAllFetchesAllRecordTypes() async throws {
        let client = MockCloudKitClient()
        try await seedAllTypes(client)

        let service = DataExportService(dataClient: client)
        let data = await service.exportAll()

        #expect(data.workouts.count == 1)
        #expect(data.oneRepMaxRecords.count == 1)
        #expect(data.completedWorkoutRecords.count == 1)
        #expect(data.cyclePhaseInfo.count == 1)
        #expect(data.cycleSettings != nil)
        #expect(data.benchmarkResults.count == 1)
        #expect(data.injuries.count == 1)
        #expect(data.painLogs.count == 1)
        #expect(data.celebrations.count == 1)
        #expect(data.enrolledPrograms.count == 1)
    }

    @Test("Export with empty data returns empty arrays and no crash")
    func testExportAllWithEmptyData() async {
        let client = MockCloudKitClient()
        let service = DataExportService(dataClient: client)

        let data = await service.exportAll()

        #expect(data.workouts.isEmpty)
        #expect(data.oneRepMaxRecords.isEmpty)
        #expect(data.completedWorkoutRecords.isEmpty)
        #expect(data.cyclePhaseInfo.isEmpty)
        #expect(data.cycleSettings == nil)
        #expect(data.benchmarkResults.isEmpty)
        #expect(data.injuries.isEmpty)
        #expect(data.painLogs.isEmpty)
        #expect(data.celebrations.isEmpty)
        #expect(data.enrolledPrograms.isEmpty)
    }

    @Test("Export tolerates partial failures — seeded types appear, unseeded are empty")
    func testExportAllToleratesPartialFailures() async throws {
        let client = MockCloudKitClient()

        // Only seed workouts and injuries
        let workout = Workout(id: "w1", date: Date(), name: "Partial", exercises: [], duration: 10)
        try await client.save([workout], recordType: "Workout")

        let injury = Injury(
            id: "inj1",
            locationIds: "shoulder",
            name: "Rotator cuff",
            recoveryPhase: .rehab,
            dateCreated: Date(),
            phaseUpdated: Date()
        )
        try await client.save([injury], recordType: "Injury")

        let service = DataExportService(dataClient: client)
        let data = await service.exportAll()

        // Seeded types should have data
        #expect(data.workouts.count == 1)
        #expect(data.injuries.count == 1)

        // Unseeded types should be empty (not crash)
        #expect(data.oneRepMaxRecords.isEmpty)
        #expect(data.completedWorkoutRecords.isEmpty)
        #expect(data.cyclePhaseInfo.isEmpty)
        #expect(data.benchmarkResults.isEmpty)
        #expect(data.painLogs.isEmpty)
        #expect(data.celebrations.isEmpty)
        #expect(data.enrolledPrograms.isEmpty)
        #expect(data.cycleSettings == nil)
    }

    @Test("Encode produces valid JSON that parses as a dictionary")
    func testEncodeProducesValidJSON() throws {
        let client = MockCloudKitClient()
        let service = DataExportService(dataClient: client)
        let data = ExportedData.current()

        let jsonData = try service.encode(data)

        // Should parse as a JSON object (dictionary)
        let parsed = try JSONSerialization.jsonObject(with: jsonData)
        #expect(parsed is [String: Any])
    }

    @Test("Encoded JSON contains all expected top-level keys")
    func testEncodedJSONContainsExpectedKeys() throws {
        let client = MockCloudKitClient()
        let service = DataExportService(dataClient: client)
        let data = ExportedData.current()

        let jsonData = try service.encode(data)
        let parsed = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Non-optional keys are always present; cycleSettings is omitted when nil.
        let alwaysPresentKeys: Set<String> = [
            "appVersion",
            "benchmarkResults",
            "celebrations",
            "completedWorkoutRecords",
            "cyclePhaseInfo",
            "enrolledPrograms",
            "exportDate",
            "injuries",
            "oneRepMaxRecords",
            "painLogs",
            "workouts",
        ]
        #expect(alwaysPresentKeys.isSubset(of: parsed.keys))
    }

    @Test("JSON structure with multiple records — 3 workouts")
    func testJSONStructureWithMultipleRecords() async throws {
        let client = MockCloudKitClient()

        // Seed 3 workouts
        for i in 1...3 {
            let workout = Workout(
                id: "w\(i)",
                date: Date(),
                name: "WOD \(i)",
                exercises: [],
                duration: 10 * i
            )
            try await client.save([workout], recordType: "Workout")
        }

        let service = DataExportService(dataClient: client)
        let exported = await service.exportAll()

        #expect(exported.workouts.count == 3)

        let jsonData = try service.encode(exported)
        let parsed = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        let workoutsArray = parsed["workouts"] as! [[String: Any]]
        #expect(workoutsArray.count == 3)
    }
}
