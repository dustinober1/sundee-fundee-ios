import StoreKit

/// Production implementation of ProductLoading using StoreKit 2.
struct StoreKitProductLoader: ProductLoading {
    func loadProducts(for ids: Set<String>) async throws -> [Product] {
        try await Product.products(for: ids)
    }
}
