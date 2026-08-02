import SwiftUI

// MARK: - FeatureTourView
//
// Post-onboarding feature tour highlighting key app capabilities.
// Shows once after initial onboarding to help users understand the app.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct FeatureTourView: View {
    @StateObject private var viewModel = FeatureTourViewModel()
    let onComplete: () -> Void

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressIndicator

            // Tour content
            TabView(selection: $viewModel.currentPage) {
                dashboardTourPage.tag(0)
                cycleAwareTourPage.tag(1)
                progressTrackingTourPage.tag(2)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)

            // Navigation buttons
            navigationButtons
        }
        .artDecoBackground()
        .task {
            await viewModel.trackTourStarted()
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == viewModel.currentPage ? AppTheme.Accent.gold : AppTheme.Text.secondary.opacity(0.3))
                    .frame(width: index == viewModel.currentPage ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)
            }
        }
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.md)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(viewModel.currentPage + 1) of \(viewModel.totalPages)")
    }

    // MARK: - Tour Pages

    private var dashboardTourPage: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.Accent.goldLight)
                        .frame(width: 120, height: 120)

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 56))
                        .foregroundColor(AppTheme.Accent.gold)
                        .symbolEffect(.bounce, value: viewModel.currentPage)
                }
                .accessibilityHidden(true)
                .padding(.top, AppTheme.Spacing.xl)

                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Your Dashboard")
                        .font(AppTheme.Typography.displayMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text("Start here every day")
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Accent.gold)
                }

                VStack(spacing: AppTheme.Spacing.lg) {
                    FeatureTourBullet(
                        icon: "figure.strengthtraining.traditional",
                        title: "Today's Workout",
                        description: "Get personalized workout suggestions based on your goals and energy"
                    )

                    FeatureTourBullet(
                        icon: "checkmark.circle.fill",
                        title: "Quick Check-ins",
                        description: "Log how you're feeling to help optimize your training"
                    )

                    FeatureTourBullet(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Progress at a Glance",
                        description: "See your weekly stats and celebrate recent wins"
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .padding(AppTheme.Spacing.lg)
    }

    private var cycleAwareTourPage: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Icon with phase symbols
                ZStack {
                    Circle()
                        .fill(AppTheme.Accent.goldLight)
                        .frame(width: 120, height: 120)

                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.Semantic.error)

                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.Accent.gold)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.Accent.orange)

                            Image(systemName: "moon.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }
                    .symbolEffect(.pulse, value: viewModel.currentPage)
                }
                .accessibilityHidden(true)
                .padding(.top, AppTheme.Spacing.xl)

                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Cycle-Aware Training")
                        .font(AppTheme.Typography.displayMedium)
                        .foregroundColor(AppTheme.Text.primary)
                        .multilineTextAlignment(.center)

                    Text("Work with your body, not against it")
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Accent.gold)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: AppTheme.Spacing.lg) {
                    FeatureTourBullet(
                        icon: "calendar",
                        title: "Track Your Cycle",
                        description: "Log your cycle phases to unlock personalized programming"
                    )

                    FeatureTourBullet(
                        icon: "waveform.path.ecg",
                        title: "Adaptive Workouts",
                        description: "Intensity adjusts based on your current phase for optimal results"
                    )

                    FeatureTourBullet(
                        icon: "brain.head.profile",
                        title: "Science-Backed",
                        description: "Training recommendations based on hormonal fluctuations"
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.xl)

                // Optional note if cycle tracking is disabled
                if !viewModel.cycleTrackingEnabled {
                    Text("You can enable cycle tracking anytime in Settings")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                }

                Spacer(minLength: AppTheme.Spacing.xl)
            }
        }
        .padding(AppTheme.Spacing.lg)
    }

    private var progressTrackingTourPage: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.Accent.goldLight)
                        .frame(width: 120, height: 120)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 56))
                        .foregroundColor(AppTheme.Accent.gold)
                        .symbolEffect(.bounce, value: viewModel.currentPage)
                }
                .accessibilityHidden(true)
                .padding(.top, AppTheme.Spacing.xl)

                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Track Your Wins")
                        .font(AppTheme.Typography.displayMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text("Every rep counts")
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Accent.gold)
                }

                VStack(spacing: AppTheme.Spacing.lg) {
                    FeatureTourBullet(
                        icon: "chart.bar.fill",
                        title: "Benchmarks & PRs",
                        description: "Track your personal records and see how you're improving over time"
                    )

                    FeatureTourBullet(
                        icon: "photo.on.rectangle.angled",
                        title: "Visual Progress",
                        description: "Upload progress photos to see your transformation"
                    )

                    FeatureTourBullet(
                        icon: "calendar.badge.checkmark",
                        title: "Workout History",
                        description: "Review past workouts and identify patterns in your training"
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.xl)

                // Ready to start message
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Ready to get started?")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text("Your first workout is waiting")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                }
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .padding(AppTheme.Spacing.lg)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Skip button (only on first pages)
            if viewModel.currentPage < viewModel.totalPages - 1 {
                Button("Skip Tour") {
                    Task {
                        await viewModel.trackTourSkipped()
                        onComplete()
                    }
                }
                .artDecoButton(style: .ghost)
                .accessibilityHint("Skip the feature tour and go to dashboard")
            }

            Spacer()

            // Next / Get Started button
            if viewModel.currentPage < viewModel.totalPages - 1 {
                Button("Next") {
                    withAnimation {
                        viewModel.currentPage += 1
                    }
                }
                .artDecoButton(style: .primary)
                .accessibilityHint("Go to next tour page")
            } else {
                Button("Get Started") {
                    Task {
                        await viewModel.trackTourCompleted()
                        onComplete()
                    }
                }
                .artDecoButton(style: .accent)
                .accessibilityHint("Complete tour and go to dashboard")
            }
        }
        .padding(AppTheme.Spacing.lg)
    }
}

// MARK: - FeatureTourBullet

/// Reusable component for feature highlights with icon, title, and description
private struct FeatureTourBullet: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppTheme.Accent.gold)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Text.primary)

                Text(description)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

// MARK: - FeatureTourViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class FeatureTourViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    let totalPages = 3

    var cycleTrackingEnabled: Bool {
        // Check user settings to conditionally show cycle tracking note
        UserDefaults.standard.bool(forKey: "cycleTrackingEnabled")
    }

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    func markTourComplete() {
        _ = KeychainHelper.save(key: "feature_tour_complete", value: "true")
    }

    static func hasCompletedTour() -> Bool {
        if let value = KeychainHelper.read(key: "feature_tour_complete"),
           value == "true" {
            return true
        }
        return false
    }

    // MARK: - Analytics

    func trackTourStarted() async {
        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.featureTourStarted,
            source: "post_onboarding"
        )
    }

    func trackTourCompleted() async {
        markTourComplete()
        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.featureTourCompleted,
            source: "post_onboarding",
            properties: ["pages_viewed": "\(totalPages)"]
        )
    }

    func trackTourSkipped() async {
        markTourComplete()
        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.featureTourSkipped,
            source: "post_onboarding",
            properties: ["skipped_at_page": "\(currentPage + 1)"]
        )
    }
}

// MARK: - Preview

#Preview {
    FeatureTourView {
        print("Tour completed")
    }
}
