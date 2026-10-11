import Foundation

/// A shared service outside the VIPER modules.
///
/// VIPER describes *one screen*. Favorites are needed by the list, the detail, the tab, and the badge at the same time,
/// so they do not live in any Presenter. They are injected into the Interactors (and into the SwiftUI Environment
/// for small controls such as the heart on a row).
protocol FavoritesServicing: AnyObject {
    var products: [Product] { get }
    var totalPrice: Decimal { get }
    func isFavorite(_ id: Product.ID) -> Bool
    func toggle(_ product: Product)
    func remove(atOffsets offsets: IndexSet)
}
