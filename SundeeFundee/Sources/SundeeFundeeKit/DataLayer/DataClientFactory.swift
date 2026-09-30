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

    private let lock = NSLock()
    // No property-level default: defaults evaluate at the start of *every*
    // init, and constructing a live CKContainer traps under the macOS CI
    // sandbox. The CloudKit boot client belongs to `init()` alone; the test
    // initializer injects a stand-in before any CloudKit type is touched.
    private var _client: any DataClientProtocol
    private var _ownerID = "signed-out"
    private var _generation: UInt64 = 0

    /// Shared for the factory's lifetime rather than one per `activate()` call,
    /// so switching accounts doesn't spin up a new `NWPathMonitor` each time.
    private let networkMonitor = NetworkMonitor()

    /// The active data client. Thread-safe read/write.
    public var client: any DataClientProtocol {
        get { lock.withLock { _client } }
        set {
            let wrapped = install(client: newValue, ownerID: lock.withLock { _ownerID })
            factoryLogger.info("🔀 DataClient switched to: \(String(describing: type(of: newValue)))")
            attachDiagnostics(wrapped)
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
        let wrapped = install(client: client, ownerID: ownerID)
        factoryLogger.info(
            "🔀 DataClient session switched to owner namespace: \(ownerID, privacy: .private(mask: .hash))"
        )
        attachDiagnostics(wrapped)
    }

    /// The one path through which `_client`/`_ownerID`/`_generation` change.
    /// Returns the wrapped client so callers act on the value they just
    /// installed rather than re-reading `_client` outside the lock — that
    /// unlocked re-read was a data race this class's `@unchecked Sendable`
    /// conformity hides from the compiler.
    private func install(client: any DataClientProtocol, ownerID: String) -> any DataClientProtocol {
        let wrapped = Self.wrapForSync(client, ownerID: ownerID, monitor: networkMonitor)
        lock.withLock {
            _client = wrapped
            _ownerID = ownerID
            _generation &+= 1
        }
        return wrapped
    }

    private func attachDiagnostics(_ wrapped: any DataClientProtocol) {
        let queue = wrapped as? SyncQueue
        Task { @MainActor in
            SyncQueueDiagnosticsService.shared.attach(queue)
        }
    }

    // MARK: - Sync Queue Wrapping

    /// Wraps a freshly-activated client so CloudKit writes survive being
    /// offline. Everything except `LocalDataClient` (guest mode) is wrapped —
    /// guest mode never throws a network error, so queuing it would be a
    /// no-op. Checking what to exclude rather than what to include means a
    /// future non-CloudKit, non-local client defaults to being wrapped
    /// instead of silently bypassing the offline queue.
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
        guard !(client is LocalDataClient) else { return client }
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

    private init() {
        _client = CloudKitClient(containerIdentifier: "iCloud.com.sundeefundee.app")
    }

    /// Non-singleton initializer for tests. Production code uses `shared`,
    /// which boots with a live CloudKit client — constructing a real
    /// CKContainer traps in the macOS CI sandbox, so tests must inject a
    /// stand-in client explicitly.
    init(client: any DataClientProtocol, ownerID: String = "test-owner") {
        _client = client
        _ownerID = ownerID
    }
}
