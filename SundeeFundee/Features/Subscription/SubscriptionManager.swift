import StoreKit
import SwiftUI

// MARK: - Protocols for Testability

protocol ProductLoading: Sendable {
    func loadProducts(for ids: Set<String>) async throws -> [Product]
}

protocol TransactionVerifying: Sendable {
    func currentEntitlements() async -> [String]
}

// MARK: - SubscriptionManager

@Observable
@MainActor
final class SubscriptionManager {
    var currentTier: SubscriptionTier = .free
    var availableProducts: [Product] = []
    var purchaseInProgress = false
    var errorMessage: String?

    private var transactionListener: Task<Void, Never>?
    private let productLoader: any ProductLoading
    private let transactionVerifier: any TransactionVerifying

    init(
        productLoader: any ProductLoading = StoreKitProductLoader(),
        transactionVerifier: any TransactionVerifying = StoreKitTransactionVerifier()
    ) {
        self.productLoader = productLoader
        self.transactionVerifier = transactionVerifier
    }

    nonisolated deinit {
    }

    func start() async {
        // All features are free — bypass StoreKit entirely
        currentTier = .premium
    }

    func purchase(_ product: Product) async {
        purchaseInProgress = true
        errorMessage = nil
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshSubscriptionStatus()
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshSubscriptionStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Static Helpers (Testable)

    static func tierFromProductID(_ productID: String?) -> SubscriptionTier {
        guard let productID else { return .free }
        return SubscriptionTier.fromProductID(productID)
    }

    static func highestTier(from activeProductIDs: [String]) -> SubscriptionTier {
        activeProductIDs
            .map { SubscriptionTier.fromProductID($0) }
            .max(by: { $0.rank < $1.rank }) ?? .free
    }

    static func sortedProducts(_ products: [Product]) -> [Product] {
        products.sorted { $0.price < $1.price }
    }

    static func monthlyProducts(from products: [Product]) -> [Product] {
        products.filter { product in
            product.id.contains(".monthly")
        }
    }

    static func annualProducts(from products: [Product]) -> [Product] {
        products.filter { product in
            product.id.contains(".annual")
        }
    }

    // MARK: - Private

    private func loadProducts() async {
        do {
            let products = try await productLoader.loadProducts(for: SubscriptionTier.allProductIDs)
            availableProducts = Self.sortedProducts(products)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshSubscriptionStatus() async {
        let activeIDs = await transactionVerifier.currentEntitlements()
        currentTier = Self.highestTier(from: activeIDs)
    }

    private func listenForTransactions() {
        transactionListener?.cancel()
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshSubscriptionStatus()
                }
            }
        }
    }
}
