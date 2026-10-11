import Foundation

/// Interactor = business logic and data for this screen.
///
/// It does not know about SwiftUI, does not format strings for the UI, and does not decide whether to show a spinner.
/// It only runs the use case: "give me a page of products".
final class ProductListInteractor: ProductListInteractorInput {
    private let repository: any ProductRepository

    init(repository: any ProductRepository) {
        self.repository = repository
    }

    func fetchProducts(query: String, sort: ProductSort, skip: Int, limit: Int) async throws -> ProductPage {
        try await repository.fetchProducts(query: query, sort: sort, skip: skip, limit: limit)
    }
}
