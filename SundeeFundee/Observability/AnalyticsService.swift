import Foundation
import os

/// Lightweight analytics service for monetization event tracking.
/// Phase 1: logs to os_log in DEBUG. Phase 2+: swap for Firebase/Amplitude backend.
@MainActor
final class AnalyticsService: Sendable {
    static let shared = AnalyticsService()
    private static let logger = Logger(subsystem: "com.sundeefundee.app", category: "analytics")

    func track(_ event: AnalyticsEvent, properties: [String: String] = [:]) {
        let propString = properties.isEmpty ? "" : " \(properties)"
        Self.logger.info("[Analytics] \(event.rawValue)\(propString)")
    }

    nonisolated static func formatProperties(_ properties: [String: String]) -> String {
        properties.isEmpty ? "" : properties.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ", ")
    }
}
