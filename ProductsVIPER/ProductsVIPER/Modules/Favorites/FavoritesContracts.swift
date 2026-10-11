import Foundation

@MainActor
protocol FavoritesViewOutput: AnyObject {
    func didSelectProduct(id: Product.ID)
    func didDelete(at offsets: IndexSet)
    func didTapBrowseProducts()
}

protocol FavoritesInteractorInput: AnyObject {
    var products: [Product] { get }
    var totalPrice: Decimal { get }
    func remove(atOffsets offsets: IndexSet)
}

@MainActor
protocol FavoritesRouterInput: AnyObject {
    func openProductDetail(id: Product.ID)
    func switchToProductsTab()
}
