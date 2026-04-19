import CloudKit
import XCTest
@testable import SundeeFundeeKit

// MARK: - Test Doubles

/// A test double that always throws `DataError.networkError` so mutations
/// enqueue, and can be toggled to throw a non-network error on replay so
/// we can simulate "N consecutive failures".
private actor FailingClient: DataClientProtocol {
    enum FailureMode {
        case network        // triggers enqueue
        case flush(Error)   // triggers flush-time failure (does NOT re-enqueue)
        case succeed
    }

    var mode: FailureMode = .network
    private(set) var saveCallCount = 0
    private(set) var saveFromJSONCallCount = 0
    private(set) var deleteCallCount = 0

    func setMode(_ mode: FailureMode) {
        self.mode = mode
    }

    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        return []
    }

    func save<T>(_ records: [T], recordType: String) async throws where T: Encodable & Sendable {
        saveCallCount += 1
        switch mode {
        case .network:
            throw DataError.networkError(underlying: NSError(domain: "test", code: -1))
        case .flush(let error):
            throw error
        case .succeed:
            return
        }
    }

    func saveFromJSON(_ jsonRecords: [Data], recordType: String) async throws {
        saveFromJSONCallCount += 1
        switch mode {
        case .network:
            throw DataError.networkError(underlying: NSError(domain: "test", code: -1))
        case .flush(let error):
            throw error
        case .succeed:
            return
        }
    }

    func delete(recordIDs: [CKRecord.ID], recordType: String) async throws {
        deleteCallCount += 1
        switch mode {
        case .network:
            throw DataError.networkError(underlying: NSError(domain: "test", code: -1))
        case .flush(let error):
            throw error
        case .succeed:
            return
        }
    }

    func deleteAllData() async throws {}
}

private struct TestRecord: Codable, Sendable, Equatable {
    let id: String
    let name: String
}

// MARK: - Stuck Mutation Tests

final class SyncQueueStuckTests: XCTestCase {

    @MainActor
    func testMutationMovesToStuckAfterMaxRetries() async throws {
        let suiteName = "Test.SyncQueueStuck.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = await SyncQueueStore(userDefaults: defaults)
        let client = FailingClient()
        let monitor = NetworkMonitor()

        // Low retry bound for test speed.
        let queue = SyncQueue(
            wrapping: client,
            store: store,
            monitor: monitor,
            maxRetryAttempts: 3
        )

        // Enqueue one mutation (client is in .network mode → save throws networkError → enqueued).
        let record = TestRecord(id: "r1", name: "first")
        try await queue.save([record], recordType: "TestRecord")

        let pendingAfterEnqueue = await queue.pendingCount
        XCTAssertEqual(pendingAfterEnqueue, 1, "Mutation should be queued after network failure")

        // Switch client into flush-failure mode: replays will fail with a
        // non-network error, bumping attempts each flush.
        await client.setMode(.flush(NSError(domain: "flush", code: 42)))

        // Flush enough times to exceed maxRetryAttempts.
        // After maxRetryAttempts reached, mutation should be moved to stuck.
        for _ in 0..<5 {
            await queue.flushQueue()
        }

        let pendingAfter = await queue.pendingCount
        XCTAssertEqual(pendingAfter, 0, "Mutation should be removed from pending once stuck")

        let stuck = await queue.stuckMutations
        XCTAssertEqual(stuck.count, 1, "Stuck mutation should be surfaced")
        XCTAssertEqual(stuck.first?.recordType, "TestRecord")
    }

    @MainActor
    func testSuccessfulMutationDoesNotAppearInStuck() async throws {
        let suiteName = "Test.SyncQueueStuck.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = await SyncQueueStore(userDefaults: defaults)
        let client = FailingClient()
        let monitor = NetworkMonitor()

        let queue = SyncQueue(
            wrapping: client,
            store: store,
            monitor: monitor,
            maxRetryAttempts: 3
        )

        let record = TestRecord(id: "r2", name: "second")
        try await queue.save([record], recordType: "TestRecord")
        let initial = await queue.pendingCount
        XCTAssertEqual(initial, 1)

        // Replay succeeds.
        await client.setMode(.succeed)
        await queue.flushQueue()

        let remaining = await queue.pendingCount
        XCTAssertEqual(remaining, 0, "Succeeded mutation should be removed")
        let stuck = await queue.stuckMutations
        XCTAssertTrue(stuck.isEmpty, "Successful mutation must not appear in stuck list")
    }
}
