import Foundation

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
            favoritesStore: FavoritesStore(persistence: UserDefaultsFavoritesPersistence(key: "productsviper.favorites.products"))
        )
    }

    static func preview() -> AppDependencies {
        AppDependencies(
            productRepository: PreviewProductRepository(),
            favoritesStore: FavoritesStore(persistence: InMemoryFavoritesPersistence())
        )
    }
}
