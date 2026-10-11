import Foundation
import Observation

/// Shared app state for favorites. Lives outside any one screen and is injected
/// with `.environment(favoritesStore)`. Persistence is UserDefaults — no protocol,
/// because this project is MVVM only, not Clean Architecture.
@Observable
final class FavoritesStore {
    private(set) var products: [Product]
    private var ids: Set<Product.ID>

    @ObservationIgnored private let defaults: UserDefaults?
    @ObservationIgnored private let key: String

    init(defaults: UserDefaults = .standard, key: String = "productsmvvm.favorites.products") {
        self.defaults = defaults
        self.key = key
        let stored = Self.load(from: defaults, key: key)
        products = stored
        ids = Set(stored.map(\.id))
    }

    /// Preview / tests: in memory, nothing is written to disk.
    init(previewProducts: [Product]) {
        defaults = nil
        key = ""
        products = previewProducts
        ids = Set(previewProducts.map(\.id))
    }

    var totalPrice: Decimal {
        products.reduce(Decimal.zero) { $0 + $1.discountedPrice }
    }

    func isFavorite(_ id: Product.ID) -> Bool {
        ids.contains(id)
    }

    func toggle(_ product: Product) {
        if ids.contains(product.id) {
            remove(ids: [product.id])
        } else {
            products.insert(product, at: 0)
            ids.insert(product.id)
            persist()
        }
    }

    func remove(atOffsets offsets: IndexSet) {
        remove(ids: Set(offsets.map { products[$0].id }))
    }

    private func remove(ids idsToRemove: Set<Product.ID>) {
        products.removeAll { idsToRemove.contains($0.id) }
        ids.subtract(idsToRemove)
        persist()
    }

    private func persist() {
        guard let defaults, let data = try? JSONEncoder().encode(products) else { return }
        defaults.set(data, forKey: key)
    }

    private static func load(from defaults: UserDefaults, key: String) -> [Product] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Product].self, from: data)) ?? []
    }
}
