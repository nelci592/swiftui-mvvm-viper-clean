import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    @Environment(AppRouter.self) private var router
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        // `@Environment` is read-only. `@Bindable` lets us make a
        // Binding (`$router.selectedTab`) to properties of an @Observable object.
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab("Products", systemImage: "bag", value: AppTab.products) {
                // A separate NavigationStack per tab → each tab keeps its own history.
                NavigationStack(path: $router.productsPath) {
                    ProductListView(repository: dependencies.productRepository)
                        .withAppDestinations(dependencies)
                }
            }

            Tab("Favorites", systemImage: "heart", value: AppTab.favorites) {
                NavigationStack(path: $router.favoritesPath) {
                    FavoritesView()
                        .withAppDestinations(dependencies)
                }
            }
            // The badge updates automatically as soon as the shared state changes.
            .badge(favorites.products.count)
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    RootView(dependencies: dependencies)
        .environment(AppRouter())
        .environment(dependencies.favoritesStore)
}
