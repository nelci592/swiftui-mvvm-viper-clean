import SwiftUI

struct ProductRowView: View {
    /// Usually `let` — the row only displays data, it does not own it.
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: product.thumbnailURL)
                .frame(width: 64, height: 64)
                .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(2)
                if let brand = product.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    PriceView(product: product)
                    Spacer()
                    RatingView(rating: product.rating)
                }
            }

            FavoriteButton(product: product)
                // Without this, in a `List` with `NavigationLink`, tapping the button
                // activates the whole row (navigates) instead of only the button.
                .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
        // Accessibility: VoiceOver reads the row as one meaningful sentence.
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        ProductRowView(product: .sample)
        ProductRowView(product: .sampleWithoutBrand)
    }
    .environment(FavoritesStore(persistence: InMemoryFavoritesPersistence()))
}
