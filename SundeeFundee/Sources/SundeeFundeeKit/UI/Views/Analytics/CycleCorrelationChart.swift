import SwiftUI
import Charts

// MARK: - CycleCorrelationChart

/// Bar chart showing average training volume by menstrual cycle phase.
///
/// Shows a BarMark chart with phase-appropriate colors
/// (menstrual=red, follicular=gold, ovulation=orange, luteal=navy).
/// Displays an empty state when no cycle data is available.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct CycleCorrelationChart: View {
    let data: [CyclePerformancePoint]

    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Section header
                Text("Cycle Correlation")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                if data.isEmpty {
                    emptyState
                } else {
                    chartContent
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(data.isEmpty
            ? "No data available for cycle correlation chart"
            : "Cycle correlation chart showing average volume by menstrual phase: \(data.map { "\(phaseLabel($0.phase)): \(Int($0.averageVolume))" }.joined(separator: ", "))")
    }

    // MARK: - Chart

    private var chartContent: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Phase", phaseLabel(point.phase)),
                y: .value("Avg Volume", point.averageVolume)
            )
            .foregroundStyle(phaseColor(point.phase).gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
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
            Image(systemName: "heart.text.square")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.Text.secondary.opacity(0.5))
                .accessibilityHidden(true)

            Text("Track cycle phases to see correlation")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Helpers

    private func phaseLabel(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulation: return "Ovulation"
        case .luteal: return "Luteal"
        }
    }

    private func phaseColor(_ phase: CyclePhase) -> Color {
        switch phase {
        case .menstrual: return .red
        case .follicular: return AppTheme.Accent.gold
        case .ovulation: return AppTheme.Accent.orange
        case .luteal: return AppTheme.Background.navy
        }
    }
}
