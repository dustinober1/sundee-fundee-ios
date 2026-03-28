import SwiftUI

/// View modifier that overlays a locked state and presents the paywall when tapped.
struct FeatureGateModifier: ViewModifier {
    let feature: GatedFeature
    @Environment(AppState.self) private var appState
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        if Self.isLocked(feature: feature, tier: appState.subscriptionTier) {
            content
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            VStack(spacing: AppTheme.Spacing.sm) {
                                PremiumBadge(tier: FeatureEntitlement.minimumTierRequired(for: feature))
                                Text(feature.displayName)
                                    .font(AppTheme.Fonts.caption)
                                    .foregroundStyle(AppTheme.Colors.navy)
                                Text("Tap to upgrade")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.Colors.accentOrange)
                            }
                        }
                }
                .onTapGesture {
                    AnalyticsService.shared.track(.featureGateTapped, properties: ["feature": feature.rawValue])
                    showPaywall = true
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView(triggeredBy: feature)
                }
        } else {
            content
        }
    }

    static func isLocked(feature: GatedFeature, tier: SubscriptionTier) -> Bool {
        !FeatureEntitlement.canAccess(feature: feature, tier: tier)
    }
}

extension View {
    func requiresSubscription(_ feature: GatedFeature) -> some View {
        modifier(FeatureGateModifier(feature: feature))
    }
}
