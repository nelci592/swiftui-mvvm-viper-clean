import Foundation
import Observation

@Observable
final class ProductDetailPresenter: ProductDetailViewOutput {
    let productID: Product.ID
    private(set) var state: Loadable<Product> = .idle

    @ObservationIgnored private let interactor: any ProductDetailInteractorInput

    init(productID: Product.ID, interactor: any ProductDetailInteractorInput) {
        self.productID = productID
        self.interactor = interactor
    }

    func viewDidAppear() async {
        if state.isLoaded { return }
        state = .loading
        do {
            state = .loaded(try await interactor.fetchProduct(id: productID))
        } catch let error where error.isCancellation {
            return
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    func didTapRetry() async {
        state = .idle
        await viewDidAppear()
    }
}
