import SwiftUI

// MARK: - AnalyticsView

/// Main analytics screen containing four chart sections with time range selection.
///
/// Displays strength progression (line), training volume (bar), workout frequency (bar),
/// and cycle-correlated performance, all driven by the AnalyticsViewModel.
/// Supports pull-to-refresh and time range switching with automatic re-aggregation.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var showLogMax = false

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
                } else if viewModel.hasNoData {
                    emptyState
                } else {
                    if let snapshot = viewModel.progressSnapshot {
                        progressSnapshotCard(snapshot)
                    }

                    if !viewModel.cycleInsights.isEmpty {
                        cycleInsightsCard(viewModel.cycleInsights)
                    }

                    // Charts
                    StrengthProgressionChart(
                        data: viewModel.strengthData,
                        availableExercises: viewModel.availableExercises,
                        selectedExercise: $viewModel.selectedExercise
                    )

                    VolumeChart(data: viewModel.volumeData)

                    FrequencyChart(data: viewModel.frequencyData)

                    CycleCorrelationChart(
                        data: viewModel.cycleData
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
        .sheet(isPresented: $showLogMax) {
            NavigationStack { MaxesListView() }
        }
        .task {
            await viewModel.loadAnalytics()
        }
        .refreshable {
            await viewModel.loadAnalytics()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
            Task { await viewModel.loadAnalytics() }
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
        .accessibilityLabel("\(range.shortLabel) time range")
        .accessibilityHint("Filter analytics to \(range.shortLabel)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView("Loading analytics")
                .progressViewStyle(.circular)
                .tint(AppTheme.Accent.gold)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Error State

    private func errorState(message: String) -> some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title)
                    .foregroundColor(AppTheme.Semantic.warning)
                    .accessibilityHidden(true)

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
                .accessibilityHint("Reload analytics data")
            }
        }
    }

    private func progressSnapshotCard(_ snapshot: ProgressSnapshot) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Progress Snapshot")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.Spacing.sm) {
                    ForEach(snapshot.items) { item in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Image(systemName: item.systemImage)
                                .font(.headline)
                                .foregroundColor(AppTheme.Accent.gold)
                                .accessibilityHidden(true)

                            Text(item.title)
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Text.secondary)

                            Text(item.value)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Text(item.subtitle)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.Background.cream.opacity(0.45))
                        .cornerRadius(AppTheme.CornerRadius.small)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private func cycleInsightsCard(_ insights: [CycleAwareProgressInsight]) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Cycle-Aware Insights")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                ForEach(insights.prefix(3)) { insight in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(insight.title)
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Accent.gold)
                        Text(insight.value)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.primary)
                        Text(insight.subtitle)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "chart.bar",
            title: "No Data Yet",
            subtitle: "Complete your first workout and log a max to start seeing your analytics.",
            actionLabel: "Log a Max",
            action: { showLogMax = true }
        )
        .frame(maxWidth: .infinity, minHeight: 400)
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
