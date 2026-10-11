import SwiftUI

enum AppTab: Hashable {
    case products
    case favorites
}

struct RootView: View {
    let api: ProductAPI
    @State private var selectedTab: AppTab = .products
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Products", systemImage: "bag", value: AppTab.products) {
                NavigationStack {
                    ProductListView(api: api)
                }
            }

            Tab("Favorites", systemImage: "heart", value: AppTab.favorites) {
                NavigationStack {
                    FavoritesView(api: api, selectedTab: $selectedTab)
                }
            }
            .badge(favorites.products.count)
        }
    }
}

#Preview {
    RootView(api: .preview)
        .environment(FavoritesStore(previewProducts: Product.samples))
}
