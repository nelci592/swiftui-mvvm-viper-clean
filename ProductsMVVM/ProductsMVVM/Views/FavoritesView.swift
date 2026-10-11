import SwiftUI

struct FavoritesView: View {
    let api: ProductAPI
    @Binding var selectedTab: AppTab
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        Group {
            if favorites.products.isEmpty {
                ContentUnavailableView {
                    Label("No favorites yet", systemImage: "heart")
                } description: {
                    Text("Tap the heart on any product to save it here.")
                } actions: {
                    Button("Browse products") { selectedTab = .products }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    Section {
                        ForEach(favorites.products) { product in
                            NavigationLink {
                                ProductDetailView(productID: product.id, api: api)
                            } label: {
                                ProductRowView(product: product)
                            }
                        }
                        .onDelete { favorites.remove(atOffsets: $0) }
                    } footer: {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(favorites.totalPrice, format: .currency(code: "USD"))
                                .bold()
                        }
                        .font(.body)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationTitle("Favorites")
    }
}

#Preview {
    @Previewable @State var tab = AppTab.favorites
    NavigationStack {
        FavoritesView(api: .preview, selectedTab: $tab)
    }
    .environment(FavoritesStore(previewProducts: Product.samples))
}
