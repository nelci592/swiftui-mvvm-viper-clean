import Foundation

@MainActor
protocol ProductDetailViewOutput: AnyObject {
    func viewDidAppear() async
    func didTapRetry() async
}

protocol ProductDetailInteractorInput: AnyObject {
    func fetchProduct(id: Product.ID) async throws -> Product
}
