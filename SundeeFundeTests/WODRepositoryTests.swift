import XCTest
import CloudKit
@testable import SundeeFundee

final class WODRepositoryTests: XCTestCase {

    // MARK: - BundledWODRepository

    func testBundledWODRepositoryLoadsFromTestBundle() async throws {
        let bundle = Bundle(for: type(of: self))
        let repo = BundledWODRepository(bundle: bundle, resourceName: "test_wods")
        // Since test bundle likely doesn't have test_wods.json, expect empty
        let wods = try await repo.fetchWODs()
        XCTAssertEqual(wods.count, 0)
    }

    func testBundledWODRepositoryCachesResults() async throws {
        let repo = BundledWODRepository(bundle: .main, resourceName: "wods")
        let first = try await repo.fetchWODs()
        let second = try await repo.fetchWODs()
        XCTAssertEqual(first.count, second.count)
    }

    func testBundledWODRepositoryReturnsEmptyForMissingResource() async throws {
        let repo = BundledWODRepository(bundle: .main, resourceName: "nonexistent")
        let wods = try await repo.fetchWODs()
        XCTAssertEqual(wods.count, 0)
    }

    // MARK: - CloudKitWODRepository

    func testCloudKitWODRepositoryFallsBackOnError() async throws {
        let fallbackWODs = [
            WOD(id: "wod-fb", date: "2026-03-01", title: "Fallback", description: "test", exercises: [])
        ]
        let fallback = InMemoryWODRepository(wods: fallbackWODs)
        let repo = CloudKitWODRepository(
            fallback: fallback,
            cloudFetcher: { throw NSError(domain: "test", code: 1) }
        )
        let wods = try await repo.fetchWODs()
        XCTAssertEqual(wods.count, 1)
        XCTAssertEqual(wods[0].id, "wod-fb")
    }

    func testCloudKitWODRepositoryUsesCloudDataWhenAvailable() async throws {
        let cloudWODs = [
            WOD(id: "wod-cloud", date: "2026-03-01", title: "Cloud", description: "test", exercises: [])
        ]
        let fallback = InMemoryWODRepository(wods: [])
        let repo = CloudKitWODRepository(
            fallback: fallback,
            cloudFetcher: { cloudWODs }
        )
        let wods = try await repo.fetchWODs()
        XCTAssertEqual(wods.count, 1)
        XCTAssertEqual(wods[0].id, "wod-cloud")
    }

    // MARK: - CKRecord decoding

    func testWODInitFromCKRecord() throws {
        let record = CKRecord(recordType: "WOD")
        record["id"] = "wod-ck" as CKRecordValue
        record["date"] = "2026-03-01" as CKRecordValue
        record["title"] = "CK WOD" as CKRecordValue
        record["description"] = "From CloudKit" as CKRecordValue

        let exercisesJSON = """
        [{"exercise":"Squat","variant":null,"sets":3,"reps":5,"percent1RM":0.80,"restMinutes":3,"notes":null,"bodyweightOnly":false}]
        """
        record["exercisesJSON"] = exercisesJSON as CKRecordValue

        let wod = try WOD(record: record)
        XCTAssertEqual(wod.id, "wod-ck")
        XCTAssertEqual(wod.date, "2026-03-01")
        XCTAssertEqual(wod.title, "CK WOD")
        XCTAssertEqual(wod.exercises.count, 1)
        XCTAssertEqual(wod.exercises[0].exercise, "Squat")
    }

    func testWODInitFromCKRecordThrowsOnMissingFields() {
        let record = CKRecord(recordType: "WOD")
        record["id"] = "wod-bad" as CKRecordValue
        // Missing other required fields

        XCTAssertThrowsError(try WOD(record: record))
    }

    // MARK: - CloudKit record fetcher init

    func testCloudKitWODRepositoryRecordFetcherInit() async throws {
        let exercisesJSON = """
        [{"exercise":"Bench","variant":null,"sets":3,"reps":8,"percent1RM":null,"restMinutes":2,"notes":null,"bodyweightOnly":false}]
        """
        let record = CKRecord(recordType: "WOD")
        record["id"] = "wod-rf" as CKRecordValue
        record["date"] = "2026-03-01" as CKRecordValue
        record["title"] = "RF WOD" as CKRecordValue
        record["description"] = "Record fetcher test" as CKRecordValue
        record["exercisesJSON"] = exercisesJSON as CKRecordValue

        let fallback = InMemoryWODRepository(wods: [])
        let repo = CloudKitWODRepository(
            fallback: fallback,
            cloudRecordFetcher: { _ in
                [(record.recordID, .success(record))]
            }
        )
        let wods = try await repo.fetchWODs()
        XCTAssertEqual(wods.count, 1)
        XCTAssertEqual(wods[0].id, "wod-rf")
    }
}

// MARK: - Test helpers

final class InMemoryWODRepository: WODRepository, @unchecked Sendable {
    let wods: [WOD]

    init(wods: [WOD]) {
        self.wods = wods
    }

    func fetchWODs() async throws -> [WOD] { wods }
}
