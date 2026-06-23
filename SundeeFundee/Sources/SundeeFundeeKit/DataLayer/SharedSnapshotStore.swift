import Foundation
import os.log

private let snapshotLogger = Logger(subsystem: "com.sundeefundee.app", category: "SharedSnapshot")

// MARK: - SharedSnapshotStore
//
// App Group-backed store shared between the main app and the widget extension.
// The widget imports SundeeFundeeKit and reads cycle state written by the main app.

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

    private static let cycleKey = "cycleSnapshot.v1"
    private static let sharkWeekBannerSuppressedKey = "sharkWeekBannerSuppressed.v1"

    /// Overridable suite for tests. Defaults to the shared App Group.
    /// `nonisolated(unsafe)` because this is a test seam — production code
    /// only reads/writes through the enum's static methods from the main actor
    /// (CyclePhaseCache, widget timeline provider).
    nonisolated(unsafe) public static var defaults: UserDefaults? = UserDefaults(suiteName: suiteName)

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
        defaults?.removeObject(forKey: cycleKey)
        defaults?.removeObject(forKey: sharkWeekBannerSuppressedKey)
    }

    // MARK: - Shark Week Banner

    public static func writeSharkWeekBannerSuppressed(_ isSuppressed: Bool) {
        defaults?.set(isSuppressed, forKey: sharkWeekBannerSuppressedKey)
    }

    public static func readSharkWeekBannerSuppressed() -> Bool {
        defaults?.bool(forKey: sharkWeekBannerSuppressedKey) ?? false
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
