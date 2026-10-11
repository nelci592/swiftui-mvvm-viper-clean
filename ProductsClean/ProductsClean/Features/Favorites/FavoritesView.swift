import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesStore.self) private var favorites
    @Environment(AppRouter.self) private var router

    var body: some View {
        Group {
            if favorites.products.isEmpty {
                ContentUnavailableView {
                    Label("No favorites yet", systemImage: "heart")
                } description: {
                    Text("Tap the heart on any product to save it here.")
                } actions: {
                    // Navigation between tabs through the shared router.
                    Button("Browse products") { router.selectedTab = .products }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    Section {
                        ForEach(favorites.products) { product in
                            NavigationLink(value: Route.productDetail(id: product.id)) {
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
    NavigationStack {
        FavoritesView()
    }
    .environment(FavoritesStore(persistence: InMemoryFavoritesPersistence(products: Product.samples)))
    .environment(AppRouter())
}
