import Foundation
import MetricKit

/// Subscribes to MetricKit diagnostics payloads and logs them for Xcode Organizer review.
final class MetricsService: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {
    static let shared = MetricsService()

    private override init() {
        super.init()
    }

    func start() {
        MXMetricManager.shared.add(self)
    }

    func stop() {
        MXMetricManager.shared.remove(self)
    }

    // MARK: - MXMetricManagerSubscriber

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // payloads are automatically available in Xcode Organizer
            // Log a summary for debugging purposes only
            #if DEBUG
            print("[MetricsService] Received metric payload for \(payload.timeStampBegin) – \(payload.timeStampEnd)")
            if let cpu = payload.cpuMetrics {
                print("  CPU time: \(cpu.cumulativeCPUTime)")
            }
            if let memory = payload.memoryMetrics {
                print("  Peak memory: \(memory.peakMemoryUsage)")
            }
            #endif
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            #if DEBUG
            print("[MetricsService] Received diagnostic payload")
            if let crashes = payload.crashDiagnostics {
                print("  Crashes: \(crashes.count)")
            }
            if let hangs = payload.hangDiagnostics {
                print("  Hangs: \(hangs.count)")
            }
            #endif
        }
    }
}
