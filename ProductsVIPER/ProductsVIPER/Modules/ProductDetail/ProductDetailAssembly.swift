import SwiftUI

enum ProductDetailAssembly {
    @MainActor
    static func make(productID: Product.ID, repository: any ProductRepository) -> ProductDetailView {
        let interactor = ProductDetailInteractor(repository: repository)
        let presenter = ProductDetailPresenter(productID: productID, interactor: interactor)
        return ProductDetailView(presenter: presenter)
    }
}
