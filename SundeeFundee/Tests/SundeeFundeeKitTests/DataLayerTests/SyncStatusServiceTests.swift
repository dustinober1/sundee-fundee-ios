import XCTest
@testable import SundeeFundeeKit

final class SyncStatusServiceTests: XCTestCase {

    // MARK: - Guest Mode

    func testGuestModeReturnsLocalOnly() {
        let status = SyncStatusService.status(
            isGuest: true,
            pendingMutationCount: 0,
            stuckMutationCount: 0
        )

        XCTAssertEqual(status.kind, .localOnly)
        XCTAssertEqual(status.title, "Saved on this device")
        XCTAssertTrue(status.message.contains("Sign in to sync to iCloud"))
        XCTAssertEqual(status.systemImage, "lock.shield")
    }

    func testGuestModeIgnoresQueueCounts() {
        // Even if counts are non-zero, guest is always localOnly
        let status = SyncStatusService.status(
            isGuest: true,
            pendingMutationCount: 5,
            stuckMutationCount: 3
        )

        XCTAssertEqual(status.kind, .localOnly)
    }

    // MARK: - Synced

    func testSignedInWithEmptyQueueReturnsSynced() {
        let status = SyncStatusService.status(
            isGuest: false,
            pendingMutationCount: 0,
            stuckMutationCount: 0
        )

        XCTAssertEqual(status.kind, .synced)
        XCTAssertEqual(status.title, "Synced with iCloud")
        XCTAssertTrue(status.message.contains("synced with iCloud"))
        XCTAssertEqual(status.systemImage, "checkmark.icloud")
    }

    // MARK: - Queued

    func testSignedInWithPendingOnlyReturnsQueued() {
        let status = SyncStatusService.status(
            isGuest: false,
            pendingMutationCount: 3,
            stuckMutationCount: 0
        )

        XCTAssertEqual(status.kind, .queued)
        XCTAssertEqual(status.title, "Waiting to sync")
        XCTAssertTrue(status.message.contains("3 changes waiting to sync"))
        XCTAssertEqual(status.systemImage, "arrow.triangle.2.circlepath.icloud")
    }

    func testSignedInWithSinglePendingReturnsSingularMessage() {
        let status = SyncStatusService.status(
            isGuest: false,
            pendingMutationCount: 1,
            stuckMutationCount: 0
        )

        XCTAssertEqual(status.kind, .queued)
        XCTAssertTrue(status.message.contains("1 change waiting to sync"))
    }

    // MARK: - Needs Attention

    func testSignedInWithStuckMutationsReturnsNeedsAttention() {
        let status = SyncStatusService.status(
            isGuest: false,
            pendingMutationCount: 0,
            stuckMutationCount: 2
        )

        XCTAssertEqual(status.kind, .needsAttention)
        XCTAssertEqual(status.title, "Needs attention")
        XCTAssertTrue(status.message.contains("couldn't sync"))
        XCTAssertTrue(status.message.contains("Check your connection"))
        XCTAssertEqual(status.systemImage, "exclamationmark.icloud")
    }

    func testSignedInWithBothPendingAndStuckReturnsNeedsAttention() {
        // Stuck takes priority over pending
        let status = SyncStatusService.status(
            isGuest: false,
            pendingMutationCount: 5,
            stuckMutationCount: 1
        )

        XCTAssertEqual(status.kind, .needsAttention)
    }

    // MARK: - SyncStatus Properties

    func testAllStatusesHaveNonEmptyFields() {
        let allStatuses: [SyncStatus] = [
            SyncStatusService.status(isGuest: true, pendingMutationCount: 0, stuckMutationCount: 0),
            SyncStatusService.status(isGuest: false, pendingMutationCount: 0, stuckMutationCount: 0),
            SyncStatusService.status(isGuest: false, pendingMutationCount: 1, stuckMutationCount: 0),
            SyncStatusService.status(isGuest: false, pendingMutationCount: 0, stuckMutationCount: 1),
        ]

        for status in allStatuses {
            XCTAssertFalse(status.title.isEmpty, "Title should not be empty for \(status.kind)")
            XCTAssertFalse(status.message.isEmpty, "Message should not be empty for \(status.kind)")
            XCTAssertFalse(status.systemImage.isEmpty, "systemImage should not be empty for \(status.kind)")
        }
    }

    func testSyncStatusKindRawValues() {
        XCTAssertEqual(SyncStatusKind.localOnly.rawValue, "localOnly")
        XCTAssertEqual(SyncStatusKind.synced.rawValue, "synced")
        XCTAssertEqual(SyncStatusKind.queued.rawValue, "queued")
        XCTAssertEqual(SyncStatusKind.needsAttention.rawValue, "needsAttention")
    }

    func testSyncStatusIsEquatable() {
        let a = SyncStatusService.status(isGuest: false, pendingMutationCount: 0, stuckMutationCount: 0)
        let b = SyncStatusService.status(isGuest: false, pendingMutationCount: 0, stuckMutationCount: 0)
        let c = SyncStatusService.status(isGuest: true, pendingMutationCount: 0, stuckMutationCount: 0)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testSyncStatusKindIsSendable() {
        // Compile-time check — if this compiles, Sendable conformance is correct
        let _: any Sendable = SyncStatusKind.localOnly
    }

    func testSyncStatusIsSendable() {
        let _: any Sendable = SyncStatusService.status(
            isGuest: false,
            pendingMutationCount: 0,
            stuckMutationCount: 0
        )
    }
}
