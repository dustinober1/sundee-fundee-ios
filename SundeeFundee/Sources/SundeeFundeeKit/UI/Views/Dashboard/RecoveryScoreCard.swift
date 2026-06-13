import SwiftUI

// MARK: - RecoveryScoreCard
//
// Hero dashboard element showing the recovery score as an animated ring.
// Displays one of four states: score ring, guest placeholder, loading, or empty.
// Per UI-SPEC D-01, D-02, D-03, D-08, D-09.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct RecoveryScoreCard: View {

    // MARK: - Properties

    let score: RecoveryScore?
    let isLoading: Bool
    let isGuest: Bool

    @State private var animatedProgress: Double = 0

    // MARK: - Body

    var body: some View {
        if isGuest {
            guestPlaceholder
        } else if isLoading {
            loadingState
        } else if let score = score {
            scoreRing(score: score)
        } else {
            emptyState
        }
    }

    // MARK: - Score Ring (D-01, D-02)

    private func scoreRing(score: RecoveryScore) -> some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.sm) {
                ZStack {
                    // Background arc track
                    Circle()
                        .stroke(
                            AppTheme.Background.cream.opacity(0.3),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)

                    // Animated fill arc
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(
                            AppTheme.recoveryColor(for: score.total),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))

                    // Center content
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("\(score.total)")
                            .font(AppTheme.Typography.displayLarge)
                            .foregroundColor(AppTheme.Text.primary)

                        Text(recommendationLabel(score.recommendation))
                            .font(AppTheme.Typography.displaySmall)
                            .foregroundColor(AppTheme.recoveryColor(for: score.total))
                    }
                }

                Text("Recovery Score")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Text.secondary)

                // Partial data badge (D-08)
                if score.presentInputCount < score.totalInputCount {
                    Text("\(score.presentInputCount)/\(score.totalInputCount) inputs")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.Background.card)
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = Double(score.total) / 100.0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Recovery score \(score.total) out of 100. \(recommendationLabel(score.recommendation))"
        )
        .accessibilityHint("Tap to view breakdown")
    }

    // MARK: - Guest Placeholder (D-09)

    private var guestPlaceholder: some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "heart.circle")
                    .font(.largeTitle)
                    .foregroundColor(AppTheme.Accent.gold)
                    .accessibilityHidden(true)

                Text("Sign in to unlock Recovery Score")
                    .font(AppTheme.Typography.displaySmall)
                    .foregroundColor(AppTheme.Text.primary)
                    .multilineTextAlignment(.center)

                // Note: Sign In button action wired by parent via environment
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        ArtDecoCard {
            VStack {
                ProgressView("Loading recovery score")
                    .frame(width: 200, height: 200)
                Text("Recovery Score")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "heart.circle")
                    .font(.title)
                    .foregroundColor(AppTheme.Text.secondary.opacity(0.5))
                    .accessibilityHidden(true)

                Text("No recovery data yet")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Text("Open the app after sleeping with Apple Watch to calculate your first score.")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        }
    }

    // MARK: - Helpers

    private func recommendationLabel(_ rec: TrainingRecommendation) -> String {
        switch rec {
        case .pushDay:  return "Push Day"
        case .moderate: return "Take It Easy"
        case .restDay:  return "Rest Day"
        }
    }
}
