import SwiftUI
import StoreKit

struct SubscriptionManagementView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var isFetchingProducts = true
    @State private var message: String?

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            Form {
                Section("Current Plan") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(subscriptionService.currentTier.displayName)
                            .foregroundStyle(subscriptionService.isPremium ? AppTheme.Colors.accentOrange : AppTheme.Colors.navy.opacity(0.6))
                            .fontWeight(.semibold)
                    }
                    if subscriptionService.isPremium {
                        HStack {
                            Text("AI Workouts")
                            Spacer()
                            Text(Self.dailyLimitText(for: subscriptionService.currentTier))
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                        }
                    }
                }

                if subscriptionService.currentTier < .pro {
                    Section("Choose a Plan") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            BulletPoint("AI-powered personalized workouts")
                            BulletPoint("Tailored to your goals and maxes")
                            BulletPoint("Cycle-phase aware training")

                            if isFetchingProducts {
                                ProgressView("Loading plans...")
                                    .padding()
                            } else if products.isEmpty {
                                Text("Unable to load subscription plans. Please check your connection.")
                                    .font(AppTheme.Fonts.caption)
                                    .foregroundStyle(AppTheme.Colors.error)
                            } else {
                                ForEach(upgradeProducts, id: \.id) { product in
                                    Button(action: { purchaseSubscription(product) }) {
                                        if isLoading {
                                            ProgressView()
                                                .frame(maxWidth: .infinity)
                                        } else {
                                            VStack(spacing: 4) {
                                                Text(Self.tierName(for: product.id))
                                                    .font(AppTheme.Fonts.subheading)
                                                Text("\(product.displayPrice)/month")
                                                    .font(AppTheme.Fonts.caption)
                                                Text("2-week free trial")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundStyle(AppTheme.Colors.cream.opacity(0.8))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(AppTheme.Spacing.md)
                                            .background(AppTheme.Colors.accentOrange)
                                            .foregroundStyle(AppTheme.Colors.cream)
                                            .cornerRadius(AppTheme.Spacing.sm)
                                        }
                                    }
                                    .disabled(isLoading)
                                }
                            }
                        }
                        .padding(AppTheme.Spacing.sm)
                    }
                }

                Section("Account") {
                    Button("Restore Purchases", action: restorePurchases)
                }

                if let message = message {
                    Section {
                        Text(message)
                            .font(AppTheme.Fonts.caption)
                            .foregroundStyle(AppTheme.Colors.accentOrange)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Subscription")
        .task {
            await loadProducts()
            await subscriptionService.loadStatus()
        }
    }

    private var upgradeProducts: [Product] {
        products
            .filter { SubscriptionTier.from(productID: $0.id) > subscriptionService.currentTier }
            .sorted { $0.price < $1.price }
    }

    static func dailyLimitText(for tier: SubscriptionTier) -> String {
        switch tier {
        case .free: "None"
        case .plus: "1 per day"
        case .pro: "3 per day"
        }
    }

    static func tierName(for productID: String) -> String {
        SubscriptionTier.from(productID: productID).displayName
    }

    private func loadProducts() async {
        do {
            print("[SubscriptionManagementView] Loading products...")
            products = try await Product.products(for: SubscriptionTier.allProductIDs)
            print("[SubscriptionManagementView] Loaded \(products.count) products")
            isFetchingProducts = false
        } catch {
            print("[SubscriptionManagementView] Failed to load products: \(error)")
            message = "Failed to load products: \(error.localizedDescription)"
            isFetchingProducts = false
        }
    }

    private func purchaseSubscription(_ product: Product) {
        print("[SubscriptionManagementView] Purchase initiated for: \(product.id)")
        isLoading = true
        message = nil
        Task {
            do {
                try await subscriptionService.purchase(product)
                print("[SubscriptionManagementView] Purchase successful")
                message = "Thank you for subscribing!"
            } catch {
                print("[SubscriptionManagementView] Purchase failed: \(error)")
                // Don't show error for user cancellation
                if !error.localizedDescription.contains("cancel") {
                    message = "Purchase failed: \(error.localizedDescription)"
                }
            }
            isLoading = false
        }
    }

    private func restorePurchases() {
        Task {
            do {
                try await subscriptionService.restorePurchases()
                message = "Purchases restored!"
            } catch {
                message = "Restore failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - BulletPoint

private struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.accentOrange)

            Text(text)
                .font(AppTheme.Fonts.caption)
        }
    }
}
