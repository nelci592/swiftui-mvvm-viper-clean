import Foundation

/// The module's Router: turns "I want the detail" into app-wide navigation state.
///
/// In UIKit this is where `pushViewController` would happen. In SwiftUI the Router changes `path`,
/// and `NavigationStack` shows the screen. The detail Assembly is called from Root, not from the View.
final class ProductListRouter: ProductListRouterInput {
    private let appRouter: AppRouter
    private let tab: AppTab

    init(appRouter: AppRouter, tab: AppTab) {
        self.appRouter = appRouter
        self.tab = tab
    }

    func openProductDetail(id: Product.ID) {
        appRouter.show(.productDetail(id: id), in: tab)
    }
}
