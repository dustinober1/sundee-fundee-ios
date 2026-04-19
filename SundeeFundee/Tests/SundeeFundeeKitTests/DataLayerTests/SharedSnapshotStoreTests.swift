import Foundation
import Testing
@testable import SundeeFundeeKit

// MARK: - SharedSnapshotStoreTests

@Suite("SharedSnapshotStore")
struct SharedSnapshotStoreTests {

    private func withTestSuite(_ body: () throws -> Void) rethrows {
        let suiteName = "com.sundeefundee.tests.snapshot-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        let previous = SharedSnapshotStore.defaults
        SharedSnapshotStore.defaults = defaults
        defer {
            SharedSnapshotStore.defaults = previous
            defaults?.removePersistentDomain(forName: suiteName)
        }
        try body()
    }

    @Test("Recovery snapshot round-trips through UserDefaults")
    func recoveryRoundTrip() throws {
        try withTestSuite {
            let captured = Date(timeIntervalSince1970: 1_700_000_000)
            let snapshot = RecoverySnapshot(
                total: 72,
                recommendationRaw: "pushDay",
                capturedAt: captured,
                presentInputCount: 4
            )
            SharedSnapshotStore.writeRecovery(snapshot)
            let read = SharedSnapshotStore.readRecovery()
            #expect(read == snapshot)
        }
    }

    @Test("Cycle snapshot round-trips through UserDefaults")
    func cycleRoundTrip() throws {
        try withTestSuite {
            let snapshot = CyclePhaseSnapshot(
                phaseRaw: "follicular",
                cycleDay: 9,
                capturedAt: Date(timeIntervalSince1970: 1_700_000_000),
                isSharkWeek: false
            )
            SharedSnapshotStore.writeCycle(snapshot)
            #expect(SharedSnapshotStore.readCycle() == snapshot)
        }
    }

    @Test("readRecovery returns nil on empty suite")
    func emptyRecovery() throws {
        try withTestSuite {
            #expect(SharedSnapshotStore.readRecovery() == nil)
            #expect(SharedSnapshotStore.readCycle() == nil)
        }
    }

    @Test("clear() wipes both snapshots")
    func clearWipes() throws {
        try withTestSuite {
            SharedSnapshotStore.writeRecovery(
                RecoverySnapshot(total: 50, recommendationRaw: "moderate", capturedAt: Date(), presentInputCount: 3)
            )
            SharedSnapshotStore.writeCycle(
                CyclePhaseSnapshot(phaseRaw: "luteal", cycleDay: 22, capturedAt: Date(), isSharkWeek: false)
            )
            SharedSnapshotStore.clear()
            #expect(SharedSnapshotStore.readRecovery() == nil)
            #expect(SharedSnapshotStore.readCycle() == nil)
        }
    }
}
