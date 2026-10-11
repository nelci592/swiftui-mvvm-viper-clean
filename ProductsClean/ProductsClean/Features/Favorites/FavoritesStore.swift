import Foundation
import Observation

/// Shared (app-wide) state: which products are favorites.
///
/// It is used from three places at once — the list, the detail screen, and the "Favorites" tab
/// (including the tab badge). That is why it lives OUTSIDE any single screen and is
/// injected into the SwiftUI Environment: `.environment(favoritesStore)`.
///
/// `@Observable` (Observation framework, iOS 17+): SwiftUI tracks which properties
/// the View read in `body` and recomputes it only when THOSE change.
/// (Unlike `ObservableObject`, where every `@Published` change
/// invalidates every observing View.)
///
/// The class is `MainActor` (the project's default isolation) — UI state changes only on the main thread.
@Observable
final class FavoritesStore {
    /// `private(set)`: the outside world can read, but cannot write directly.
    /// Changes go only through the methods below → a single, predictable data flow.
    private(set) var products: [Product]

    /// Index for an O(1) `isFavorite` check — called for every row in the list.
    private var ids: Set<Product.ID>

    @ObservationIgnored private let persistence: any FavoritesPersistence

    init(persistence: any FavoritesPersistence) {
        self.persistence = persistence
        let stored = persistence.load()
        products = stored
        ids = Set(stored.map(\.id))
    }

    /// Derived (computed) state — not stored separately, so it cannot drift out of sync.
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
        persistence.save(products)
    }
}
