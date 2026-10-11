import SwiftUI

struct ProductRowView: View {
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
                .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        ProductRowView(product: .sample)
        ProductRowView(product: .sampleWithoutBrand)
    }
    .environment(FavoritesStore(previewProducts: []))
}
