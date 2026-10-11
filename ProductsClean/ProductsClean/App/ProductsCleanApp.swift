import SwiftUI

@main
struct ProductsCleanApp: App {
    /// `@State` so they are created once and live for the lifetime of the app.
    @State private var dependencies = AppDependencies.live()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                // Inject shared state into the Environment —
                // available to every View further down the hierarchy.
                .environment(router)
                .environment(dependencies.favoritesStore)
                .onOpenURL { url in
                    router.handle(url: url)
                }
        }
    }
}
