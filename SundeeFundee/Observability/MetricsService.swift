import Foundation
import MetricKit
import os

/// Subscribes to MetricKit diagnostics payloads and logs them for Xcode Organizer review.
final class MetricsService: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {
    struct MetricPayloadSummary: Sendable {
        let begin: Date
        let end: Date
        let cpuTime: Measurement<UnitDuration>?
        let peakMemory: Measurement<UnitInformationStorage>?
    }

    struct DiagnosticPayloadSummary: Sendable {
        let crashCount: Int?
        let hangCount: Int?
    }

    private static let logger = Logger(subsystem: "com.sundeefundee.app", category: "MetricsService")

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
        #if DEBUG
        logMetricPayloads(payloads.map {
            MetricPayloadSummary(
                begin: $0.timeStampBegin,
                end: $0.timeStampEnd,
                cpuTime: $0.cpuMetrics?.cumulativeCPUTime,
                peakMemory: $0.memoryMetrics?.peakMemoryUsage
            )
        })
        #endif
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        #if DEBUG
        logDiagnosticPayloads(payloads.map {
            DiagnosticPayloadSummary(
                crashCount: $0.crashDiagnostics?.count,
                hangCount: $0.hangDiagnostics?.count
            )
        })
        #endif
    }

    func logMetricPayloads(
        _ payloads: [MetricPayloadSummary],
        printer: (String) -> Void = { MetricsService.logger.debug("\($0, privacy: .private)") }
    ) {
        for payload in payloads {
            for line in metricSummaryLines(
                begin: payload.begin,
                end: payload.end,
                cpuTime: payload.cpuTime,
                peakMemory: payload.peakMemory
            ) {
                printer(line)
            }
        }
    }

    func logDiagnosticPayloads(
        _ payloads: [DiagnosticPayloadSummary],
        printer: (String) -> Void = { MetricsService.logger.debug("\($0, privacy: .private)") }
    ) {
        for payload in payloads {
            for line in diagnosticSummaryLines(
                crashCount: payload.crashCount,
                hangCount: payload.hangCount
            ) {
                printer(line)
            }
        }
    }

    func metricSummaryLines(
        begin: Date,
        end: Date,
        cpuTime: Measurement<UnitDuration>?,
        peakMemory: Measurement<UnitInformationStorage>?
    ) -> [String] {
        var lines = ["[MetricsService] Received metric payload for \(begin) – \(end)"]
        if let cpuTime {
            lines.append("  CPU time: \(cpuTime)")
        }
        if let peakMemory {
            lines.append("  Peak memory: \(peakMemory)")
        }
        return lines
    }

    func diagnosticSummaryLines(
        crashCount: Int?,
        hangCount: Int?
    ) -> [String] {
        var lines = ["[MetricsService] Received diagnostic payload"]
        if let crashCount {
            lines.append("  Crashes: \(crashCount)")
        }
        if let hangCount {
            lines.append("  Hangs: \(hangCount)")
        }
        return lines
    }
}
