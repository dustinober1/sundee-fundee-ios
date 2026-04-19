import Foundation
import os.log

private let snapshotLogger = Logger(subsystem: "com.sundeefundee.app", category: "SharedSnapshot")

// MARK: - SharedSnapshotStore
//
// App Group-backed store shared between the main app and the widget extension.
// The widget imports SundeeFundeeKit and reads via readRecovery / readCycle;
// the main app writes after recomputing Recovery Score or cycle phase.

/// Snapshot of today's Recovery Score, readable from the widget extension.
public struct RecoverySnapshot: Codable, Sendable, Equatable {
    public let total: Int
    public let recommendationRaw: String
    public let capturedAt: Date
    public let presentInputCount: Int

    public init(total: Int, recommendationRaw: String, capturedAt: Date, presentInputCount: Int) {
        self.total = total
        self.recommendationRaw = recommendationRaw
        self.capturedAt = capturedAt
        self.presentInputCount = presentInputCount
    }
}

/// Snapshot of current cycle phase, readable from the widget extension.
public struct CyclePhaseSnapshot: Codable, Sendable, Equatable {
    public let phaseRaw: String?
    public let cycleDay: Int?
    public let capturedAt: Date
    public let isSharkWeek: Bool

    public init(phaseRaw: String?, cycleDay: Int?, capturedAt: Date, isSharkWeek: Bool) {
        self.phaseRaw = phaseRaw
        self.cycleDay = cycleDay
        self.capturedAt = capturedAt
        self.isSharkWeek = isSharkWeek
    }
}

public enum SharedSnapshotStore {

    public static let suiteName = "group.com.sundeefundee.shared"

    private static let recoveryKey = "recoverySnapshot.v1"
    private static let cycleKey = "cycleSnapshot.v1"

    /// Overridable suite for tests. Defaults to the shared App Group.
    public static var defaults: UserDefaults? = UserDefaults(suiteName: suiteName)

    // MARK: - Recovery

    public static func writeRecovery(_ snapshot: RecoverySnapshot) {
        guard let defaults else { return }
        do {
            let data = try encoder().encode(snapshot)
            defaults.set(data, forKey: recoveryKey)
        } catch {
            snapshotLogger.error("writeRecovery failed: \(error.localizedDescription)")
        }
    }

    public static func readRecovery() -> RecoverySnapshot? {
        guard let defaults, let data = defaults.data(forKey: recoveryKey) else { return nil }
        return try? decoder().decode(RecoverySnapshot.self, from: data)
    }

    // MARK: - Cycle

    public static func writeCycle(_ snapshot: CyclePhaseSnapshot) {
        guard let defaults else { return }
        do {
            let data = try encoder().encode(snapshot)
            defaults.set(data, forKey: cycleKey)
        } catch {
            snapshotLogger.error("writeCycle failed: \(error.localizedDescription)")
        }
    }

    public static func readCycle() -> CyclePhaseSnapshot? {
        guard let defaults, let data = defaults.data(forKey: cycleKey) else { return nil }
        return try? decoder().decode(CyclePhaseSnapshot.self, from: data)
    }

    // MARK: - Test helpers

    public static func clear() {
        defaults?.removeObject(forKey: recoveryKey)
        defaults?.removeObject(forKey: cycleKey)
    }

    // MARK: - Codec

    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
