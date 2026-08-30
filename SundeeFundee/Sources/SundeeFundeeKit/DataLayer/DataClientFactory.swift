import Foundation
import os.log

private let factoryLogger = Logger(subsystem: "com.sundeefundee.app", category: "DataClient")

// MARK: - DataClientFactory
//
// Singleton that holds the active data client and immutable owner identity for
// the current session.
// Switch between CloudKitClient (signed-in users) and LocalDataClient (guests)
// with `activate(client:ownerID:)` before account-scoped ViewModels resolve it.
//
// Usage:
//   DataClientFactory.shared.client = LocalDataClient()   // guest sign-in
//   DataClientFactory.shared.client = CloudKitClient(...)  // Apple sign-in / restore

public final class DataClientFactory: @unchecked Sendable {
    public struct Session: Sendable {
        public let ownerID: String
        public let client: any DataClientProtocol
        public let generation: UInt64

        public init(
            ownerID: String,
            client: any DataClientProtocol,
            generation: UInt64 = 0
        ) {
            self.ownerID = ownerID
            self.client = client
            self.generation = generation
        }
    }

    // MARK: - Shared Instance

    public static let shared = DataClientFactory()

    // MARK: - Client

    private let lock = NSLock()
    private var _client: any DataClientProtocol = CloudKitClient(
        containerIdentifier: "iCloud.com.sundeefundee.app"
    )
    private var _ownerID = "signed-out"
    private var _generation: UInt64 = 0

    /// Shared for the factory's lifetime rather than one per `activate()` call,
    /// so switching accounts doesn't spin up a new `NWPathMonitor` each time.
    private let networkMonitor = NetworkMonitor()

    /// The active data client. Thread-safe read/write.
    public var client: any DataClientProtocol {
        get { lock.withLock { _client } }
        set {
            lock.withLock {
                _client = newValue
                _generation &+= 1
            }
            factoryLogger.info("🔀 DataClient switched to: \(String(describing: type(of: newValue)))")
        }
    }

    /// A single lock-protected snapshot prevents pairing one account's client
    /// with another account's local cache during a concurrent session switch.
    public var session: Session {
        lock.withLock {
            Session(
                ownerID: _ownerID,
                client: _client,
                generation: _generation
            )
        }
    }

    public var ownerID: String {
        lock.withLock { _ownerID }
    }

    public func activate(client: any DataClientProtocol, ownerID: String) {
        let wrapped = Self.wrapForSync(client, ownerID: ownerID, monitor: networkMonitor)
        lock.withLock {
            _client = wrapped
            _ownerID = ownerID
            _generation &+= 1
        }
        factoryLogger.info(
            "🔀 DataClient session switched to owner namespace: \(ownerID, privacy: .private(mask: .hash))"
        )
        let queue = wrapped as? SyncQueue
        Task { @MainActor in
            SyncQueueDiagnosticsService.shared.attach(queue)
        }
    }

    // MARK: - Sync Queue Wrapping

    /// Wraps a freshly-activated client so CloudKit writes survive being
    /// offline. Only `CloudKitClient` is wrapped — `LocalDataClient` (guest
    /// mode) never throws a network error, so queuing it would be a no-op.
    ///
    /// Each `ownerID` gets its own on-device storage (an arbitrary
    /// `UserDefaults` suite name, not a real App Group — no entitlement
    /// needed). Without this, every account would share one pending-mutation
    /// store: if Account A queued a write offline and then Account B signed
    /// in on the same device before reconnecting, Account B's queue would
    /// replay Account A's write into Account B's CloudKit data on the next
    /// successful flush. Namespacing by owner makes that impossible by
    /// construction rather than by detecting and clearing on account switch,
    /// which would require `activate` to become async.
    static func wrapForSync(
        _ client: any DataClientProtocol,
        ownerID: String,
        monitor: NetworkMonitor
    ) -> any DataClientProtocol {
        guard client is CloudKitClient else { return client }
        let suiteName = syncQueueSuiteName(for: ownerID)
        let store = SyncQueueStore(userDefaults: UserDefaults(suiteName: suiteName) ?? .standard)
        return SyncQueue(wrapping: client, store: store, monitor: monitor)
    }

    /// Separated from `wrapForSync` as its own function so tests can verify
    /// the isolation-by-owner naming scheme directly, without needing a real
    /// `CloudKitClient` round trip to observe it.
    static func syncQueueSuiteName(for ownerID: String) -> String {
        "com.sundeefundee.syncqueue.\(ownerID)"
    }

    // MARK: - Initialization

    private init() {}
}
