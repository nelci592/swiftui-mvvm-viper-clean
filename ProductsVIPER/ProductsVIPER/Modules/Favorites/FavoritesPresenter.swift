import Foundation
import Observation

/// The Presenter does not keep a copy of the favorites — it reads them through the Interactor from the shared store.
/// The View observes the store through the Environment for the badge and hearts; only the screen's actions live here.
@Observable
final class FavoritesPresenter: FavoritesViewOutput {
    @ObservationIgnored private let interactor: any FavoritesInteractorInput
    @ObservationIgnored private let router: any FavoritesRouterInput

    init(interactor: any FavoritesInteractorInput, router: any FavoritesRouterInput) {
        self.interactor = interactor
        self.router = router
    }

    var products: [Product] { interactor.products }
    var totalPrice: Decimal { interactor.totalPrice }

    func didSelectProduct(id: Product.ID) {
        router.openProductDetail(id: id)
    }

    func didDelete(at offsets: IndexSet) {
        interactor.remove(atOffsets: offsets)
    }

    func didTapBrowseProducts() {
        router.switchToProductsTab()
    }
}
