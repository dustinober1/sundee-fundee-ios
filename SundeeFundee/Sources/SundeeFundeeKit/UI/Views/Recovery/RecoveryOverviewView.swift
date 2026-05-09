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
