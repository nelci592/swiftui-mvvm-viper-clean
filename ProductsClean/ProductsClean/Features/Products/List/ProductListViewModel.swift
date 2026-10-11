import Foundation
import Observation

/// ViewModel for the product list (MVVM).
///
/// The View is "dumb": it renders `state` and sends intents —
/// `loadIfNeeded()`, `refresh()`, `loadNextPage()`. All the logic lives here and is
/// tested with unit tests without UI (see `ProductListViewModelTests`).
///
/// Data flow (unidirectional data flow):
///   User action -> View -> ViewModel method -> Repository -> ViewModel state -> View re-render
@Observable
final class ProductListViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failed(message: String)
    }

    /// The combination of inputs that decides what we show.
    /// Used as the `id` of `.task(id:)` in the View.
    struct Query: Hashable {
        var text: String
        var sort: ProductSort
    }

    // MARK: - State (readable by the View)

    private(set) var state: State = .idle
    private(set) var products: [Product] = []
    private(set) var isLoadingNextPage = false
    private(set) var nextPageErrorMessage: String?
    private(set) var refreshErrorMessage: String?

    // MARK: - Input (bound to controls through Binding)

    var searchText = ""
    var sort: ProductSort = .relevance

    // MARK: - Derived state

    var query: Query {
        Query(text: searchText.trimmingCharacters(in: .whitespacesAndNewlines), sort: sort)
    }

    var canLoadMore: Bool {
        state == .loaded && products.count < total
    }

    /// Custom getter/setter so `.alert(isPresented:)` can bind to an optional message.
    var isShowingRefreshError: Bool {
        get { refreshErrorMessage != nil }
        set { if !newValue { refreshErrorMessage = nil } }
    }

    // MARK: - Private

    @ObservationIgnored private let repository: any ProductRepository
    @ObservationIgnored private let pageSize: Int
    @ObservationIgnored private let searchDebounce: Duration
    private var total = 0
    /// The query for which the current `products` were loaded.
    private var loadedQuery: Query?
    /// Incremented on every fresh load from the first page. A response that arrives with
    /// an older `generation` is stale and is ignored (protection against a race condition).
    private var generation = 0

    init(
        repository: any ProductRepository,
        pageSize: Int = 20,
        searchDebounce: Duration = .milliseconds(350)
    ) {
        self.repository = repository
        self.pageSize = pageSize
        self.searchDebounce = searchDebounce
    }

    // MARK: - Intents

    /// Called from `.task(id: viewModel.query)`. SwiftUI automatically cancels
    /// the previous Task when `query` changes → that gives us debounce "for free":
    /// if the user types another character during `Task.sleep`, the sleep throws
    /// `CancellationError` and the old request never starts.
    func loadIfNeeded() async {
        let query = query
        // Idempotency: `.task` runs every time the View appears
        // (for example, returning from another tab) — we do not reload if we already have the data.
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

    /// Pull-to-refresh: keep the current content visible while loading.
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
            let page = try await repository.fetchProducts(
                query: loadedQuery.text,
                sort: loadedQuery.sort,
                skip: products.count,
                limit: pageSize
            )
            guard requestGeneration == generation else { return }
            // Guard against duplicates if the backend added items between requests.
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

    // MARK: - Loading

    private func reload(_ query: Query, showsLoading: Bool) async {
        generation += 1
        let requestGeneration = generation
        isLoadingNextPage = false
        nextPageErrorMessage = nil

        if showsLoading || products.isEmpty {
            state = .loading
        }

        do {
            let page = try await repository.fetchProducts(
                query: query.text,
                sort: query.sort,
                skip: 0,
                limit: pageSize
            )
            // While we were waiting on the network, a newer load may have started.
            // MainActor does NOT protect us from that — between `await` points the code can interleave.
            guard requestGeneration == generation else { return }

            products = page.items
            total = page.total
            loadedQuery = query
            state = page.items.isEmpty ? .empty : .loaded
        } catch let error where error.isCancellation {
            // Cancellation is not an error: a newer Task took over, or the View disappeared.
            return
        } catch {
            guard requestGeneration == generation else { return }

            if query == loadedQuery && !products.isEmpty {
                // Failed refresh: do not wipe content that is already on screen.
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
