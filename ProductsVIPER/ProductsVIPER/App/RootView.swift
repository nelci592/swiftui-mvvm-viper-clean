import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies
    @Environment(AppRouter.self) private var router
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab("Products", systemImage: "bag", value: AppTab.products) {
                NavigationStack(path: $router.productsPath) {
                    ProductListAssembly.make(
                        repository: dependencies.productRepository,
                        appRouter: router,
                        tab: .products
                    )
                    .withVIPERDestinations(dependencies)
                }
            }

            Tab("Favorites", systemImage: "heart", value: AppTab.favorites) {
                NavigationStack(path: $router.favoritesPath) {
                    FavoritesAssembly.make(
                        favorites: dependencies.favoritesStore,
                        appRouter: router
                    )
                    .withVIPERDestinations(dependencies)
                }
            }
            .badge(favorites.products.count)
        }
    }
}

private extension View {
    func withVIPERDestinations(_ dependencies: AppDependencies) -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .productDetail(let id):
                ProductDetailAssembly.make(
                    productID: id,
                    repository: dependencies.productRepository
                )
            }
        }
    }
}
