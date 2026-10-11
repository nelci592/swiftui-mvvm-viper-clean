import Foundation

final class FavoritesInteractor: FavoritesInteractorInput {
    private let favorites: any FavoritesServicing

    init(favorites: any FavoritesServicing) {
        self.favorites = favorites
    }

    var products: [Product] { favorites.products }
    var totalPrice: Decimal { favorites.totalPrice }

    func remove(atOffsets offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
    }
}
