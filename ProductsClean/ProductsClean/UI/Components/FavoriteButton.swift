import SwiftUI

/// Reads the shared `FavoritesStore` from the Environment.
/// We do not have to pass it by hand through every parent View ("prop drilling").
struct FavoriteButton: View {
    let product: Product
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        let isFavorite = favorites.isFavorite(product.id)
        Button {
            favorites.toggle(product)
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(isFavorite ? .red : .secondary)
                .contentTransition(.symbolEffect(.replace))
                .frame(minWidth: 44, minHeight: 44)
        }
        .sensoryFeedback(.selection, trigger: isFavorite)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }
}
