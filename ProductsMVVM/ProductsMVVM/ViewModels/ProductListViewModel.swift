import Foundation
import Observation

/// List screen ViewModel. The View renders `state` and sends intents.
/// Data comes from `ProductAPI` directly — there is no repository protocol.
@Observable
final class ProductListViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failed(message: String)
    }

    struct Query: Hashable {
        var text: String
        var sort: ProductSort
    }

    private(set) var state: State = .idle
    private(set) var products: [Product] = []
    private(set) var isLoadingNextPage = false
    private(set) var nextPageErrorMessage: String?
    private(set) var refreshErrorMessage: String?

    var searchText = ""
    var sort: ProductSort = .relevance

    var query: Query {
        Query(text: searchText.trimmingCharacters(in: .whitespacesAndNewlines), sort: sort)
    }

    var canLoadMore: Bool {
        state == .loaded && products.count < total
    }

    var isShowingRefreshError: Bool {
        get { refreshErrorMessage != nil }
        set { if !newValue { refreshErrorMessage = nil } }
    }

    @ObservationIgnored private let api: ProductAPI
    @ObservationIgnored private let pageSize: Int
    @ObservationIgnored private let searchDebounce: Duration
    private var total = 0
    private var loadedQuery: Query?
    private var generation = 0

    init(
        api: ProductAPI,
        pageSize: Int = 20,
        searchDebounce: Duration = .milliseconds(350)
    ) {
        self.api = api
        self.pageSize = pageSize
        self.searchDebounce = searchDebounce
    }

    func loadIfNeeded() async {
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

    func refresh() async {
        await reload(query, showsLoading: false)
    }

    func retry() async {
        await reload(query, showsLoading: true)
    }

    func loadNextPage() async {
        guard canLoadMore, !isLoadingNextPage, let loadedQuery else { return }

        let requestGeneration = generation
        isLoadingNextPage = true
        nextPageErrorMessage = nil
        defer {
            if requestGeneration == generation { isLoadingNextPage = false }
        }

        do {
            let page = try await api.fetchProducts(
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

    private func reload(_ query: Query, showsLoading: Bool) async {
        generation += 1
        let requestGeneration = generation
        isLoadingNextPage = false
        nextPageErrorMessage = nil

        if showsLoading || products.isEmpty {
            state = .loading
        }

        do {
            let page = try await api.fetchProducts(
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
