import SwiftUI

// MARK: - RecoveryOverviewView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct RecoveryOverviewView: View {
    @StateObject private var viewModel = RecoveryScoreViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var cyclePhaseCache: CyclePhaseCache

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                NavigationLink {
                    RecoveryBreakdownView(viewModel: viewModel)
                } label: {
                    RecoveryScoreCard(
                        score: viewModel.score,
                        isLoading: viewModel.isLoading,
                        isGuest: authViewModel.isGuest
                    )
                }
                .buttonStyle(.plain)

                Text("Recovery Score combines available sleep, HRV, training load, pain, and cycle context when those inputs are available.")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !viewModel.topExplanations.isEmpty {
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Top Recovery Factors")
                                .font(AppTheme.Typography.headlineMedium)
                                .foregroundColor(AppTheme.Text.primary)

                            ForEach(viewModel.topExplanations.prefix(3)) { explanation in
                                HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                                    Circle()
                                        .fill(AppTheme.Accent.gold.opacity(0.6))
                                        .frame(width: 5, height: 5)
                                        .padding(.top, 5)
                                        .accessibilityHidden(true)
                                    Text(explanation.text)
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Text.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }

                if let deload = viewModel.deloadRecommendation, deload.isRecommended {
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Active Recovery Suggested")
                                .font(AppTheme.Typography.headlineMedium)
                                .foregroundColor(AppTheme.Text.primary)
                            Text(deload.reason)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if !viewModel.recentPainLogs.isEmpty {
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            HStack {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(AppTheme.Accent.orange)
                                    .accessibilityHidden(true)

                                Text("Return to Lifting")
                                    .font(AppTheme.Typography.headlineMedium)
                                    .foregroundColor(AppTheme.Text.primary)
                            }

                            Text("Active pain was logged recently. Follow your ramp plan to ease back into full training loads.")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            NavigationLink(destination: PainTrackingView()) {
                                Label("View Pain & Ramp Details", systemImage: "arrow.right.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .artDecoButton(style: .secondary)
                        }
                    }
                }

                if viewModel.score == nil && !viewModel.isLoading {
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("Improve Today's Score")
                                .font(AppTheme.Typography.headlineMedium)
                                .foregroundColor(AppTheme.Text.primary)

                            Text("Recovery works best after a recent workout, a pain check-in, cycle context, and available Apple Health sleep or HRV data.")
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            NavigationLink(destination: PainTrackingView()) {
                                Label("Log Pain or Soreness", systemImage: "bandage")
                                    .frame(maxWidth: .infinity)
                            }
                            .artDecoButton(style: .secondary)

                            NavigationLink(destination: CycleTrackingView()) {
                                Label("Update Cycle", systemImage: "calendar.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .artDecoButton(style: .secondary)
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .navigationTitle("Recovery")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            await viewModel.loadScore(
                cyclePhase: cyclePhaseCache.currentPhase,
                isGuest: authViewModel.isGuest
            )
        }
    }
}
