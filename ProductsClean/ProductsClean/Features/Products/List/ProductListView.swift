import SwiftUI

struct ProductListView: View {
    /// `@State` + an `@Observable` class: the View OWNS the ViewModel.
    /// SwiftUI keeps the instance for as long as the View is in the hierarchy, even when
    /// the `ProductListView` struct is recreated on every parent update.
    /// (The `ObservableObject` equivalent is `@StateObject`.)
    @State private var viewModel: ProductListViewModel

    init(repository: any ProductRepository) {
        _viewModel = State(initialValue: ProductListViewModel(repository: repository))
    }

    var body: some View {
        content
            .navigationTitle("Products")
            // `$viewModel.searchText` — a Binding to a property of an @Observable object.
            .searchable(text: $viewModel.searchText, prompt: "Search products")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SortMenu(selection: $viewModel.sort)
                }
            }
            // The Task is tied to the View's lifetime: it is cancelled when the View disappears
            // and restarted when `id` changes.
            .task(id: viewModel.query) {
                await viewModel.loadIfNeeded()
            }
            .alert("Couldn't refresh", isPresented: $viewModel.isShowingRefreshError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.refreshErrorMessage ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading products…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            if viewModel.query.text.isEmpty {
                ContentUnavailableView("No products", systemImage: "bag")
            } else {
                ContentUnavailableView.search(text: viewModel.query.text)
            }

        case .failed(let message):
            ContentUnavailableView {
                Label("Something went wrong", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.borderedProminent)
            }

        case .loaded:
            productList
        }
    }

    private var productList: some View {
        List {
            ForEach(viewModel.products) { product in
                // Value-based navigation: the link only appends a `Route` to the path.
                NavigationLink(value: Route.productDetail(id: product.id)) {
                    ProductRowView(product: product)
                }
            }

            if viewModel.canLoadMore {
                NextPageFooter(errorMessage: viewModel.nextPageErrorMessage) {
                    Task { await viewModel.loadNextPage() }
                }
                // A sentinel row at the end of the list: when it appears, we load the next page.
                // `id: products.count` — restarts the task if the row is still visible after loading.
                .task(id: viewModel.products.count) {
                    await viewModel.loadNextPage()
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
    }
}

#Preview("Loaded") {
    let dependencies = AppDependencies.preview()
    NavigationStack {
        ProductListView(repository: dependencies.productRepository)
    }
    .environment(dependencies.favoritesStore)
}

#Preview("Error") {
    NavigationStack {
        ProductListView(repository: PreviewProductRepository(behavior: .failure))
    }
    .environment(FavoritesStore(persistence: InMemoryFavoritesPersistence()))
}
