import SwiftUI
import Charts

// MARK: - StrengthProgressionChart

/// Line chart showing one-rep-max progression over time for a selected exercise.
///
/// Uses Swift Charts `LineMark` with `chartXSelection` for tap-to-inspect.
/// Filtered by the selected exercise from the parent ViewModel.
/// Art Deco themed with navy lines and gold selection accents.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct StrengthProgressionChart: View {
    let data: [StrengthDataPoint]
    let availableExercises: [String]
    @Binding var selectedExercise: String?
    @State private var selectedDate: Date?

    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Section header with exercise picker
                HStack {
                    Text("Strength Progression")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Spacer()

                    if availableExercises.count > 1 {
                        exercisePicker
                    }
                }

                if data.isEmpty {
                    emptyState
                } else {
                    chartContent
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(data.isEmpty
            ? "No data available for strength progression chart"
            : "Strength progression chart showing \(data.count) data points for \(selectedExercise ?? "all exercises")")
    }

    // MARK: - Exercise Picker

    private var exercisePicker: some View {
        Menu {
            Button("All Exercises") {
                selectedExercise = nil
            }
            ForEach(availableExercises, id: \.self) { exercise in
                Button(exercise) {
                    selectedExercise = exercise
                }
            }
        } label: {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 14))
                Text(selectedExercise ?? "All")
                    .font(AppTheme.Typography.labelMedium)
            }
            .foregroundColor(AppTheme.Text.secondary)
        }
    }

    // MARK: - Chart

    private var chartContent: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(AppTheme.Background.navy)
            .lineStyle(StrokeStyle(lineWidth: 2))

            if let selectedDate {
                RuleMark(x: .value("Selected", selectedDate))
                    .foregroundStyle(AppTheme.Accent.gold.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            }
        }
        .chartXSelection(value: $selectedDate)
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
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.Text.secondary.opacity(0.5))
                .accessibilityHidden(true)

            Text("Log your first max to see progression")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}
