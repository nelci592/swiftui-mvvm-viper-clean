import SwiftUI

@main
struct ProductsVIPERApp: App {
    @State private var dependencies = AppDependencies.live()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .environment(router)
                .environment(dependencies.favoritesStore)
                .onOpenURL { url in
                    router.handle(url: url)
                }
        }
    }
}
