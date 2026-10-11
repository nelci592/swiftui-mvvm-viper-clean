import Foundation
import Testing
@testable import ProductsClean

/// The ViewModel is `@MainActor`, so the tests run on the MainActor as well.
@MainActor
struct ProductListViewModelTests {
    @Test func initialLoadShowsProducts() async {
        let repository = StubProductRepository { _ in .fixture(ids: 1...2, total: 2) }
        let viewModel = ProductListViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.products.map(\.id) == [1, 2])
        #expect(viewModel.canLoadMore == false)
    }

    @Test func emptyResponseShowsEmptyState() async {
        let repository = StubProductRepository { _ in .fixture(ids: [], total: 0) }
        let viewModel = ProductListViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .empty)
    }

    @Test func failureShowsErrorState() async {
        let error = NetworkError.transport(.notConnectedToInternet)
        let repository = StubProductRepository { _ in throw error }
        let viewModel = ProductListViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .failed(message: error.localizedDescription))
        #expect(viewModel.products.isEmpty)
    }

    @Test func loadIfNeededIsIdempotent() async {
        let repository = StubProductRepository { _ in .fixture(ids: 1...2, total: 2) }
        let viewModel = ProductListViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(repository.requests.count == 1)
    }

    @Test func nextPageAppendsItems() async {
        let repository = StubProductRepository { request in
            request.skip == 0
                ? .fixture(ids: 1...2, total: 4)
                : .fixture(ids: 3...4, total: 4, skip: request.skip)
        }
        let viewModel = ProductListViewModel(repository: repository, pageSize: 2)

        await viewModel.loadIfNeeded()
        #expect(viewModel.canLoadMore)

        await viewModel.loadNextPage()

        #expect(viewModel.products.map(\.id) == [1, 2, 3, 4])
        #expect(repository.requests.map(\.skip) == [0, 2])
        #expect(viewModel.canLoadMore == false)
    }

    @Test func nextPageFailureKeepsLoadedItems() async {
        let repository = StubProductRepository { request in
            guard request.skip == 0 else { throw NetworkError.httpStatus(500) }
            return .fixture(ids: 1...2, total: 4)
        }
        let viewModel = ProductListViewModel(repository: repository, pageSize: 2)

        await viewModel.loadIfNeeded()
        await viewModel.loadNextPage()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.products.map(\.id) == [1, 2])
        #expect(viewModel.nextPageErrorMessage != nil)
    }

    @Test func failedRefreshKeepsExistingContent() async {
        let counter = Counter()
        let repository = StubProductRepository { _ in
            await counter.increment()
            guard await counter.value == 1 else { throw NetworkError.transport(.timedOut) }
            return .fixture(ids: 1...2, total: 2)
        }
        let viewModel = ProductListViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        await viewModel.refresh()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.products.map(\.id) == [1, 2])
        #expect(viewModel.isShowingRefreshError)
    }

    /// Classic race condition: the request for "old" responds AFTER the request for "new".
    /// Without the `generation` check, the screen would show the results for "old".
    @Test func staleResponseIsIgnored() async {
        let gate = Gate()
        let repository = StubProductRepository { request in
            if request.query == "old" {
                await gate.enterAndWait()
                return ProductPage(items: [.fixture(id: 1, title: "old")], total: 1, skip: 0)
            }
            return ProductPage(items: [.fixture(id: 2, title: "new")], total: 1, skip: 0)
        }
        let viewModel = ProductListViewModel(repository: repository)

        viewModel.searchText = "old"
        let oldRequest = Task { await viewModel.refresh() }
        await gate.waitUntilEntered()

        viewModel.searchText = "new"
        await viewModel.refresh()

        await gate.release()
        await oldRequest.value

        #expect(viewModel.products.map(\.title) == ["new"])
        #expect(viewModel.state == .loaded)
    }

    /// A cancelled Task (the user kept typing) must not reach the network.
    @Test func cancelledSearchDoesNotHitNetwork() async {
        let repository = StubProductRepository { _ in .fixture(ids: 1...2, total: 2) }
        let viewModel = ProductListViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        viewModel.searchText = "phone"
        let search = Task { await viewModel.loadIfNeeded() }
        search.cancel()
        await search.value

        #expect(repository.requests.count == 1)
    }

    @Test func searchUsesTrimmedQueryAndSort() async {
        let repository = StubProductRepository { _ in .fixture(ids: 1...1, total: 1) }
        let viewModel = ProductListViewModel(repository: repository, searchDebounce: .zero)
        await viewModel.loadIfNeeded()

        viewModel.searchText = "  phone "
        viewModel.sort = .priceHighToLow
        await viewModel.loadIfNeeded()

        #expect(repository.requests.last == .init(query: "phone", sort: .priceHighToLow, skip: 0, limit: 20))
    }
}
