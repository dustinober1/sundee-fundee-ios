import Foundation

// MARK: - SubscriptionClientFactory
//
// Singleton that holds the active subscription client for the current session.
// Switch between RevenueCatClient (production) and MockSubscriptionClient (testing/guest)
// by setting SubscriptionClientFactory.shared.client at app launch.
//
// Usage:
//   SubscriptionClientFactory.shared.client = RevenueCatClient(apiKey: "appl_xxx")
//   SubscriptionClientFactory.shared.client = MockSubscriptionClient()  // guest/test

public final class SubscriptionClientFactory: @unchecked Sendable {

    // MARK: - Shared Instance

    public static let shared = SubscriptionClientFactory()

    // MARK: - Client

    private let lock = NSLock()
    private var _client: any SubscriptionClientProtocol = MockSubscriptionClient()

    /// The active subscription client. Thread-safe read/write.
    public var client: any SubscriptionClientProtocol {
        get { lock.withLock { _client } }
        set { lock.withLock { _client = newValue } }
    }

    // MARK: - Initialization

    private init() {}
}
