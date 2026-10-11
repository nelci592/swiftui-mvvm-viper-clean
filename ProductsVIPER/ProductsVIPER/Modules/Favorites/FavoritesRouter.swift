import Foundation

final class FavoritesRouter: FavoritesRouterInput {
    private let appRouter: AppRouter

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func openProductDetail(id: Product.ID) {
        appRouter.show(.productDetail(id: id), in: .favorites)
    }

    func switchToProductsTab() {
        appRouter.selectedTab = .products
    }
}
