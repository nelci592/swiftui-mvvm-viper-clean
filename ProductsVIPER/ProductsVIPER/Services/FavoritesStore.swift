import Foundation
import Observation

@Observable
final class FavoritesStore: FavoritesServicing {
    private(set) var products: [Product]
    private var ids: Set<Product.ID>
    @ObservationIgnored private let persistence: any FavoritesPersistence

    init(persistence: any FavoritesPersistence) {
        self.persistence = persistence
        let stored = persistence.load()
        products = stored
        ids = Set(stored.map(\.id))
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
        persistence.save(products)
    }
}
