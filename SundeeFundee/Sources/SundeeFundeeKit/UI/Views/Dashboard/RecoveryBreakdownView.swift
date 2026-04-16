import Charts
import SwiftUI

// MARK: - RecoveryBreakdownView
//
// Detail screen pushed from the dashboard's RecoveryScoreCard.
// Shows the 5 input bars with sub-scores and explanations, followed
// by the 30-day trend chart with cycle phase bands.
// Per UI-SPEC D-04, D-05, D-06, D-07.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct RecoveryBreakdownView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: RecoveryScoreViewModel

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Section: Today's Inputs (D-04)
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Today's Inputs")
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Text.primary)

                    ForEach(Array(RecoveryInput.allCases.enumerated()), id: \.element) { index, input in
                        InputBarRow(
                            input: input,
                            subScore: viewModel.score?.subScores[input],
                            explanation: viewModel.score?.explanations[input],
                            animationDelay: Double(index) * 0.1
                        )
                    }
                }

                // Divider (per UI-SPEC)
                Divider()
                    .background(AppTheme.Accent.gold.opacity(0.3))

                // Section: 30-Day Trend (D-06)
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("30-Day Trend")
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Text.primary)

                    RecoveryTrendChart(
                        scores: viewModel.historicalScores,
                        phaseBands: viewModel.phaseBands
                    )
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .navigationTitle("Recovery Breakdown")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            // Lazy load history + phase bands when breakdown view appears.
            // loadHistory() fetches PeriodLog + CycleSettings and calls
            // computePhaseBands internally -- phaseBands will be non-empty
            // when cycle data exists (D-07).
            await viewModel.loadHistory()
        }
    }
}
