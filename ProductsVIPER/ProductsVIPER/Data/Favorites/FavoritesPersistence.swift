import Foundation

/// Abstraction over local storage so `FavoritesStore`
/// can be tested without touching the real `UserDefaults`.
protocol FavoritesPersistence {
    func load() -> [Product]
    func save(_ products: [Product])
}

/// `UserDefaults` fits small amounts of data (settings, a few dozen records).
/// For large or relational data, use SwiftData / Core Data; for secrets (tokens), use the Keychain.
struct UserDefaultsFavoritesPersistence: FavoritesPersistence {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "favorites.products") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> [Product] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Product].self, from: data)) ?? []
    }

    func save(_ products: [Product]) {
        guard let data = try? JSONEncoder().encode(products) else { return }
        defaults.set(data, forKey: key)
    }
}

final class InMemoryFavoritesPersistence: FavoritesPersistence {
    private(set) var storedProducts: [Product]

    init(products: [Product] = []) {
        storedProducts = products
    }

    func load() -> [Product] { storedProducts }

    func save(_ products: [Product]) { storedProducts = products }
}
