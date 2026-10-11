import Foundation

/// The real `ProductRepository` implementation, which reads from the API.
///
/// Responsibilities:
/// 1. Picks the right endpoint (list or search).
/// 2. Maps DTO -> domain model.
/// 3. Caches product details (through the `AsyncCache` actor).
nonisolated struct RemoteProductRepository: ProductRepository {
    private let client: any HTTPClient
    private let detailCache: AsyncCache<Product.ID, Product>

    init(client: any HTTPClient, detailCache: AsyncCache<Product.ID, Product> = AsyncCache()) {
        self.client = client
        self.detailCache = detailCache
    }

    func fetchProducts(query: String, sort: ProductSort, skip: Int, limit: Int) async throws -> ProductPage {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpoint: Endpoint = trimmedQuery.isEmpty
            ? .products(sort: sort, skip: skip, limit: limit)
            : .searchProducts(query: trimmedQuery, sort: sort, skip: skip, limit: limit)

        return try await client.send(endpoint, as: ProductListResponseDTO.self).toDomain()
    }

    func fetchProduct(id: Product.ID) async throws -> Product {
        // `[client]` capture list: the closure takes a copy of the client, not `self`.
        try await detailCache.value(for: id) { [client] in
            try await client.send(.product(id: id), as: ProductDTO.self).toDomain()
        }
    }
}
