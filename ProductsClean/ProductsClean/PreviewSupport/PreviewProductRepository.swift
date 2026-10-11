import Foundation

/// A fake repository for SwiftUI Previews — works offline and instantly.
/// This is a direct benefit of ViewModels depending on a protocol.
nonisolated struct PreviewProductRepository: ProductRepository {
    enum Behavior: Sendable {
        case success
        case empty
        case failure
    }

    var behavior: Behavior = .success
    var delay: Duration = .milliseconds(300)

    func fetchProducts(query: String, sort: ProductSort, skip: Int, limit: Int) async throws -> ProductPage {
        try await Task.sleep(for: delay)
        switch behavior {
        case .success:
            let matching = query.isEmpty
                ? Product.samples
                : Product.samples.filter { $0.title.localizedStandardContains(query) }
            return ProductPage(items: matching, total: matching.count, skip: skip)
        case .empty:
            return ProductPage(items: [], total: 0, skip: skip)
        case .failure:
            throw NetworkError.transport(.notConnectedToInternet)
        }
    }

    func fetchProduct(id: Product.ID) async throws -> Product {
        try await Task.sleep(for: delay)
        guard behavior == .success, let product = Product.samples.first(where: { $0.id == id }) else {
            throw NetworkError.httpStatus(404)
        }
        return product
    }
}
