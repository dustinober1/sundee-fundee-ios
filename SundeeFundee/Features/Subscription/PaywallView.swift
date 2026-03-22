import SwiftUI
import StoreKit

/// Custom Art Deco themed paywall for Sundee Plus and Sundee Premium.
struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let triggeredBy: GatedFeature?

    @State private var billingPeriod: BillingPeriod = .monthly
    @State private var selectedTier: SubscriptionTier = .plus
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    enum BillingPeriod: String, CaseIterable {
        case monthly = "Monthly"
        case annual = "Annual"
    }

    init(triggeredBy: GatedFeature? = nil) {
        self.triggeredBy = triggeredBy
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    headerSection
                    billingToggle
                    tierCards
                    featureComparison
                    subscribeButton
                    restoreLink
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.4))
            }
            .padding(AppTheme.Spacing.md)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.gold)

            Text(Self.headerTitle(triggeredBy: triggeredBy))
                .font(AppTheme.Fonts.heading)
                .foregroundStyle(AppTheme.Colors.navy)
                .multilineTextAlignment(.center)

            Text(Self.headerSubtitle(triggeredBy: triggeredBy))
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppTheme.Spacing.xl)
    }

    private var billingToggle: some View {
        Picker("Billing", selection: $billingPeriod) {
            ForEach(BillingPeriod.allCases, id: \.self) { period in
                Text(period == .annual ? "Annual (Save 33%)" : period.rawValue)
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var tierCards: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            tierCard(for: .plus)
            tierCard(for: .premium)
        }
    }

    private func tierCard(for tier: SubscriptionTier) -> some View {
        let isSelected = selectedTier == tier
        let product = productFor(tier: tier)

        return VStack(spacing: AppTheme.Spacing.sm) {
            if tier == .premium {
                Text("BEST VALUE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.cream)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.Colors.accentOrange)
                    .clipShape(Capsule())
            } else {
                Text(" ")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.vertical, 3)
            }

            Text(tier.displayName.replacingOccurrences(of: "Sundee ", with: ""))
                .font(AppTheme.Fonts.subheading)
                .foregroundStyle(AppTheme.Colors.navy)

            if let product {
                Text(product.displayPrice)
                    .font(AppTheme.Font.heading(24))
                    .foregroundStyle(AppTheme.Colors.navy)
                Text(Self.periodLabel(for: billingPeriod))
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            } else {
                Text(Self.fallbackPrice(tier: tier, period: billingPeriod))
                    .font(AppTheme.Font.heading(24))
                    .foregroundStyle(AppTheme.Colors.navy)
                Text(Self.periodLabel(for: billingPeriod))
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Self.tierHighlights(for: tier), id: \.self) { highlight in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.accentOrange)
                        Text(highlight)
                            .font(AppTheme.Fonts.caption)
                            .foregroundStyle(AppTheme.Colors.navy)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(isSelected ? AppTheme.Colors.gold.opacity(0.1) : AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(isSelected ? AppTheme.Colors.gold : AppTheme.Colors.separator, lineWidth: isSelected ? 2 : 1)
        )
        .onTapGesture { selectedTier = tier }
    }

    private var featureComparison: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("COMPARE PLANS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accentOrange)
                .tracking(1.5)

            ForEach(Self.comparisonRows(), id: \.feature) { row in
                HStack {
                    Text(row.feature)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy)
                    Spacer()
                    Text(row.free)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                        .frame(width: 50)
                    Text(row.plus)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy)
                        .frame(width: 50)
                    Text(row.premium)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                        .frame(width: 50)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }

    private var subscribeButton: some View {
        Button {
            guard let product = productFor(tier: selectedTier) else { return }
            Task {
                isPurchasing = true
                await subscriptionManager.purchase(product)
                isPurchasing = false
                if subscriptionManager.currentTier != .free {
                    dismiss()
                }
            }
        } label: {
            if isPurchasing {
                ProgressView()
                    .tint(AppTheme.Colors.cream)
                    .frame(maxWidth: .infinity)
            } else {
                Text(Self.ctaText(for: selectedTier))
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isPurchasing || productFor(tier: selectedTier) == nil)

    }

    private var restoreLink: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Button("Restore Purchases") {
                Task { await subscriptionManager.restorePurchases() }
            }
            .font(AppTheme.Fonts.caption)
            .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))

            if case .guest = appState.authState {
                Text("Sign in to subscribe")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
            }

            if let error = subscriptionManager.errorMessage {
                Text(error)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.error)
            }
        }
        .padding(.bottom, AppTheme.Spacing.lg)
    }

    // MARK: - Helpers

    private func productFor(tier: SubscriptionTier) -> Product? {
        let targetID = billingPeriod == .monthly ? tier.monthlyProductID : tier.annualProductID
        return subscriptionManager.availableProducts.first { $0.id == targetID }
    }

    // MARK: - Static Helpers (Testable)

    static func headerTitle(triggeredBy feature: GatedFeature?) -> String {
        if let feature {
            return "Unlock \(feature.displayName)"
        }
        return "Upgrade Your Training"
    }

    static func headerSubtitle(triggeredBy feature: GatedFeature?) -> String {
        if let feature {
            return feature.featureDescription
        }
        return "Get more from every workout with Sundee Plus or Premium."
    }

    static func ctaText(for tier: SubscriptionTier) -> String {
        "Subscribe to \(tier.displayName)"
    }

    static func periodLabel(for period: BillingPeriod) -> String {
        period == .monthly ? "per month" : "per year"
    }

    static func fallbackPrice(tier: SubscriptionTier, period: BillingPeriod) -> String {
        switch (tier, period) {
        case (.plus, .monthly):    return "$4.99"
        case (.plus, .annual):     return "$39.99"
        case (.premium, .monthly): return "$9.99"
        case (.premium, .annual):  return "$79.99"
        default:                   return "Free"
        }
    }

    static func tierHighlights(for tier: SubscriptionTier) -> [String] {
        switch tier {
        case .free:
            return []
        case .plus:
            return [
                "15 AI workouts/month",
                "Pain trend analysis",
                "Effort trends",
                "WOD execution",
                "Unlimited tracking",
                "Custom benchmarks",
            ]
        case .premium:
            return [
                "Unlimited AI workouts",
                "Everything in Plus",
                "Rehab sessions",
                "AI workout history",
                "Export data",
            ]
        }
    }

    struct ComparisonRow: Sendable {
        let feature: String
        let free: String
        let plus: String
        let premium: String
    }

    static func comparisonRows() -> [ComparisonRow] {
        [
            ComparisonRow(feature: "AI Workouts", free: "3/mo", plus: "15/mo", premium: "Unlimited"),
            ComparisonRow(feature: "Lift Tracking", free: "5", plus: "All", premium: "All"),
            ComparisonRow(feature: "Injury Profiles", free: "1", plus: "All", premium: "All"),
            ComparisonRow(feature: "Workout History", free: "30 days", plus: "All", premium: "All"),
            ComparisonRow(feature: "Pain Trends", free: "--", plus: "Yes", premium: "Yes"),
            ComparisonRow(feature: "Effort Trends", free: "--", plus: "Yes", premium: "Yes"),
            ComparisonRow(feature: "WOD Execution", free: "--", plus: "Yes", premium: "Yes"),
            ComparisonRow(feature: "Custom Benchmarks", free: "--", plus: "Yes", premium: "Yes"),
            ComparisonRow(feature: "Rehab Sessions", free: "--", plus: "--", premium: "Yes"),
            ComparisonRow(feature: "AI History", free: "--", plus: "--", premium: "Yes"),
            ComparisonRow(feature: "Export Data", free: "--", plus: "--", premium: "Yes"),
        ]
    }

    static func savingsText(monthlyPrice: Decimal, annualPrice: Decimal) -> String {
        let yearlyIfMonthly = monthlyPrice * Decimal(12)
        guard yearlyIfMonthly > 0 else { return "" }
        let saved = yearlyIfMonthly - annualPrice
        let percent = NSDecimalNumber(decimal: saved * Decimal(100) / yearlyIfMonthly).intValue
        return "Save \(percent)%"
    }
}
