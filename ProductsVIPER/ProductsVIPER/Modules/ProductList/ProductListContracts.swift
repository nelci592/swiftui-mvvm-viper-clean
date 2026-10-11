import Foundation

/// Contracts for the Product List module.
///
/// In VIPER every arrow between layers is a protocol. That lets the Presenter be tested with a
/// fake Interactor/Router, without SwiftUI and without a network.
///
/// Arrows (classic VIPER):
///   View  --events-->  Presenter  --requests-->  Interactor
///   View  <--state---  Presenter  <--entities--  Interactor
///   Presenter --navigation--> Router

enum ProductListViewState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(message: String)
}

struct ProductListQuery: Hashable {
    var text: String
    var sort: ProductSort
}

/// What the View calls (user events). The Presenter implements the protocol.
@MainActor
protocol ProductListViewOutput: AnyObject {
    func viewDidChangeQuery() async
    func didPullToRefresh() async
    func didTapRetry() async
    func didScrollToBottom() async
    func didSelectProduct(id: Product.ID)
}

/// The screen's use cases. The repository is called only here.
protocol ProductListInteractorInput: AnyObject {
    func fetchProducts(query: String, sort: ProductSort, skip: Int, limit: Int) async throws -> ProductPage
}

/// Navigation out of the module. The Presenter does not know about TabView / NavigationStack.
@MainActor
protocol ProductListRouterInput: AnyObject {
    func openProductDetail(id: Product.ID)
}
