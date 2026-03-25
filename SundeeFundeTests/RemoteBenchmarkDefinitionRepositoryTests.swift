import Testing
import Foundation
import CloudKit
@testable import SundeeFundee

@Suite("BundledBenchmarkDefinitionRepository")
struct BundledBenchmarkDefinitionRepositoryTests {

    @Test func fetchesFromBundledJSON() async throws {
        let repo = BundledBenchmarkDefinitionRepository()
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(!defs.isEmpty)
        #expect(defs.allSatisfy { $0.category == "Sundee Fundee" })
        #expect(defs.allSatisfy { $0.isPredefined == true })
        #expect(defs.allSatisfy { $0.userID == "" })
    }

    @Test func returnsEmptyForMissingBundle() async throws {
        let repo = BundledBenchmarkDefinitionRepository(bundle: .main, resourceName: "nonexistent")
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(defs.isEmpty)
    }

    @Test func cachesResults() async throws {
        let repo = BundledBenchmarkDefinitionRepository()
        let first = try await repo.fetchBenchmarkDefinitions()
        let second = try await repo.fetchBenchmarkDefinitions()
        #expect(first.count == second.count)
    }
}

@Suite("CloudKitBenchmarkDefinitionRepository")
struct CloudKitBenchmarkDefinitionRepositoryTests {

    @Test func fetchesFromCloudKit() async throws {
        let repo = CloudKitBenchmarkDefinitionRepository(
            fallback: BundledBenchmarkDefinitionRepository(bundle: .main, resourceName: "nonexistent"),
            cloudFetcher: {
                [BenchmarkDefinition(
                    id: "ck-1", userID: "", name: "CloudKit Bench",
                    category: "Sundee Fundee", workoutDescription: "Test",
                    scoringType: .time, isPredefined: true, sortOrder: 1
                )]
            }
        )
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(defs.count == 1)
        #expect(defs[0].name == "CloudKit Bench")
    }

    @Test func fallsBackWhenCloudKitFails() async throws {
        let repo = CloudKitBenchmarkDefinitionRepository(
            fallback: BundledBenchmarkDefinitionRepository(),
            cloudFetcher: { throw CKError(.networkUnavailable) }
        )
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(!defs.isEmpty)
    }

    @Test func fallsBackWhenCloudKitReturnsEmpty() async throws {
        let repo = CloudKitBenchmarkDefinitionRepository(
            fallback: BundledBenchmarkDefinitionRepository(),
            cloudFetcher: { [] }
        )
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(!defs.isEmpty)
    }

    @Test func decodesCloudKitRecords() async throws {
        let recordID = CKRecord.ID(recordName: "bench-1")
        let record = CKRecord(recordType: "BenchmarkDefinition", recordID: recordID)
        record["id"] = "bench-1" as CKRecordValue
        record["name"] = "Test WOD" as CKRecordValue
        record["category"] = "Sundee Fundee" as CKRecordValue
        record["workoutDescription"] = "Do stuff" as CKRecordValue
        record["scoringTypeRaw"] = "time" as CKRecordValue
        record["sortOrder"] = Int64(1) as CKRecordValue

        let repo = CloudKitBenchmarkDefinitionRepository(
            fallback: BundledBenchmarkDefinitionRepository(bundle: .main, resourceName: "nonexistent"),
            cloudRecordFetcher: { _ in [(recordID, .success(record))] }
        )
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(defs.count == 1)
        #expect(defs[0].name == "Test WOD")
        #expect(defs[0].scoringTypeRaw == "time")
        #expect(defs[0].isPredefined == true)
    }

    @Test func skipsInvalidCloudKitRecords() async throws {
        let goodID = CKRecord.ID(recordName: "bench-good")
        let good = CKRecord(recordType: "BenchmarkDefinition", recordID: goodID)
        good["id"] = "bench-good" as CKRecordValue
        good["name"] = "Good" as CKRecordValue
        good["category"] = "Sundee Fundee" as CKRecordValue
        good["workoutDescription"] = "OK" as CKRecordValue
        good["scoringTypeRaw"] = "reps" as CKRecordValue
        good["sortOrder"] = Int64(1) as CKRecordValue

        let badID = CKRecord.ID(recordName: "bench-bad")
        let bad = CKRecord(recordType: "BenchmarkDefinition", recordID: badID)
        // Missing required fields

        let repo = CloudKitBenchmarkDefinitionRepository(
            fallback: BundledBenchmarkDefinitionRepository(bundle: .main, resourceName: "nonexistent"),
            cloudRecordFetcher: { _ in [(goodID, .success(good)), (badID, .success(bad))] }
        )
        let defs = try await repo.fetchBenchmarkDefinitions()
        #expect(defs.count == 1)
        #expect(defs[0].name == "Good")
    }
}
