import Foundation
import Observation

@Observable
final class ProductDetailViewModel {
    let productID: Product.ID
    private(set) var state: Loadable<Product> = .idle

    @ObservationIgnored private let api: ProductAPI

    init(productID: Product.ID, api: ProductAPI) {
        self.productID = productID
        self.api = api
    }

    func load() async {
        if state.isLoaded { return }

        state = .loading
        do {
            state = .loaded(try await api.fetchProduct(id: productID))
        } catch let error where error.isCancellation {
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
