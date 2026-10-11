import SwiftUI

struct FavoritesView: View {
    @State private var presenter: FavoritesPresenter
    /// The store stays in the Environment because SwiftUI must redraw when it changes
    /// (a heart in another tab). The Presenter is not the single source for this shared state.
    @Environment(FavoritesStore.self) private var favorites

    init(presenter: FavoritesPresenter) {
        _presenter = State(initialValue: presenter)
    }

    var body: some View {
        Group {
            if favorites.products.isEmpty {
                ContentUnavailableView {
                    Label("No favorites yet", systemImage: "heart")
                } description: {
                    Text("Tap the heart on any product to save it here.")
                } actions: {
                    Button("Browse products") { presenter.didTapBrowseProducts() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    Section {
                        ForEach(favorites.products) { product in
                            Button {
                                presenter.didSelectProduct(id: product.id)
                            } label: {
                                ProductRowView(product: product)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { presenter.didDelete(at: $0) }
                    } footer: {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(favorites.totalPrice, format: .currency(code: "USD"))
                                .bold()
                        }
                        .font(.body)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationTitle("Favorites")
    }
}
