import SwiftUI

struct PriceView: View {
    let product: Product

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(product.discountedPrice, format: .currency(code: "USD"))
                .font(.subheadline.bold())
            if product.discountPercentage > 0 {
                Text(product.price, format: .currency(code: "USD"))
                    .font(.caption)
                    .strikethrough()
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Original price \(product.price.formatted(.currency(code: "USD")))")
            }
        }
    }
}
