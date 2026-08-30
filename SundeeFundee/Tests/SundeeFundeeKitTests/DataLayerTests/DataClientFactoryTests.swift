import XCTest
@testable import SundeeFundeeKit

/// Tests `DataClientFactory.wrapForSync` and `syncQueueSuiteName` as pure
/// functions. Deliberately does not touch `DataClientFactory.shared` — it's
/// a singleton, and mutating its shared state from a test would leak into
/// every other test that reads `DataClientFactory.shared.client`.
final class DataClientFactoryTests: XCTestCase {

    func testWrapsCloudKitClientInSyncQueue() {
        let client = CloudKitClient(containerIdentifier: "iCloud.com.sundeefundee.app")
        let monitor = NetworkMonitor()

        let wrapped = DataClientFactory.wrapForSync(client, ownerID: "owner-a", monitor: monitor)

        XCTAssertTrue(wrapped is SyncQueue)
    }

    func testDoesNotWrapLocalDataClient() {
        let suiteName = "DataClientFactoryTests.local.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        let client = LocalDataClient(userDefaults: UserDefaults(suiteName: suiteName)!)
        let monitor = NetworkMonitor()

        let wrapped = DataClientFactory.wrapForSync(client, ownerID: "guest_local", monitor: monitor)

        XCTAssertFalse(wrapped is SyncQueue)
    }

    func testSyncQueueSuiteNameDiffersByOwner() {
        let ownerA = "owner-\(UUID().uuidString)"
        let ownerB = "owner-\(UUID().uuidString)"

        XCTAssertNotEqual(
            DataClientFactory.syncQueueSuiteName(for: ownerA),
            DataClientFactory.syncQueueSuiteName(for: ownerB)
        )
    }

    func testSyncQueueSuiteNameIsStableForTheSameOwner() {
        let owner = "owner-\(UUID().uuidString)"

        XCTAssertEqual(
            DataClientFactory.syncQueueSuiteName(for: owner),
            DataClientFactory.syncQueueSuiteName(for: owner)
        )
    }

    func testDifferentOwnersGetIsolatedQueueStorage() async throws {
        let ownerA = "owner-\(UUID().uuidString)"
        let ownerB = "owner-\(UUID().uuidString)"
        let suiteA = DataClientFactory.syncQueueSuiteName(for: ownerA)
        let suiteB = DataClientFactory.syncQueueSuiteName(for: ownerB)
        defer {
            UserDefaults(suiteName: suiteA)?.removePersistentDomain(forName: suiteA)
            UserDefaults(suiteName: suiteB)?.removePersistentDomain(forName: suiteB)
        }

        // Directly exercises the same SyncQueueStore type wrapForSync builds,
        // since SyncQueue's own store is private and unreachable even via
        // @testable import — this verifies the isolation property the suite
        // naming exists to guarantee, without a real CloudKit round trip.
        let storeA = SyncQueueStore(userDefaults: UserDefaults(suiteName: suiteA)!)
        let storeB = SyncQueueStore(userDefaults: UserDefaults(suiteName: suiteB)!)

        let mutation = PendingMutation(
            recordType: "Workout",
            operation: .save,
            encodedData: try JSONEncoder().encode(["ownerA-only"])
        )
        await storeA.append(mutation)

        let countA = await storeA.pendingCount
        let countB = await storeB.pendingCount
        XCTAssertEqual(countA, 1)
        XCTAssertEqual(countB, 0)
    }
}
