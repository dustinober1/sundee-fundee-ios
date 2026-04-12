import Foundation
import os.log

private let factoryLogger = Logger(subsystem: "com.sundeefundee.app", category: "DataClient")

// MARK: - DataClientFactory
//
// Singleton that holds the active data client for the current session.
// Switch between CloudKitClient (signed-in users) and LocalDataClient (guests)
// by setting DataClientFactory.shared.client before any ViewModels are initialized.
//
// Usage:
//   DataClientFactory.shared.client = LocalDataClient()   // guest sign-in
//   DataClientFactory.shared.client = CloudKitClient(...)  // Apple sign-in / restore

public final class DataClientFactory: @unchecked Sendable {

    // MARK: - Shared Instance

    public static let shared = DataClientFactory()

    // MARK: - Client

    private let lock = NSLock()
    private var _client: any DataClientProtocol = CloudKitClient(
        containerIdentifier: "iCloud.com.sundeefundee.app"
    )

    /// The active data client. Thread-safe read/write.
    public var client: any DataClientProtocol {
        get { lock.withLock { _client } }
        set {
            lock.withLock { _client = newValue }
            factoryLogger.info("🔀 DataClient switched to: \(String(describing: type(of: newValue)))")
        }
    }

    // MARK: - Initialization

    private init() {}
}
