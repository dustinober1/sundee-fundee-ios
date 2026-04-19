import Foundation

/// Cross-suite serializer for tests that mutate `SharedSnapshotStore.defaults`.
/// Swift Testing runs suites in parallel by default; without this gate,
/// `AppIntentsTests` and `SharedSnapshotStoreTests` race on the global and
/// trigger a data-race trap (SIGTRAP) under Swift 6 strict checking.
///
/// An actor serializes all async callers. Sync callers must wrap work in a
/// `Task` and await; since tests are tiny, the overhead is negligible.
actor SharedSnapshotTestLock {
    static let shared = SharedSnapshotTestLock()

    func run<T>(_ body: () throws -> T) rethrows -> T {
        try body()
    }

    func runAsync<T>(_ body: () async throws -> T) async rethrows -> T {
        try await body()
    }
}
