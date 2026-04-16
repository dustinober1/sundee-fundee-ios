import Charts
import SwiftUI

// MARK: - RecoveryTrendChart
//
// 30-day line chart of recovery scores with cycle-phase color bands.
// Uses SwiftUI Charts (RectangleMark + LineMark + PointMark).
// Per UI-SPEC D-06, D-07.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct RecoveryTrendChart: View {

    // MARK: - Properties

    let scores: [RecoveryScoreRecord]
    let phaseBands: [(startDate: Date, endDate: Date, phase: CyclePhase)]

    private let formatter = ISO8601DateFormatter()

    // MARK: - Body

    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                if scores.isEmpty {
                    emptyState
                } else {
                    chartContent
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartAccessibilityLabel)
    }

    // MARK: - Chart Content

    private var chartContent: some View {
        Chart {
            // Layer 1: Phase bands (background) -- D-07 vertical colored bands
            ForEach(Array(phaseBands.enumerated()), id: \.offset) { _, band in
                RectangleMark(
                    xStart: .value("Phase Start", band.startDate),
                    xEnd: .value("Phase End", band.endDate),
                    yStart: .value("Min", 0),
                    yEnd: .value("Max", 100)
                )
                .foregroundStyle(band.phase.chartBandColor.opacity(band.phase.chartBandOpacity))
            }

            // Zone boundary gridlines at 40 and 70
            RuleMark(y: .value("Yellow Zone", 40))
                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                .foregroundStyle(AppTheme.Text.secondary.opacity(0.3))
            RuleMark(y: .value("Green Zone", 70))
                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                .foregroundStyle(AppTheme.Text.secondary.opacity(0.3))

            // Layer 2: Score line
            ForEach(scores, id: \.id) { record in
                if let date = formatter.date(from: record.scoreDate) {
                    LineMark(
                        x: .value("Date", date),
                        y: .value("Score", record.totalScore)
                    )
                    .foregroundStyle(AppTheme.Text.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Date", date),
                        y: .value("Score", record.totalScore)
                    )
                    .foregroundStyle(AppTheme.recoveryColor(for: record.totalScore))
                    .symbolSize(16)
                }
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppTheme.Accent.gold.opacity(0.2))
                AxisValueLabel(format: .dateTime.day())
                    .font(AppTheme.Typography.monoLarge)
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 20, 40, 60, 80, 100]) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppTheme.Accent.gold.opacity(0.2))
                AxisValueLabel()
                    .font(AppTheme.Typography.monoLarge)
            }
        }
        .frame(height: 200)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.Text.secondary.opacity(0.5))
                .accessibilityHidden(true)
            Text("Not enough data yet - check back after a few days.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Accessibility

    private var chartAccessibilityLabel: String {
        guard !scores.isEmpty else { return "Recovery trend chart. Not enough data yet." }
        let avg = scores.map(\.totalScore).reduce(0, +) / scores.count
        let minScore = scores.map(\.totalScore).min() ?? 0
        let maxScore = scores.map(\.totalScore).max() ?? 0
        return "Recovery score trend over 30 days. Average: \(avg). Range: \(minScore) to \(maxScore)."
    }
}
