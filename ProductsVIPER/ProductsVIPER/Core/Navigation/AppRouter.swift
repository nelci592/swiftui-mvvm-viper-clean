import Foundation
import Observation

enum AppTab: Hashable {
    case products
    case favorites
}

/// Every destination in the app.
///
/// We pass only the `id`, not the whole `Product`: the route stays small and `Hashable`,
/// and it can be created from a deep link or push notification, where we only have an ID.
enum Route: Hashable {
    case productDetail(id: Product.ID)
}

/// Router (a Coordinator-style pattern for SwiftUI).
///
/// Navigation is *state*: `NavigationStack(path:)` shows exactly the screens
/// in the array. Because navigation is data, we can change it programmatically
/// (deep links, "pop to root", switching tabs) and test it without UI.
@Observable
final class AppRouter {
    var selectedTab: AppTab = .products
    var productsPath: [Route] = []
    var favoritesPath: [Route] = []

    func show(_ route: Route, in tab: AppTab) {
        selectedTab = tab
        switch tab {
        case .products: productsPath.append(route)
        case .favorites: favoritesPath.append(route)
        }
    }

    func popToRoot(in tab: AppTab) {
        switch tab {
        case .products: productsPath.removeAll()
        case .favorites: favoritesPath.removeAll()
        }
    }

    /// Supported links:
    /// - `productsviper://products`
    /// - `productsviper://products/42`
    /// - `productsviper://favorites`
    @discardableResult
    func handle(url: URL) -> Bool {
        guard url.scheme == "productsviper", let host = url.host() else { return false }
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch (host, pathComponents.first.flatMap(Int.init)) {
        case ("products", let id?):
            popToRoot(in: .products)
            show(.productDetail(id: id), in: .products)
        case ("products", nil):
            popToRoot(in: .products)
            selectedTab = .products
        case ("favorites", _):
            popToRoot(in: .favorites)
            selectedTab = .favorites
        default:
            return false
        }
        return true
    }
}
