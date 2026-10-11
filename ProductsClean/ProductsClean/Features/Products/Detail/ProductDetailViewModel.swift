import Foundation
import Observation

/// A simpler ViewModel: one value, described by the generic `Loadable<Product>`.
@Observable
final class ProductDetailViewModel {
    let productID: Product.ID
    private(set) var state: Loadable<Product> = .idle

    @ObservationIgnored private let repository: any ProductRepository

    init(productID: Product.ID, repository: any ProductRepository) {
        self.productID = productID
        self.repository = repository
    }

    func load() async {
        if state.isLoaded { return }

        state = .loading
        do {
            state = .loaded(try await repository.fetchProduct(id: productID))
        } catch let error where error.isCancellation {
            // On the next appearance `load()` will try again, because state is not `.loaded`.
            return
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    func retry() async {
        state = .idle
        await load()
    }
}
