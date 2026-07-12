import CloudKit
import XCTest
@testable import SundeeFundeeKit

@MainActor
final class DailyReadinessServiceTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
    private var defaults: UserDefaults!
    private var previousDefaults: UserDefaults?

    override func setUp() {
        super.setUp()
        previousDefaults = SharedSnapshotStore.defaults
        defaults = UserDefaults(suiteName: "DailyReadinessServiceTests.\(UUID().uuidString)") ?? .standard
        SharedSnapshotStore.defaults = defaults
        SharedSnapshotStore.clear()
    }

    override func tearDown() {
        SharedSnapshotStore.clear()
        SharedSnapshotStore.defaults = previousDefaults
        defaults = nil
        previousDefaults = nil
        super.tearDown()
    }

    func testSuccessfulAssessmentPersistsAndCaches() async throws {
        let client = MockCloudKitClient()
        let service = makeService(dataClient: client, subjective: SubjectiveReadinessSnapshot(energy: 8, fatigue: 2))
        let result = await service.calculateShadowAssessment(assessmentDate: fixedDate, timeZone: .gmt, cyclePhase: .luteal, cycleConfidence: 0.8)
        XCTAssertEqual(result?.persistence, .saved)
        let saved: [DailyReadinessRecord] = try await client.fetchAll(recordType: DailyReadinessRecord.recordType)
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(SharedSnapshotStore.readReadiness()?.totalScore, result?.assessment.totalScore)
    }

    func testSaveFailureReturnsCachedOnly() async {
        let service = makeService(dataClient: FailingSaveClient(), subjective: SubjectiveReadinessSnapshot(energy: 8))
        let result = await service.calculateShadowAssessment(assessmentDate: fixedDate, timeZone: .gmt, cyclePhase: nil, cycleConfidence: nil)
        XCTAssertEqual(result?.persistence, .cachedOnly)
        XCTAssertNotNil(SharedSnapshotStore.readReadiness())
    }

    func testEmptyContextReturnsNilAndDoesNotCache() async {
        let service = makeService(dataClient: MockCloudKitClient(), subjective: .empty)
        let result = await service.calculateShadowAssessment(assessmentDate: fixedDate, timeZone: .gmt, cyclePhase: nil, cycleConfidence: nil)
        XCTAssertNil(result)
        XCTAssertNil(SharedSnapshotStore.readReadiness())
    }

    private func makeService(dataClient: DataClientProtocol, subjective: SubjectiveReadinessSnapshot) -> DailyReadinessService {
        let builder = DailyTrainingContextBuilder(healthProvider: FixedHealthProvider(value: .empty), historyProvider: FixedHistoryProvider(value: HistoryReadinessSnapshot(subjective: subjective, training: .empty, pain: nil)))
        return DailyReadinessService(contextBuilder: builder, dataClient: dataClient)
    }
}

private actor FixedHealthProvider: HealthReadinessProviding {
    let value: PhysiologicalReadinessSnapshot
    init(value: PhysiologicalReadinessSnapshot) { self.value = value }
    func load(assessmentDate: Date, calendar: Calendar) async -> PhysiologicalReadinessSnapshot { value }
}

private actor FixedHistoryProvider: HistoryReadinessProviding {
    let value: HistoryReadinessSnapshot
    init(value: HistoryReadinessSnapshot) { self.value = value }
    func load(assessmentDate: Date, calendar: Calendar) async -> HistoryReadinessSnapshot { value }
}

private actor FailingSaveClient: DataClientProtocol {
    func fetch<T>(recordType: String, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]?) async throws -> [T] where T: Decodable & Sendable { [] }
    func save<T>(_ records: [T], recordType: String) async throws where T: Encodable & Sendable { throw DataError.networkError(underlying: nil) }
    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws {}
    func deleteAllData() async throws {}
    func saveFromJSON(_ jsonRecords: [Data], recordType: String) async throws { throw DataError.networkError(underlying: nil) }
}
