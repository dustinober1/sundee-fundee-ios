import SwiftUI

// MARK: - MonthlyReviewViewModel

@MainActor
@Observable
final class MonthlyReviewViewModel {

    var review: MonthlyReview?
    var isLoading = true
    var errorMessage: String?

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    func loadReview(for month: Date = Date()) async {
        isLoading = true
        errorMessage = nil

        do {
            let workouts: [Workout] = try await dataClient.fetchAll(recordType: "Workout")
            let painLogs: [DailyPainLog] = (try? await dataClient.fetchAll(recordType: "DailyPainLog")) ?? []
            let effortLogs: [WorkoutEffortLog] = (try? await dataClient.fetchAll(recordType: "WorkoutEffortLog")) ?? []
            let symptomLogs: [SymptomCheckInRecord] = (try? await dataClient.fetchAll(recordType: "SymptomCheckInRecord")) ?? []

            review = MonthlyReviewService.build(
                month: month,
                workouts: workouts,
                painLogs: painLogs,
                effortLogs: effortLogs,
                symptomLogs: symptomLogs
            )
        } catch {
            errorMessage = "We couldn't load your monthly review. Check your connection and try again."
        }

        isLoading = false
    }
}

// MARK: - MonthlyReviewDetailView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct MonthlyReviewDetailView: View {
    @State private var viewModel = MonthlyReviewViewModel()
    @State private var showShareSheet = false

    private let month: Date

    public init(month: Date = Date()) {
        self.month = month
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                if viewModel.isLoading {
                    ProgressView("Loading monthly review")
                        .padding(.top, AppTheme.Spacing.xxxl)
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else if let review = viewModel.review {
                    reviewContent(review)
                }
            }
            .padding()
        }
        .background(AppTheme.Background.brandCream.ignoresSafeArea())
        .navigationTitle("Monthly Review")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            if viewModel.review != nil {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
                #endif
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            if let review = viewModel.review {
                ShareCardSheet(
                    variant: .monthlyReview(review: review),
                    shareContext: ShareContext(
                        surface: .cycleInsight,
                        sourceID: "monthly-review",
                        title: review.monthTitle
                    )
                )
            }
        }
        #endif
        .task {
            await viewModel.loadReview(for: month)
        }
    }

    // MARK: - Review Content

    @ViewBuilder
    private func reviewContent(_ review: MonthlyReview) -> some View {
        // Header card
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.md) {
                Text(review.monthTitle)
                    .font(AppTheme.Typography.displayMedium)
                    .foregroundColor(AppTheme.Text.primary)

                HStack(spacing: AppTheme.Spacing.xl) {
                    StatCard(value: "\(review.workoutCount)", label: "Workouts")
                    StatCard(value: "\(review.personalRecordCount)", label: "High-Effort")
                }
            }
        }

        // Top Wins
        if !review.topWins.isEmpty {
            sectionCard(title: "Top Wins", icon: "star.fill", items: review.topWins)
        }

        // Patterns
        if !review.patterns.isEmpty {
            sectionCard(title: "Patterns", icon: "chart.line.uptrend.xyaxis", items: review.patterns)
        }

        // Next Month Suggestions
        if !review.nextMonthSuggestions.isEmpty {
            sectionCard(
                title: "Looking Ahead",
                icon: "lightbulb.fill",
                items: review.nextMonthSuggestions
            )
        }
    }

    // MARK: - Section Card

    @ViewBuilder
    private func sectionCard(title: String, icon: String, items: [String]) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(AppTheme.Accent.gold)
                    Text(title)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)
                }

                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Circle()
                            .fill(AppTheme.Accent.gold)
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)
                        Text(item)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(message: String) -> some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(AppTheme.Semantic.warning)
                Text(message)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    Task { await viewModel.loadReview(for: month) }
                }
                .artDecoButton(style: .secondary)
            }
        }
    }
}
