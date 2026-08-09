#if os(iOS) && canImport(StoreKitTest)
@testable import SundeeFundeeKit
import StoreKitTest
import XCTest

/// Exercises `StoreKitSupportTipStore` against the real `SundeeFundee.storekit`
/// configuration, which the scheme binds to the test action.
///
/// This test previously created its own `SKTestSession` over the same
/// configuration file. That is a second, competing StoreKit environment: the
/// session failed to initialize with `SKInternalErrorDomain Code=3`, and
/// because a failed session never applies `disableDialogs`, `purchase()` went
/// on to wait for confirmation UI that a unit-test host has no scene to
/// present. The result was a hang that blocked every test scheduled after it —
/// 41 minutes of CI before the job timeout, and the same locally, which is why
/// full iOS test runs had never completed.
///
/// The configuration now comes from one place only: the scheme.
@available(iOS 18.0, *)
final class StoreKitSupportTipStoreIntegrationTests: XCTestCase {

    func testRealStoreKitConfigurationLoadsAndPurchasesSupportTip() async throws {
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

    // MARK: - Timeout
    //
    // StoreKit calls can block indefinitely when the test storefront is not
    // usable. Left unbounded, one such call takes down the whole iOS suite
    // rather than failing on its own. Bounding each phase keeps the worst case
    // to a named failure instead of a dead run.

    private struct PhaseTimeout: Error, CustomStringConvertible {
        let phase: String
        let seconds: Double
        var description: String {
            "StoreKit phase '\(phase)' did not return within \(Int(seconds))s. "
                + "The test storefront is likely unavailable, or a second StoreKit "
                + "configuration is competing with the one bound by the scheme."
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
