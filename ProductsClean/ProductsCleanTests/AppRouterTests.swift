import Foundation
import Testing
@testable import ProductsClean

@MainActor
struct AppRouterTests {
    @Test func productDeepLinkOpensDetailOnProductsTab() throws {
        let router = AppRouter()
        router.selectedTab = .favorites
        router.productsPath = [.productDetail(id: 1)]

        let handled = router.handle(url: try #require(URL(string: "productsclean://products/42")))

        #expect(handled)
        #expect(router.selectedTab == .products)
        #expect(router.productsPath == [.productDetail(id: 42)])
    }

    @Test func favoritesDeepLinkSwitchesTabAndPopsToRoot() throws {
        let router = AppRouter()
        router.favoritesPath = [.productDetail(id: 1)]

        router.handle(url: try #require(URL(string: "productsclean://favorites")))

        #expect(router.selectedTab == .favorites)
        #expect(router.favoritesPath.isEmpty)
    }

    @Test(arguments: ["https://products/1", "productsclean://unknown", "productsclean://"])
    func unsupportedLinksAreIgnored(link: String) throws {
        let router = AppRouter()

        let handled = router.handle(url: try #require(URL(string: link)))

        #expect(!handled)
        #expect(router.selectedTab == .products)
        #expect(router.productsPath.isEmpty)
    }
}
