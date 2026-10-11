import Foundation
import Observation

/// Presenter = the brain of the screen.
///
/// - receives events from the View (`ProductListViewOutput`)
/// - asks the Interactor for data
/// - holds state that is **ready for the UI** (`state`, `products`, …)
/// - asks the Router to navigate
///
/// In MVVM this was `ProductListViewModel`. Here it is split: networking lives in the Interactor,
/// navigation lives in the Router, and UI state stays in the Presenter.
@Observable
final class ProductListPresenter: ProductListViewOutput {
    private(set) var state: ProductListViewState = .idle
    private(set) var products: [Product] = []
    private(set) var isLoadingNextPage = false
    private(set) var nextPageErrorMessage: String?
    private(set) var refreshErrorMessage: String?

    var searchText = ""
    var sort: ProductSort = .relevance

    var query: ProductListQuery {
        ProductListQuery(
            text: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
            sort: sort
        )
    }

    var canLoadMore: Bool {
        state == .loaded && products.count < total
    }

    var isShowingRefreshError: Bool {
        get { refreshErrorMessage != nil }
        set { if !newValue { refreshErrorMessage = nil } }
    }

    @ObservationIgnored private let interactor: any ProductListInteractorInput
    @ObservationIgnored private let router: any ProductListRouterInput
    @ObservationIgnored private let pageSize: Int
    @ObservationIgnored private let searchDebounce: Duration

    private var total = 0
    private var loadedQuery: ProductListQuery?
    private var generation = 0

    init(
        interactor: any ProductListInteractorInput,
        router: any ProductListRouterInput,
        pageSize: Int = 20,
        searchDebounce: Duration = .milliseconds(350)
    ) {
        self.interactor = interactor
        self.router = router
        self.pageSize = pageSize
        self.searchDebounce = searchDebounce
    }

    func viewDidChangeQuery() async {
        let query = query
        guard query != loadedQuery else { return }

        let isTypingSearch = loadedQuery != nil && query.text != loadedQuery?.text
        if isTypingSearch {
            do {
                try await Task.sleep(for: searchDebounce)
            } catch {
                return
            }
        }
        await reload(query, showsLoading: true)
    }

    func didPullToRefresh() async {
        await reload(query, showsLoading: false)
    }

    func didTapRetry() async {
        await reload(query, showsLoading: true)
    }

    func didScrollToBottom() async {
        guard canLoadMore, !isLoadingNextPage, let loadedQuery else { return }

        let requestGeneration = generation
        isLoadingNextPage = true
        nextPageErrorMessage = nil
        defer {
            if requestGeneration == generation { isLoadingNextPage = false }
        }

        do {
            let page = try await interactor.fetchProducts(
                query: loadedQuery.text,
                sort: loadedQuery.sort,
                skip: products.count,
                limit: pageSize
            )
            guard requestGeneration == generation else { return }
            let existingIDs = Set(products.map(\.id))
            products += page.items.filter { !existingIDs.contains($0.id) }
            total = page.total
        } catch let error where error.isCancellation {
            return
        } catch {
            guard requestGeneration == generation else { return }
            nextPageErrorMessage = error.localizedDescription
        }
    }

    func didSelectProduct(id: Product.ID) {
        router.openProductDetail(id: id)
    }

    private func reload(_ query: ProductListQuery, showsLoading: Bool) async {
        generation += 1
        let requestGeneration = generation
        isLoadingNextPage = false
        nextPageErrorMessage = nil

        if showsLoading || products.isEmpty {
            state = .loading
        }

        do {
            let page = try await interactor.fetchProducts(
                query: query.text,
                sort: query.sort,
                skip: 0,
                limit: pageSize
            )
            guard requestGeneration == generation else { return }

            products = page.items
            total = page.total
            loadedQuery = query
            state = page.items.isEmpty ? .empty : .loaded
        } catch let error where error.isCancellation {
            return
        } catch {
            guard requestGeneration == generation else { return }

            if query == loadedQuery && !products.isEmpty {
                refreshErrorMessage = error.localizedDescription
                state = .loaded
            } else {
                products = []
                total = 0
                loadedQuery = nil
                state = .failed(message: error.localizedDescription)
            }
        }
    }
}
