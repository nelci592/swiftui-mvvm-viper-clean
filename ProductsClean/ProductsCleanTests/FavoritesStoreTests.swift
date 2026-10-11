import Foundation
import Testing
@testable import ProductsClean

@MainActor
struct FavoritesStoreTests {
    @Test func toggleAddsAndRemovesAndPersists() {
        let persistence = InMemoryFavoritesPersistence()
        let store = FavoritesStore(persistence: persistence)
        let product = Product.fixture(id: 1)

        store.toggle(product)
        #expect(store.isFavorite(1))
        #expect(persistence.storedProducts.map(\.id) == [1])

        store.toggle(product)
        #expect(!store.isFavorite(1))
        #expect(persistence.storedProducts.isEmpty)
    }

    @Test func restoresFavoritesFromPersistence() {
        let persistence = InMemoryFavoritesPersistence(products: [.fixture(id: 7)])

        let store = FavoritesStore(persistence: persistence)

        #expect(store.isFavorite(7))
        #expect(store.products.count == 1)
    }

    @Test func newestFavoriteIsFirst() {
        let store = FavoritesStore(persistence: InMemoryFavoritesPersistence())

        store.toggle(.fixture(id: 1))
        store.toggle(.fixture(id: 2))

        #expect(store.products.map(\.id) == [2, 1])
    }

    @Test func removeAtOffsets() {
        let store = FavoritesStore(persistence: InMemoryFavoritesPersistence(products: [.fixture(id: 1), .fixture(id: 2)]))

        store.remove(atOffsets: IndexSet(integer: 0))

        #expect(store.products.map(\.id) == [2])
        #expect(!store.isFavorite(1))
    }

    @Test func totalPriceSumsDiscountedPrices() {
        let store = FavoritesStore(persistence: InMemoryFavoritesPersistence(products: [
            .fixture(id: 1, price: 100, discountPercentage: 10),
            .fixture(id: 2, price: Decimal(string: "0.10")!),
            .fixture(id: 3, price: Decimal(string: "0.20")!),
        ]))

        #expect(store.totalPrice == Decimal(string: "90.30"))
    }

    @Test func userDefaultsPersistenceRoundTrip() throws {
        let suiteName = "FavoritesStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let persistence = UserDefaultsFavoritesPersistence(defaults: defaults)

        persistence.save([.fixture(id: 3)])

        #expect(persistence.load().map(\.id) == [3])
    }
}
