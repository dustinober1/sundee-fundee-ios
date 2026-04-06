import SwiftUI

// MARK: - AnalyticsView

/// Main analytics screen containing four chart sections with time range selection.
///
/// Displays strength progression (line), training volume (bar), workout frequency (bar),
/// and cycle-correlated performance (Pro-gated bar) — all driven by the AnalyticsViewModel.
/// Supports pull-to-refresh and time range switching with automatic re-aggregation.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var showingSubscription = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Time range picker
                timeRangePicker

                // Loading state
                if viewModel.isLoading {
                    loadingState
                } else if let error = viewModel.errorMessage {
                    errorState(message: error)
                } else {
                    // Charts
                    StrengthProgressionChart(
                        data: viewModel.strengthData,
                        availableExercises: viewModel.availableExercises,
                        selectedExercise: $viewModel.selectedExercise
                    )

                    VolumeChart(data: viewModel.volumeData)

                    FrequencyChart(data: viewModel.frequencyData)

                    CycleCorrelationChart(
                        data: viewModel.cycleData,
                        hasAccess: viewModel.hasCycleAccess
                    )
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .navigationTitle("Analytics")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .background(AppTheme.Background.cream)
        .task {
            await viewModel.loadAnalytics()
        }
        .refreshable {
            await viewModel.loadAnalytics()
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    timeRangeButton(range)
                }
            }
        }
    }

    private func timeRangeButton(_ range: TimeRange) -> some View {
        let isSelected = viewModel.selectedTimeRange == range

        return Button {
            viewModel.selectedTimeRange = range
        } label: {
            Text(range.shortLabel)
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(isSelected ? AppTheme.Text.cream : AppTheme.Text.primary)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(isSelected ? AppTheme.Background.navy : AppTheme.Background.card)
                .cornerRadius(AppTheme.CornerRadius.circle)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : AppTheme.Accent.gold.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppTheme.Accent.gold)

            Text("Loading analytics…")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.Semantic.warning)

                Text("Could not load analytics")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Text(message)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .multilineTextAlignment(.center)

                Button("Retry") {
                    Task {
                        await viewModel.loadAnalytics()
                    }
                }
                .artDecoButton(style: .accent)
            }
        }
    }
}

// MARK: - TimeRange Label Extension

extension TimeRange {
    /// Short display label for the time range picker chip.
    var shortLabel: String {
        switch self {
        case .lastMonth: return "1M"
        case .lastThreeMonths: return "3M"
        case .lastSixMonths: return "6M"
        case .lastYear: return "1Y"
        case .allTime: return "All"
        }
    }
}
