import Foundation

final class ProductDetailInteractor: ProductDetailInteractorInput {
    private let repository: any ProductRepository

    init(repository: any ProductRepository) {
        self.repository = repository
    }

    func fetchProduct(id: Product.ID) async throws -> Product {
        try await repository.fetchProduct(id: id)
    }
}
