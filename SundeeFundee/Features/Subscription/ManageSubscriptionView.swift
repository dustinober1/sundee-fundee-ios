import SwiftUI
import StoreKit

/// Subscription management screen shown from Settings.
struct ManageSubscriptionView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var showPaywall = false

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            List {
                currentPlanSection
                if appState.subscriptionTier != .free {
                    usageSection
                    manageSection
                } else {
                    upgradeSection
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Subscription")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Sections

    private var currentPlanSection: some View {
        Section("Current Plan") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.subscriptionTier.displayName)
                        .font(AppTheme.Fonts.subheading)
                        .foregroundStyle(AppTheme.Colors.navy)
                    Text(Self.tierDescription(appState.subscriptionTier))
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                }
                Spacer()
                PremiumBadge(tier: appState.subscriptionTier)
            }
        }
    }

    private var usageSection: some View {
        Section("This Month") {
            let used = AIUsageTracker.usageThisMonth()
            let limit = FeatureEntitlement.aiWorkoutLimit(for: appState.subscriptionTier)
            HStack {
                Text("AI Workouts")
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                Spacer()
                Text(Self.usageText(used: used, limit: limit))
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }
        }
    }

    private var manageSection: some View {
        Section {
            Button("Manage in App Store") {
                Task {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        try? await AppStore.showManageSubscriptions(in: windowScene)
                    }
                }
            }
            .font(AppTheme.Fonts.body)
            .foregroundStyle(AppTheme.Colors.accentOrange)
        }
    }

    private var upgradeSection: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(AppTheme.Colors.gold)
                    Text("Upgrade")
                        .font(AppTheme.Fonts.subheading)
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.3))
                }
            }
        }
    }

    // MARK: - Static Helpers

    static func tierDescription(_ tier: SubscriptionTier) -> String {
        switch tier {
        case .free:    return "Basic workout tracking"
        case .plus:    return "Enhanced training intelligence"
        case .premium: return "Full AI-powered coaching"
        }
    }

    static func usageText(used: Int, limit: Int?) -> String {
        if let limit {
            return "\(used) of \(limit) used"
        }
        return "\(used) used (unlimited)"
    }
}
