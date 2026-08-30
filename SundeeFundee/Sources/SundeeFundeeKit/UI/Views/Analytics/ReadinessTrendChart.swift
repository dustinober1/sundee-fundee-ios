import SwiftUI
import Charts

// MARK: - ReadinessTrendChart

/// Line chart showing daily readiness score history.
///
/// Colors each point by `AppTheme.recoveryColor(for:)`, the same score-to-color
/// mapping the Today readiness card already uses, so a score reads the same
/// color everywhere in the app. Low-confidence days are shown smaller and
/// more transparent rather than plotted with the same visual weight as a
/// fully-signaled score — the model itself is less sure about them.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ReadinessTrendChart: View {
    let data: [ReadinessDataPoint]

    private static let sparseDataThreshold = 7

    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Readiness Trend")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                if data.isEmpty {
                    emptyState
                } else if data.count < Self.sparseDataThreshold {
                    sparseState
                } else {
                    chartContent
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(data.isEmpty
            ? "No readiness data available yet"
            : "Readiness trend chart showing \(data.count) days, most recent score \(data.last?.totalScore ?? 0)")
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartContent: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Score", point.totalScore)
            )
            .foregroundStyle(AppTheme.Background.navy.opacity(0.35))
            .lineStyle(StrokeStyle(lineWidth: 1.5))

            PointMark(
                x: .value("Date", point.date),
                y: .value("Score", point.totalScore)
            )
            .foregroundStyle(pointColor(for: point))
            .symbolSize(point.confidence == .low ? 25 : 50)
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppTheme.Accent.gold.opacity(0.2))
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .font(AppTheme.Typography.labelSmall)
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 35, 60, 80, 100]) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppTheme.Accent.gold.opacity(0.2))
                AxisValueLabel()
                    .font(AppTheme.Typography.labelSmall)
            }
        }
        .frame(height: 200)

        if data.contains(where: { $0.confidence == .low }) {
            Text("Faded points are low-confidence days — fewer signals were available.")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)
        }
    }

    private func pointColor(for point: ReadinessDataPoint) -> Color {
        let base = AppTheme.recoveryColor(for: point.totalScore)
        return point.confidence == .low ? base.opacity(0.4) : base
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.title)
                .foregroundColor(AppTheme.Text.secondary.opacity(0.5))
                .accessibilityHidden(true)

            Text("Check in daily to see your readiness trend")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Sparse State

    private var sparseState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.title)
                .foregroundColor(AppTheme.Text.secondary.opacity(0.5))
                .accessibilityHidden(true)

            Text("A trend appears after a week of readiness check-ins")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}
