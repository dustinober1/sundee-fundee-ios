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

        public init(ownerID: String, client: any DataClientProtocol) {
            self.ownerID = ownerID
            self.client = client
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

    /// The active data client. Thread-safe read/write.
    public var client: any DataClientProtocol {
        get { lock.withLock { _client } }
        set {
            lock.withLock { _client = newValue }
            factoryLogger.info("🔀 DataClient switched to: \(String(describing: type(of: newValue)))")
        }
    }

    /// A single lock-protected snapshot prevents pairing one account's client
    /// with another account's local cache during a concurrent session switch.
    public var session: Session {
        lock.withLock { Session(ownerID: _ownerID, client: _client) }
    }

    public var ownerID: String {
        lock.withLock { _ownerID }
    }

    public func activate(client: any DataClientProtocol, ownerID: String) {
        lock.withLock {
            _client = client
            _ownerID = ownerID
        }
        factoryLogger.info(
            "🔀 DataClient session switched to owner namespace: \(ownerID, privacy: .private(mask: .hash))"
        )
    }

    // MARK: - Initialization

    private init() {}
}
