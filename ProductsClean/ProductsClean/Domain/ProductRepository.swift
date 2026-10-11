import Foundation

/// Repository pattern: a single access point for products.
///
/// ViewModels do not know where the data comes from — network, cache, database, or
/// fake data for Previews and tests. They only know this protocol.
nonisolated protocol ProductRepository: Sendable {
    /// An empty `query` means "all products".
    func fetchProducts(
        query: String,
        sort: ProductSort,
        skip: Int,
        limit: Int
    ) async throws -> ProductPage

    func fetchProduct(id: Product.ID) async throws -> Product
}
