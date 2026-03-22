import StoreKit

/// Production implementation of TransactionVerifying using StoreKit 2.
struct StoreKitTransactionVerifier: TransactionVerifying {
    func currentEntitlements() async -> [String] {
        var activeIDs: [String] = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    activeIDs.append(transaction.productID)
                }
            }
        }
        return activeIDs
    }
}
