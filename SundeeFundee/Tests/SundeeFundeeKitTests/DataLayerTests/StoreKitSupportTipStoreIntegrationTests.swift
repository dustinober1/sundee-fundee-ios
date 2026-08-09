#if os(iOS) && canImport(StoreKitTest)
@testable import SundeeFundeeKit
import StoreKitTest
import XCTest

/// Exercises `StoreKitSupportTipStore` against the real `SundeeFundee.storekit`
/// configuration.
///
/// KNOWN BROKEN — skipped in CI. Do not un-skip without reproducing locally
/// first; a hang here blocks every test queued behind it.
///
/// What happens today:
///
///   [SKTestSession] Error saving configuration file: SKInternalErrorDomain Code=3
///   [Default] Could not find a UI anchor for ...support.tip199 purchase
///
/// `SKTestSession(contentsOf:)` is handed an absolute path into the source tree
/// derived from `#filePath`. The sandboxed simulator app cannot write there, so
/// the session fails to initialize, `disableDialogs` never applies, and
/// `purchase()` then blocks waiting on confirmation UI that a unit-test host
/// has no scene to present. The process is eventually killed.
///
/// Cost of the hang: it blocked the ~960 tests scheduled after it, so a full
/// iOS run never completed — 41 minutes of CI before the job timeout, and the
/// same locally. That is why the iOS suite had never been run in this repo
/// before CI existed.
///
/// Ruled out while diagnosing:
///   - The scheme's test-action StoreKit configuration competing with the
///     session. Removing it does not change the Code=3 failure.
///   - Bounding the calls with a task-group timeout. StoreKit blocks rather
///     than suspends, starving the sibling sleep, so it never fires.
///
/// Likely fix, not yet attempted: add SundeeFundee.storekit to the test
/// target's resources and use `SKTestSession(configurationFileNamed:)`, so the
/// session reads a bundled copy instead of an unwritable source path.
@available(iOS 18.0, *)
final class StoreKitSupportTipStoreIntegrationTests: XCTestCase {
    private var session: SKTestSession?

    override func tearDown() {
        session?.clearTransactions()
        session = nil
        super.tearDown()
    }

    func testRealStoreKitConfigurationLoadsAndPurchasesSupportTip() async throws {
        let session = try SKTestSession(contentsOf: Self.storeKitConfigurationURL())
        session.disableDialogs = true
        session.clearTransactions()
        self.session = session

        let store = StoreKitSupportTipStore()

        let offer = try await withPhaseTimeout("loadSupportTip") {
            try await store.loadSupportTip()
        }
        XCTAssertEqual(offer.id, SupportTipProduct.id)
        XCTAssertEqual(offer.displayPrice, "$1.99")

        let outcome = try await withPhaseTimeout("purchaseSupportTip") {
            await store.purchaseSupportTip()
        }
        XCTAssertEqual(outcome, .purchased)
    }

    private static func storeKitConfigurationURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // DataLayerTests
            .deletingLastPathComponent() // SundeeFundeeKitTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // SundeeFundee
            .deletingLastPathComponent() // repo root
            .appendingPathComponent("SundeeFundeeApp/StoreKit/SundeeFundee.storekit")
    }

    // MARK: - Timeout
    //
    // Best-effort only. It does not fire against the current hang, because
    // StoreKit blocks the executor rather than suspending, so the sibling
    // Task.sleep is never scheduled. Kept because it does bound the cases where
    // a call genuinely suspends, and it costs nothing. The real protection
    // against one hang taking down the suite is the CI job timeout plus the
    // executed-count floor.

    private struct PhaseTimeout: Error, CustomStringConvertible {
        let phase: String
        let seconds: Double
        var description: String {
            "StoreKit phase '\(phase)' did not return within \(Int(seconds))s."
        }
    }

    private func withPhaseTimeout<T: Sendable>(
        _ phase: String,
        seconds: Double = 30,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw PhaseTimeout(phase: phase, seconds: seconds)
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else {
                throw PhaseTimeout(phase: phase, seconds: seconds)
            }
            return first
        }
    }
}
#endif
