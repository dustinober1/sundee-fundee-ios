import CloudKit
import Foundation
import Testing
@testable import SundeeFundeeKit

// MARK: - GuestDataMigratorTests

struct GuestDataMigratorTests {

    // MARK: - Fixtures

    private func seedSource(_ client: MockCloudKitClient) async throws {
        let workout = Workout(
            id: "w1",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            name: "Squat Day",
            exercises: [],
            notes: nil,
            duration: 45,
            completedAt: Date(timeIntervalSince1970: 1_700_003_600)
        )
        try await client.save([workout], recordType: "Workout")

        let challenge = Challenge(
            id: "c1",
            type: .lifetimeVolume,
            title: "Lifetime Volume",
            tiers: [],
            challengeStartDate: Date(timeIntervalSince1970: 1_700_000_000),
            challengeEndDate: nil,
            dateCreated: Date(timeIntervalSince1970: 1_700_000_000)
        )
        try await client.save([challenge], recordType: "Challenge")

        let injury = Injury(
            id: "i1",
            locationIds: "shoulder_left",
            name: "Left shoulder strain",
            recoveryPhase: .acute,
            dateCreated: Date(timeIntervalSince1970: 1_700_000_000),
            phaseUpdated: Date(timeIntervalSince1970: 1_700_000_000),
            notes: nil
        )
        try await client.save([injury], recordType: "Injury")

        let orm = OneRepMaxRecord(
            id: "orm1",
            exerciseName: "Back Squat",
            weight: 225,
            unit: .lbs,
            date: Date(timeIntervalSince1970: 1_700_000_000)
        )
        try await client.save([orm], recordType: "OneRepMaxRecord")

        let benchmark = BenchmarkResult(
            id: "b1",
            benchmarkId: "fran",
            benchmarkName: "Fran",
            score: 180,
            notes: nil,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            cyclePhase: nil
        )
        try await client.save([benchmark], recordType: "BenchmarkResult")

        let program = EnrolledProgramRecord(id: "p1", name: "5/3/1", isActive: true)
        try await client.save([program], recordType: "EnrolledProgram")

        let settings = UserSettingsRecord(
            cycleTrackingEnabled: true,
            weightUnit: "lbs",
            experienceLevel: "intermediate",
            primaryGoal: "strength"
        )
        try await client.save([settings], recordType: "UserSettings")

        let celebration = CelebrationEventRecord(
            id: "ce1",
            description: "PR!",
            date: Date(timeIntervalSince1970: 1_700_000_000)
        )
        try await client.save([celebration], recordType: "CelebrationEventRecord")
    }

    // MARK: - Tests

    @Test("migrate copies every supported record type from source to destination")
    func testMigrateCopiesAllRecordTypes() async throws {
        let source = MockCloudKitClient()
        let destination = MockCloudKitClient()
        try await seedSource(source)

        let migrator = GuestDataMigrator(source: source, destination: destination)
        let result = try await migrator.migrate()

        #expect(result.workoutsMigrated == 1)
        #expect(result.challengesMigrated == 1)
        #expect(result.injuriesMigrated == 1)
        #expect(result.oneRepMaxesMigrated == 1)
        #expect(result.benchmarkResultsMigrated == 1)
        #expect(result.enrolledProgramsMigrated == 1)
        #expect(result.settingsMigrated == 1)
        #expect(result.celebrationsMigrated == 1)
        #expect(result.totalCount == 8)

        #expect(destination.recordCount(for: "Workout") == 1)
        #expect(destination.recordCount(for: "Challenge") == 1)
        #expect(destination.recordCount(for: "Injury") == 1)
        #expect(destination.recordCount(for: "OneRepMaxRecord") == 1)
        #expect(destination.recordCount(for: "BenchmarkResult") == 1)
        #expect(destination.recordCount(for: "EnrolledProgram") == 1)
        #expect(destination.recordCount(for: "UserSettings") == 1)
        #expect(destination.recordCount(for: "CelebrationEventRecord") == 1)
    }

    @Test("migrate clears source after successful migration")
    func testMigrateClearsSourceOnSuccess() async throws {
        let source = MockCloudKitClient()
        let destination = MockCloudKitClient()
        try await seedSource(source)

        let migrator = GuestDataMigrator(source: source, destination: destination)
        _ = try await migrator.migrate()

        #expect(source.recordCount(for: "Workout") == 0)
        #expect(source.recordCount(for: "Challenge") == 0)
        #expect(source.recordCount(for: "Injury") == 0)
        #expect(source.recordCount(for: "OneRepMaxRecord") == 0)
        #expect(source.recordCount(for: "BenchmarkResult") == 0)
        #expect(source.recordCount(for: "EnrolledProgram") == 0)
        #expect(source.recordCount(for: "UserSettings") == 0)
        #expect(source.recordCount(for: "CelebrationEventRecord") == 0)
    }

    @Test("migrate throws and does not clear source when destination save fails")
    func testMigrateFailsAtomicallyWhenDestinationSaveThrows() async throws {
        let source = MockCloudKitClient()
        let destination = FailingSaveClient()
        try await seedSource(source)

        let sourceWorkoutsBefore = source.recordCount(for: "Workout")
        let sourceSettingsBefore = source.recordCount(for: "UserSettings")
        #expect(sourceWorkoutsBefore == 1)
        #expect(sourceSettingsBefore == 1)

        let migrator = GuestDataMigrator(source: source, destination: destination)

        var didThrow = false
        do {
            _ = try await migrator.migrate()
        } catch {
            didThrow = true
        }
        #expect(didThrow)

        // Source must be untouched
        #expect(source.recordCount(for: "Workout") == sourceWorkoutsBefore)
        #expect(source.recordCount(for: "Challenge") == 1)
        #expect(source.recordCount(for: "Injury") == 1)
        #expect(source.recordCount(for: "OneRepMaxRecord") == 1)
        #expect(source.recordCount(for: "BenchmarkResult") == 1)
        #expect(source.recordCount(for: "EnrolledProgram") == 1)
        #expect(source.recordCount(for: "UserSettings") == sourceSettingsBefore)
        #expect(source.recordCount(for: "CelebrationEventRecord") == 1)
    }

    @Test("migrate returns zero counts and does not throw on empty source")
    func testMigrateEmptySource() async throws {
        let source = MockCloudKitClient()
        let destination = MockCloudKitClient()

        let migrator = GuestDataMigrator(source: source, destination: destination)
        let result = try await migrator.migrate()

        #expect(result.totalCount == 0)
        #expect(result == GuestMigrationResult())

        // Destination was never written to
        #expect(destination.recordCount(for: "Workout") == 0)
        #expect(destination.recordCount(for: "UserSettings") == 0)
    }
}

// MARK: - FailingSaveClient

/// Test-only client whose `save` always throws. Used to verify the
/// migrator does not clear the source when a destination write fails.
private final class FailingSaveClient: DataClientProtocol, @unchecked Sendable {
    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        []
    }

    func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        throw DataError.networkError(underlying: nil)
    }

    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws {
        // no-op
    }

    func deleteAllData() async throws {
        // no-op
    }
}
