import SwiftUI

enum FavoritesAssembly {
    @MainActor
    static func make(favorites: any FavoritesServicing, appRouter: AppRouter) -> FavoritesView {
        let interactor = FavoritesInteractor(favorites: favorites)
        let router = FavoritesRouter(appRouter: appRouter)
        let presenter = FavoritesPresenter(interactor: interactor, router: router)
        return FavoritesView(presenter: presenter)
    }
}
