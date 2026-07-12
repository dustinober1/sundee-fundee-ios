import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ReadinessCardView: View {
    let snapshot: DailyReadinessUISnapshot
    let guidance: String
    let isStale: Bool
    let onDetails: () -> Void

    public init(snapshot: DailyReadinessUISnapshot, guidance: String, isStale: Bool = false, onDetails: @escaping () -> Void) {
        self.snapshot = snapshot; self.guidance = guidance; self.isStale = isStale; self.onDetails = onDetails
    }

    public var body: some View {
        Button(action: { HapticFeedback.light(); onDetails() }) {
            ArtDecoCard {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        Label("Daily Readiness", systemImage: "gauge.with.dots.needle.67percent")
                            .font(AppTheme.Typography.headlineMedium)
                        Spacer()
                        Image(systemName: "chevron.right").accessibilityHidden(true)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                        Text("\(snapshot.totalScore)").font(AppTheme.Typography.displayMedium.monospacedDigit()).foregroundStyle(AppTheme.recoveryColor(for: snapshot.totalScore))
                        Text(snapshot.state.rawValue.capitalized).font(AppTheme.Typography.headlineMedium)
                        Text(snapshot.confidence.rawValue.capitalized + " confidence").font(AppTheme.Typography.bodySmall).foregroundStyle(AppTheme.Text.secondary)
                    }
                    Text(guidance).font(AppTheme.Typography.bodyMedium).foregroundStyle(AppTheme.Text.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    if isStale { Label("Stale score", systemImage: "clock.badge.exclamationmark").font(AppTheme.Typography.labelSmall).foregroundStyle(AppTheme.Accent.orange) }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Daily readiness, \(snapshot.totalScore) out of 100, \(snapshot.state.rawValue)")
        .accessibilityHint("Open readiness details")
    }
}
