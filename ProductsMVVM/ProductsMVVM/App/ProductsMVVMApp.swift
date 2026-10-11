import SwiftUI

@main
struct ProductsMVVMApp: App {
    @State private var api = ProductAPI.live
    @State private var favorites = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            RootView(api: api)
                .environment(favorites)
        }
    }
}
