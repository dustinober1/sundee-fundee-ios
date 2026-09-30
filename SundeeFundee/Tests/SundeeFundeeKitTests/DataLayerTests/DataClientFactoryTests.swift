import XCTest
@testable import SundeeFundeeKit

/// Tests `DataClientFactory.wrapForSync` and `syncQueueSuiteName` as pure
/// functions. Deliberately does not touch `DataClientFactory.shared` — it's
/// a singleton, and mutating its shared state from a test would leak into
/// every other test that reads `DataClientFactory.shared.client`.
final class DataClientFactoryTests: XCTestCase {

    func testWrapsNonLocalClientsInSyncQueue() {
        // Uses MockCloudKitClient rather than a real CloudKitClient: constructing
        // a live CKContainer hangs the test process in this repo's macOS CI
        // runner (no responsive CloudKit daemon in that sandbox), the same
        // class of issue this repo already hit once with a real StoreKit call
        // in a test. wrapForSync checks !(client is LocalDataClient), so any
        // non-local stand-in exercises the same branch a real CloudKitClient
        // would in production.
        let client = MockCloudKitClient()
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

    // The setter and `activate` must share one installation path: the setter
    // once re-read `_client` outside the lock to attach diagnostics, which
    // was a data race `@unchecked Sendable` hides from the compiler. These
    // tests pin the observable semantics of both entry points on a private
    // (non-`shared`) instance so a future divergence fails loudly.

    func testClientSetterWrapsAndPreservesOwner() {
        let suiteName = "DataClientFactoryTests.setter.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        let factory = DataClientFactory(
            client: LocalDataClient(userDefaults: UserDefaults(suiteName: suiteName)!),
            ownerID: "owner-a"
        )

        factory.client = MockCloudKitClient()

        XCTAssertTrue(factory.client is SyncQueue)
        XCTAssertEqual(factory.ownerID, "owner-a", "plain client set must not rewrite the owner namespace")
    }

    func testActivateWrapsAndUpdatesOwner() {
        let suiteName = "DataClientFactoryTests.activate.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        let factory = DataClientFactory(
            client: LocalDataClient(userDefaults: UserDefaults(suiteName: suiteName)!),
            ownerID: "owner-a"
        )

        factory.activate(client: MockCloudKitClient(), ownerID: "owner-b")

        XCTAssertTrue(factory.client is SyncQueue)
        XCTAssertEqual(factory.ownerID, "owner-b")
    }

    func testGenerationIncrementsOnBothPaths() {
        let suiteName = "DataClientFactoryTests.generation.\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        let factory = DataClientFactory(
            client: LocalDataClient(userDefaults: UserDefaults(suiteName: suiteName)!),
            ownerID: "owner-a"
        )
        let initial = factory.session.generation

        factory.client = MockCloudKitClient()
        let afterSet = factory.session.generation

        factory.activate(client: MockCloudKitClient(), ownerID: "owner-b")
        let afterActivate = factory.session.generation

        XCTAssertEqual(afterSet, initial &+ 1)
        XCTAssertEqual(afterActivate, initial &+ 2)
    }
}
