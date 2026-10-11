import SwiftUI

struct ProductDetailView: View {
    @State private var presenter: ProductDetailPresenter
    @State private var isDescriptionExpanded = false

    init(presenter: ProductDetailPresenter) {
        _presenter = State(initialValue: presenter)
    }

    var body: some View {
        Group {
            switch presenter.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn't load product", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try again") { Task { await presenter.didTapRetry() } }
                        .buttonStyle(.borderedProminent)
                }
            case .loaded(let product):
                content(for: product)
            }
        }
        .navigationTitle(presenter.state.value?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let product = presenter.state.value {
                ToolbarItem(placement: .topBarTrailing) {
                    FavoriteButton(product: product)
                }
            }
        }
        .task {
            await presenter.viewDidAppear()
        }
    }

    private func content(for product: Product) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ImageGallery(urls: product.imageURLs)

                VStack(alignment: .leading, spacing: 8) {
                    if let brand = product.brand {
                        Text(brand.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(product.title)
                        .font(.title2.bold())
                    HStack {
                        PriceView(product: product)
                        Spacer()
                        RatingView(rating: product.rating)
                    }
                    Text(product.isInStock ? "In stock: \(product.stock)" : "Out of stock")
                        .font(.footnote)
                        .foregroundStyle(product.isInStock ? .green : .red)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.description)
                        .lineLimit(isDescriptionExpanded ? nil : 3)
                    Button(isDescriptionExpanded ? "Show less" : "Show more") {
                        withAnimation { isDescriptionExpanded.toggle() }
                    }
                    .font(.footnote)
                }

                if !product.reviews.isEmpty {
                    ReviewsSection(reviews: product.reviews)
                }
            }
            .padding()
        }
    }
}

private struct ImageGallery: View {
    let urls: [URL]

    var body: some View {
        TabView {
            ForEach(urls, id: \.self) { url in
                RemoteImage(url: url, contentMode: .fit)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: 280)
        .background(.quaternary.opacity(0.3), in: .rect(cornerRadius: 16))
    }
}

private struct ReviewsSection: View {
    let reviews: [Review]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reviews")
                .font(.headline)
            ForEach(reviews, id: \.self) { review in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(review.author).font(.subheadline.bold())
                        Spacer()
                        Text(review.date, format: .dateTime.day().month().year())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(String(repeating: "★", count: review.rating) + String(repeating: "☆", count: 5 - review.rating))
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("\(review.rating) out of 5 stars")
                    Text(review.comment)
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 12))
            }
        }
    }
}
