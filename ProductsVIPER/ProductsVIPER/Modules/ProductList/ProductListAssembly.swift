import SwiftUI

/// Assembly (Builder): the only place that knows the module's concrete classes
/// and wires them together. The View and the Presenter do not construct `ProductListInteractor(...)`.
///
/// This is Dependency Injection at the **screen** level. AppDependencies is DI at the app level.
enum ProductListAssembly {
    @MainActor
    static func make(
        repository: any ProductRepository,
        appRouter: AppRouter,
        tab: AppTab
    ) -> ProductListView {
        let interactor = ProductListInteractor(repository: repository)
        let router = ProductListRouter(appRouter: appRouter, tab: tab)
        let presenter = ProductListPresenter(interactor: interactor, router: router)
        return ProductListView(presenter: presenter)
    }
}
