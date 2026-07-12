import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ReadinessDetailsSheet: View {
    let snapshot: DailyReadinessUISnapshot
    let guidance: String
    let isStale: Bool
    let onRetry: (() -> Void)?
    let onStartWorkout: (() -> Void)?
    let onShare: (() -> Void)?

    public init(
        snapshot: DailyReadinessUISnapshot,
        guidance: String,
        isStale: Bool = false,
        onRetry: (() -> Void)? = nil,
        onStartWorkout: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil
    ) {
        self.snapshot = snapshot
        self.guidance = guidance
        self.isStale = isStale
        self.onRetry = onRetry
        self.onStartWorkout = onStartWorkout
        self.onShare = onShare
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Today's readiness").font(AppTheme.Typography.displaySmall)
                        Text("\(snapshot.totalScore) / 100 · \(snapshot.state.rawValue.capitalized)").font(AppTheme.Typography.headlineLarge).foregroundStyle(AppTheme.recoveryColor(for: snapshot.totalScore))
                        Text(guidance).font(AppTheme.Typography.bodyLarge)
                    }
                    if isStale { Label("This assessment is stale. Refresh for today's signals.", systemImage: "clock.badge.exclamationmark").font(AppTheme.Typography.bodyMedium).foregroundStyle(AppTheme.Accent.orange) }
                    if !snapshot.positiveReasons.isEmpty { reasonSection(title: "What's helping", reasons: snapshot.positiveReasons, icon: "arrow.up.right") }
                    if !snapshot.cautionReasons.isEmpty { reasonSection(title: "What to consider", reasons: snapshot.cautionReasons, icon: "exclamationmark.triangle") }
                    if let onRetry { Button("Refresh readiness", action: { HapticFeedback.medium(); onRetry() }).artDecoButton(style: .accent) }
                    if let onStartWorkout {
                        Button {
                            HapticFeedback.success()
                            onStartWorkout()
                        } label: {
                            Label("Start today's workout", systemImage: "figure.strengthtraining.traditional")
                                .frame(maxWidth: .infinity)
                        }
                        .artDecoButton(style: .primary)
                        .accessibilityHint("Build a workout using today's readiness guidance")
                    }
                    if let onShare {
                        Button {
                            HapticFeedback.success()
                            onShare()
                        } label: {
                            Label("Share readiness", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .artDecoButton(style: .secondary)
                    }
                }.padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("Readiness details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private func reasonSection(title: String, reasons: [ReadinessReasonCode], icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title).font(AppTheme.Typography.headlineMedium)
            ForEach(reasons, id: \.self) { reason in Label(reason.rawValue.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).capitalized, systemImage: icon).font(AppTheme.Typography.bodyMedium) }
        }
    }
}
