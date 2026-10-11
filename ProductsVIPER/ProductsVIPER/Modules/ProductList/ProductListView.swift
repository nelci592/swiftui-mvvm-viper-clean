import SwiftUI

/// The View in VIPER: it has no business logic and does not know about the repository.
/// It only calls methods on the Presenter (ViewOutput) and renders the Presenter's state.
struct ProductListView: View {
    @State private var presenter: ProductListPresenter

    init(presenter: ProductListPresenter) {
        _presenter = State(initialValue: presenter)
    }

    var body: some View {
        content
            .navigationTitle("Products")
            .searchable(text: $presenter.searchText, prompt: "Search products")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SortMenu(selection: $presenter.sort)
                }
            }
            .task(id: presenter.query) {
                await presenter.viewDidChangeQuery()
            }
            .alert("Couldn't refresh", isPresented: $presenter.isShowingRefreshError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(presenter.refreshErrorMessage ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch presenter.state {
        case .idle, .loading:
            ProgressView("Loading products…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            if presenter.query.text.isEmpty {
                ContentUnavailableView("No products", systemImage: "bag")
            } else {
                ContentUnavailableView.search(text: presenter.query.text)
            }
        case .failed(let message):
            ContentUnavailableView {
                Label("Something went wrong", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") {
                    Task { await presenter.didTapRetry() }
                }
                .buttonStyle(.borderedProminent)
            }
        case .loaded:
            productList
        }
    }

    private var productList: some View {
        List {
            ForEach(presenter.products) { product in
                // Not NavigationLink(value:): navigation goes through Presenter → Router.
                Button {
                    presenter.didSelectProduct(id: product.id)
                } label: {
                    ProductRowView(product: product)
                }
                .buttonStyle(.plain)
            }

            if presenter.canLoadMore {
                NextPageFooter(errorMessage: presenter.nextPageErrorMessage) {
                    Task { await presenter.didScrollToBottom() }
                }
                .task(id: presenter.products.count) {
                    await presenter.didScrollToBottom()
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await presenter.didPullToRefresh()
        }
    }
}
