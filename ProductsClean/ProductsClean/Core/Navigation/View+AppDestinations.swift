import SwiftUI

extension View {
    /// The one place that turns a `Route` into a screen.
    /// Screens do not know how other screens are created — they only say "I want Route X".
    func withAppDestinations(_ dependencies: AppDependencies) -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .productDetail(let id):
                ProductDetailView(productID: id, repository: dependencies.productRepository)
            }
        }
    }
}
