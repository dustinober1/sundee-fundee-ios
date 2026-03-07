import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(\.dismiss) private var dismiss
    let reason: QuestionnaireViewModel.GenerationBlockReason
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        headerSection
                        featureComparison
                        productButtons
                        restoreLink
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppTheme.Colors.navy)
                    }
                }
            }
            .task { await loadProducts() }
        }
    }

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.Colors.accentOrange)

            Text(Self.headline(for: reason))
                .font(AppTheme.Fonts.heading)
                .foregroundStyle(AppTheme.Colors.navy)
                .multilineTextAlignment(.center)

            Text(Self.subtitle(for: reason))
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppTheme.Spacing.lg)
    }

    private var featureComparison: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            featureRow("Offline workouts", free: true, plus: true, pro: true)
            featureRow("Crowdsourced workouts", free: true, plus: true, pro: true)
            featureRow("Cycle tracking", free: true, plus: true, pro: true)
            featureRow("AI workouts", free: false, plus: true, pro: true)
            featureRow("1 AI workout/day", free: false, plus: true, pro: true)
            featureRow("3 AI workouts/day", free: false, plus: false, pro: true)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }

    private func featureRow(_ label: String, free: Bool, plus: Bool, pro: Bool) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy)
            Spacer()
            checkmark(free)
            checkmark(plus)
            checkmark(pro)
        }
    }

    private func checkmark(_ included: Bool) -> some View {
        Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle")
            .foregroundStyle(included ? AppTheme.Colors.accentOrange : AppTheme.Colors.navy.opacity(0.2))
            .frame(width: 44)
    }

    private var productButtons: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(products.sorted(by: { $0.price < $1.price }), id: \.id) { product in
                Button {
                    purchaseProduct(product)
                } label: {
                    VStack(spacing: 4) {
                        Text(Self.tierName(for: product.id))
                            .font(AppTheme.Fonts.subheading)
                        Text("\(product.displayPrice)/month")
                            .font(AppTheme.Fonts.caption)
                        Text("2-week free trial")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(AppTheme.Colors.accentOrange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                }
                .disabled(isLoading)
            }

            if let message {
                Text(message)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.error)
            }
        }
    }

    private var restoreLink: some View {
        Button("Restore Purchases") {
            Task {
                do {
                    try await subscriptionService.restorePurchases()
                    dismiss()
                } catch {
                    message = "Restore failed: \(error.localizedDescription)"
                }
            }
        }
        .font(AppTheme.Fonts.caption)
        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
    }

    // MARK: - Static Helpers

    static func headline(for reason: QuestionnaireViewModel.GenerationBlockReason) -> String {
        switch reason {
        case .needsSubscription:
            "Unlock AI-Powered Workouts"
        case .dailyLimitReached:
            "Need More Workouts?"
        }
    }

    static func subtitle(for reason: QuestionnaireViewModel.GenerationBlockReason) -> String {
        switch reason {
        case .needsSubscription:
            "Get personalized AI workouts tailored to your goals, maxes, and how you're feeling today."
        case .dailyLimitReached:
            "Upgrade to Pro for up to 3 AI workouts per day."
        }
    }

    static func tierName(for productID: String) -> String {
        SubscriptionTier.from(productID: productID).displayName
    }

    private func loadProducts() async {
        do {
            products = try await Product.products(for: SubscriptionTier.allProductIDs)
        } catch {
            message = "Failed to load products."
        }
    }

    private func purchaseProduct(_ product: Product) {
        isLoading = true
        Task {
            do {
                try await subscriptionService.purchase(product)
                dismiss()
            } catch {
                message = "Purchase failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
