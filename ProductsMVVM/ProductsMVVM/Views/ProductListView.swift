import SwiftUI

struct ProductListView: View {
    @State private var viewModel: ProductListViewModel
    private let api: ProductAPI

    init(api: ProductAPI) {
        self.api = api
        _viewModel = State(initialValue: ProductListViewModel(api: api))
    }

    var body: some View {
        content
            .navigationTitle("Products")
            .searchable(text: $viewModel.searchText, prompt: "Search products")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SortMenu(selection: $viewModel.sort)
                }
            }
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
                NavigationLink {
                    ProductDetailView(productID: product.id, api: api)
                } label: {
                    ProductRowView(product: product)
                }
            }

            if viewModel.canLoadMore {
                NextPageFooter(errorMessage: viewModel.nextPageErrorMessage) {
                    Task { await viewModel.loadNextPage() }
                }
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
    NavigationStack {
        ProductListView(api: .preview)
    }
    .environment(FavoritesStore(previewProducts: []))
}

#Preview("Error") {
    NavigationStack {
        ProductListView(api: .previewFailure)
    }
    .environment(FavoritesStore(previewProducts: []))
}
