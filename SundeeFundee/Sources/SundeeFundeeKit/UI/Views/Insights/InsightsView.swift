import SwiftUI

// MARK: - InsightsView
//
// Training insights dashboard surfacing plateau alerts, load trends,
// and weekly summaries from the coach service. Pro-gated.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, AppTheme.Spacing.xl)
                } else if let insights = viewModel.insights {
                    // Summary Card
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Label("Training Insights", systemImage: "chart.line.uptrend.xyaxis")
                                .font(AppTheme.Typography.headlineMedium)
                                .foregroundColor(AppTheme.Text.primary)

                            Text(insights.summary)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }

                    // Priority Actions
                    if !insights.priorityActions.isEmpty {
                        ArtDecoCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                Label("Action Items", systemImage: "checklist")
                                    .font(AppTheme.Typography.headlineMedium)
                                    .foregroundColor(AppTheme.Text.primary)

                                ForEach(insights.priorityActions, id: \.self) { action in
                                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.Accent.gold)

                                        Text(action)
                                            .font(AppTheme.Typography.bodySmall)
                                            .foregroundColor(AppTheme.Text.primary)
                                    }
                                }
                            }
                        }
                    }

                    // Plateau Alerts
                    if !insights.plateaus.isEmpty {
                        plateauSection(insights.plateaus)
                    }

                    // Load Trends
                    if !insights.trends.isEmpty {
                        trendSection(insights.trends)
                    }

                    // Weekly Summaries
                    if !viewModel.weeklySummaries.isEmpty {
                        weeklySummarySection
                    }
                } else {
                    emptyState
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .navigationTitle("Insights")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            await viewModel.loadInsights()
        }
        .refreshable {
            await viewModel.loadInsights()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Plateaus

    private func plateauSection(_ plateaus: [PlateauDetector.PlateauAlert]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Stalled Lifts")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            ForEach(plateaus, id: \.exerciseName) { plateau in
                ArtDecoCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Text(plateau.exerciseName)
                                .font(AppTheme.Typography.headlineMedium)
                                .foregroundColor(AppTheme.Text.primary)

                            Spacer()

                            Text("\(Int(plateau.currentWeight)) \(plateau.unit.rawValue)")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Text.secondary)
                        }

                        HStack(spacing: AppTheme.Spacing.md) {
                            Label("\(plateau.stallCount) attempts", systemImage: "arrow.triangle.2.circlepath")
                            Label("\(plateau.daysSinceBest)d since best", systemImage: "calendar")
                        }
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)

                        Text(plateau.recommendation)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Accent.gold)
                    }
                }
            }
        }
    }

    // MARK: - Trends

    private func trendSection(_ trends: [WeeklyLoadAnalyzer.LoadTrend]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Trends")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            ForEach(trends, id: \.message) { trend in
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: trendIcon(trend.severity))
                        .foregroundColor(trendColor(trend.severity))

                    Text(trend.message)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.primary)
                }
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(trendColor(trend.severity).opacity(0.08))
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }

    private func trendIcon(_ severity: WeeklyLoadAnalyzer.TrendSeverity) -> String {
        switch severity {
        case .positive: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private func trendColor(_ severity: WeeklyLoadAnalyzer.TrendSeverity) -> Color {
        switch severity {
        case .positive: return AppTheme.Semantic.success
        case .warning: return AppTheme.Semantic.warning
        case .info: return AppTheme.Accent.gold
        }
    }

    // MARK: - Weekly Summaries

    private var weeklySummarySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Recent Weeks")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            ForEach(viewModel.weeklySummaries, id: \.weekStartDate) { summary in
                ArtDecoCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Text(weekLabel(summary.weekStartDate))
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Text.primary)

                            Spacer()

                            Text("\(summary.workoutsCompleted) workouts")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }

                        if !summary.muscleGroupsHit.isEmpty {
                            Text(summary.muscleGroupsHit.joined(separator: " · "))
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Accent.gold)
                        }

                        ForEach(summary.observations, id: \.self) { obs in
                            Text(obs)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }
                }
            }
        }
    }

    private func weekLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week of \(formatter.string(from: date))"
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Text.secondary.opacity(0.5))

            Text("No insights yet")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            Text("Complete a few workouts and log your maxes to start seeing training insights.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
    }
}

// MARK: - InsightsViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class InsightsViewModel: ObservableObject {
    @Published var insights: CoachInsightsResponse?
    @Published var weeklySummaries: [CoachWeeklySummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let coachService: CoachServiceProtocol
    private let contextBuilder: CoachContextBuilder
    private let memoryService: CoachMemoryService

    init(
        coachService: CoachServiceProtocol = CoachServiceFactory.makeService(),
        contextBuilder: CoachContextBuilder = CoachContextBuilder(),
        memoryService: CoachMemoryService = CoachMemoryService()
    ) {
        self.coachService = coachService
        self.contextBuilder = contextBuilder
        self.memoryService = memoryService
    }

    func loadInsights() async {
        isLoading = true

        let context = await contextBuilder.build()
        do {
            insights = try await coachService.getInsights(context: context)
        } catch {
            errorMessage = "Failed to load insights: \(error.localizedDescription)"
        }

        weeklySummaries = await memoryService.getRecentSummaries(limit: 4)

        isLoading = false
    }
}
