import Foundation

// MARK: - HealthClientFactory
//
// Singleton that holds the active health client for the current session.
// Switch between HealthKitClient (real device/production) and MockHealthKitClient (screenshots/testing)
// by setting HealthClientFactory.shared.client before any ViewModels are initialized.
//
// Usage:
//   HealthClientFactory.shared.client = MockHealthKitClient()  // screenshot mode
//   HealthClientFactory.shared.client = HealthKitClient()       // default

public final class HealthClientFactory: @unchecked Sendable {

    // MARK: - Shared Instance

    public static let shared = HealthClientFactory()

    // MARK: - Client

    private let lock = NSLock()
    private var _client: any HealthClientProtocol = HealthKitClient()

    /// The active health client. Thread-safe read/write.
    public var client: any HealthClientProtocol {
        get { lock.withLock { _client } }
        set { lock.withLock { _client = newValue } }
    }

    // MARK: - Initialization

    private init() {}
}
