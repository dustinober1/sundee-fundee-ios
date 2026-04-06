import SwiftUI
import Charts

// MARK: - VolumeChart

/// Bar chart showing weekly training volume over time.
///
/// Uses Swift Charts `BarMark` with `chartXSelection` for tap interaction.
/// Art Deco themed with navy bars and gold selection accents.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct VolumeChart: View {
    let data: [VolumeDataPoint]
    @State private var selectedWeek: Date?

    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Training Volume")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                if data.isEmpty {
                    emptyState
                } else {
                    chartContent
                }
            }
        }
    }

    // MARK: - Chart

    private var chartContent: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Week", point.weekStartDate),
                y: .value("Volume", point.totalVolume)
            )
            .foregroundStyle(AppTheme.Background.navy.gradient)
            .cornerRadius(4)

            if let selectedWeek {
                RuleMark(x: .value("Selected", selectedWeek))
                    .foregroundStyle(AppTheme.Accent.gold.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            }
        }
        .chartXSelection(value: $selectedWeek)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppTheme.Accent.gold.opacity(0.2))
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .font(AppTheme.Typography.labelSmall)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppTheme.Accent.gold.opacity(0.2))
                AxisValueLabel()
                    .font(AppTheme.Typography.labelSmall)
            }
        }
        .frame(height: 200)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.Text.secondary.opacity(0.5))

            Text("Complete workouts to track volume")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}
