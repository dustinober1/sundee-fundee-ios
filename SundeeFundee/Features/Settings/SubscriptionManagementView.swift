import SwiftUI
import StoreKit

/// Subscription management — show current tier, upgrade option, restore purchases.
struct SubscriptionManagementView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var message: String?

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            Form {
                Section("Current Subscription") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(subscriptionService.isPremium ? "Premium" : "Free")
                            .foregroundStyle(subscriptionService.isPremium ? AppTheme.Colors.accentOrange : AppTheme.Colors.navy.opacity(0.6))
                            .fontWeight(.semibold)
                    }
                }

                if !subscriptionService.isPremium {
                    Section("Upgrade to Premium") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Get unlimited AI workout generation")
                                .font(AppTheme.Fonts.body)

                            BulletPoint("Unlimited personalized workouts")
                            BulletPoint("Advanced prompt context (benchmarks, cycle phase)")
                            BulletPoint("Skill-focused training programs")

                            if let product = products.first {
                                Button(action: { purchaseSubscription(product) }) {
                                    if isLoading {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        Text("Subscribe for \(product.displayPrice)")
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

    private func loadProducts() async {
        do {
            let allProducts = try await Product.products(for: SubscriptionTier.allProductIDs)
            products = allProducts
        } catch {
            message = "Failed to load products: \(error.localizedDescription)"
        }
    }

    private func purchaseSubscription(_ product: Product) {
        isLoading = true
        Task {
            do {
                try await subscriptionService.purchase(product)
                message = "Thank you for subscribing!"
            } catch {
                message = "Purchase failed: \(error.localizedDescription)"
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
