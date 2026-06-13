import Combine
import Foundation
import StoreKit
import os.log

private let supportTipLogger = Logger(subsystem: "com.sundeefundee.app", category: "SupportTip")

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor StoreKitSupportTipStore: SupportTipStoreProtocol {
    private var cachedProduct: Product?

    public init() {}

    public func loadSupportTip() async throws -> SupportTipOffer {
        let product = try await supportProduct()
        return SupportTipOffer(
            id: product.id,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice
        )
    }

    public func purchaseSupportTip() async -> SupportTipPurchaseOutcome {
        do {
            let product = try await supportProduct()
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                return await handleTransaction(verificationResult)
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed
            }
        } catch let error as SupportTipStoreError {
            supportTipLogger.error("Support tip purchase failed: \(String(describing: error))")
            switch error {
            case .productUnavailable:
                return .unavailable
            case .unexpectedProductType:
                return .failed
            case .unverifiedTransaction:
                return .unverified
            case .storeKitFailure:
                return .failed
            }
        } catch {
            supportTipLogger.error("Support tip purchase failed: \(String(describing: error))")
            return .failed
        }
    }

    public func handleTransactionUpdate(_ verificationResult: VerificationResult<Transaction>) async {
        _ = await handleTransaction(verificationResult)
    }

    private func supportProduct() async throws -> Product {
        if let cachedProduct {
            return cachedProduct
        }

        let products = try await Product.products(for: [SupportTipProduct.id])
        guard let product = products.first else {
            throw SupportTipStoreError.productUnavailable
        }
        guard product.type == .consumable else {
            throw SupportTipStoreError.unexpectedProductType
        }

        cachedProduct = product
        return product
    }

    private func handleTransaction(_ verificationResult: VerificationResult<Transaction>) async -> SupportTipPurchaseOutcome {
        switch verificationResult {
        case .verified(let transaction):
            guard transaction.productID == SupportTipProduct.id else {
                await transaction.finish()
                return .failed
            }
            await transaction.finish()
            return .purchased
        case .unverified:
            return .unverified
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class SupportTipTransactionListener: ObservableObject {
    private let store: StoreKitSupportTipStore
    private var updatesTask: Task<Void, Never>?

    public init(store: StoreKitSupportTipStore = StoreKitSupportTipStore()) {
        self.store = store
    }

    public func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [store] in
            for await verificationResult in Transaction.updates {
                await store.handleTransactionUpdate(verificationResult)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }
}
