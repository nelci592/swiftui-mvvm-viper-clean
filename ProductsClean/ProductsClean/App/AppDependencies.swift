import Foundation

/// Composition Root: the ONLY place where concrete implementations
/// are created and wired together.
///
/// The rest of the code depends only on protocols (`ProductRepository`, `HTTPClient`)
/// and receives its dependencies through `init` (constructor injection).
/// Swapping the real API for a fake one (Preview, UI tests, staging) is then a one-line change.
final class AppDependencies {
    let productRepository: any ProductRepository
    let favoritesStore: FavoritesStore

    init(productRepository: any ProductRepository, favoritesStore: FavoritesStore) {
        self.productRepository = productRepository
        self.favoritesStore = favoritesStore
    }

    static func live() -> AppDependencies {
        let client = URLSessionHTTPClient(baseURL: URL(string: "https://dummyjson.com")!)
        return AppDependencies(
            productRepository: RemoteProductRepository(client: client),
            favoritesStore: FavoritesStore(persistence: UserDefaultsFavoritesPersistence())
        )
    }

    static func preview() -> AppDependencies {
        AppDependencies(
            productRepository: PreviewProductRepository(),
            favoritesStore: FavoritesStore(persistence: InMemoryFavoritesPersistence())
        )
    }
}
