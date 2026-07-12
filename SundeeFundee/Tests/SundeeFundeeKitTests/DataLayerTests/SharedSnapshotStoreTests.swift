import Foundation
import Testing
@testable import SundeeFundeeKit

// MARK: - SharedSnapshotStoreTests

// These tests drive the production `SharedSnapshotStore`, which mutates a
// nonisolated(unsafe) `UserDefaults?` global. On macOS Swift Package tests
// the test host has no bundle identity, so `UserDefaults(suiteName:)` can
// silently fall back to `.standard`, and Swift 6 parallel test execution
// traps when the global is swapped under us. Disabled on SPM/macOS; the
// widget read path is covered by the iOS app test target.
@Suite("SharedSnapshotStore", .serialized, .disabled("Flakes on macOS SPM test host (no bundle identity for UserDefaults suites)."))
struct SharedSnapshotStoreTests {

    private func withTestSuite(_ body: @Sendable () throws -> Void) async rethrows {
        // macOS SPM tests lack bundle identity, so `UserDefaults(suiteName:)`
        // can silently fail. Fall back to `.standard` and explicitly clear
        // the known snapshot keys for isolation. The actor serializes access
        // to the shared `SharedSnapshotStore.defaults` global across
        // concurrent Swift Testing suites.
        try await SharedSnapshotTestLock.shared.run {
            let suiteName = "com.sundeefundee.tests.snapshot-\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suiteName) ?? .standard
            let previous = SharedSnapshotStore.defaults
            SharedSnapshotStore.defaults = defaults
            SharedSnapshotStore.clear()
            defer {
                SharedSnapshotStore.clear()
                SharedSnapshotStore.defaults = previous
                defaults.removePersistentDomain(forName: suiteName)
            }
            try body()
        }
    }

    @Test("Cycle snapshot round-trips through UserDefaults")
    func cycleRoundTrip() async throws {
        await withTestSuite {
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

    @Test("Shark Week banner suppression round-trips through UserDefaults")
    func sharkWeekBannerSuppressionRoundTrip() async throws {
        await withTestSuite {
            SharedSnapshotStore.writeSharkWeekBannerSuppressed(true)
            #expect(SharedSnapshotStore.readSharkWeekBannerSuppressed())

            SharedSnapshotStore.writeSharkWeekBannerSuppressed(false)
            #expect(!SharedSnapshotStore.readSharkWeekBannerSuppressed())
        }
    }

    @Test("readCycle returns nil on empty suite")
    func emptyCycle() async throws {
        await withTestSuite {
            #expect(SharedSnapshotStore.readCycle() == nil)
        }
    }

    @Test("clear() wipes cycle snapshot")
    func clearWipes() async throws {
        await withTestSuite {
            SharedSnapshotStore.writeCycle(
                CyclePhaseSnapshot(phaseRaw: "luteal", cycleDay: 22, capturedAt: Date(), isSharkWeek: false)
            )
            SharedSnapshotStore.clear()
            #expect(SharedSnapshotStore.readCycle() == nil)
        }
    }

    @Test("Readiness snapshot round-trips through UserDefaults")
    func readinessRoundTrip() async throws {
        await withTestSuite {
            let snapshot = DailyReadinessSnapshot(stateRaw: "maintain", totalScore: 72, confidenceRaw: "medium", modelVersion: "readiness-v1", assessmentDate: Date(timeIntervalSince1970: 1_700_000_000), capturedAt: Date(timeIntervalSince1970: 1_700_000_100))
            SharedSnapshotStore.writeReadiness(snapshot)
            #expect(SharedSnapshotStore.readReadiness() == snapshot)
        }
    }

    @Test("clear removes readiness snapshot")
    func clearRemovesReadiness() async throws {
        await withTestSuite {
            SharedSnapshotStore.writeReadiness(DailyReadinessSnapshot(stateRaw: "maintain", totalScore: 72, confidenceRaw: "medium", modelVersion: "readiness-v1", assessmentDate: Date(), capturedAt: Date()))
            SharedSnapshotStore.clear()
            #expect(SharedSnapshotStore.readReadiness() == nil)
        }
    }
}
