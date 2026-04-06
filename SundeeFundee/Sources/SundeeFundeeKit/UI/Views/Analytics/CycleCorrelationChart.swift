import SwiftUI
import Charts

// MARK: - CycleCorrelationChart

/// Bar chart showing average training volume by menstrual cycle phase.
///
/// Pro-gated: free users see an upgrade card with a lock icon and CTA
/// instead of chart data. Paid users see a BarMark chart with
/// phase-appropriate colors (menstrual=red, follicular=gold, ovulation=orange, luteal=navy).

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct CycleCorrelationChart: View {
    let data: [CyclePerformancePoint]
    let hasAccess: Bool
    @State private var showingSubscription = false

    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Section header
                HStack {
                    Text("Cycle Correlation")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    if !hasAccess {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                }

                if !hasAccess {
                    upgradeCard
                } else if data.isEmpty {
                    emptyState
                } else {
                    chartContent
                }
            }
        }
    }

    // MARK: - Upgrade Card

    private var upgradeCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("See how your cycle affects performance")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                Text("Track volume, frequency, and intensity across menstrual, follicular, ovulation, and luteal phases.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary.opacity(0.8))
            }

            Button {
                showingSubscription = true
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 14))
                    Text("Unlock with Plus")
                        .font(AppTheme.Typography.labelLarge)
                }
                .foregroundColor(AppTheme.Accent.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(AppTheme.Accent.gold.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
    }

    // MARK: - Chart

    private var chartContent: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Phase", phaseLabel(point.phase)),
                y: .value("Avg Volume", point.averageVolume)
            )
            .foregroundStyle(phaseColor(point.phase).gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
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
            Image(systemName: "heart.text.square")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.Text.secondary.opacity(0.5))

            Text("Track cycle phases to see correlation")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Helpers

    private func phaseLabel(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulation: return "Ovulation"
        case .luteal: return "Luteal"
        }
    }

    private func phaseColor(_ phase: CyclePhase) -> Color {
        switch phase {
        case .menstrual: return .red
        case .follicular: return AppTheme.Accent.gold
        case .ovulation: return AppTheme.Accent.orange
        case .luteal: return AppTheme.Background.navy
        }
    }
}
