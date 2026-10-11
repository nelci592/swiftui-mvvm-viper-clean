import Foundation

// Concrete endpoints for the DummyJSON API (https://dummyjson.com/docs/products).

nonisolated extension Endpoint {
    static func products(sort: ProductSort, skip: Int, limit: Int) -> Endpoint {
        Endpoint(
            path: "products",
            queryItems: paginationItems(skip: skip, limit: limit) + sort.queryItems
        )
    }

    static func searchProducts(query: String, sort: ProductSort, skip: Int, limit: Int) -> Endpoint {
        Endpoint(
            path: "products/search",
            queryItems: [URLQueryItem(name: "q", value: query)]
                + paginationItems(skip: skip, limit: limit)
                + sort.queryItems
        )
    }

    static func product(id: Product.ID) -> Endpoint {
        Endpoint(path: "products/\(id)")
    }

    private static func paginationItems(skip: Int, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "skip", value: String(skip)),
        ]
    }
}

private nonisolated extension ProductSort {
    var queryItems: [URLQueryItem] {
        switch self {
        case .relevance:
            []
        case .priceLowToHigh:
            [URLQueryItem(name: "sortBy", value: "price"), URLQueryItem(name: "order", value: "asc")]
        case .priceHighToLow:
            [URLQueryItem(name: "sortBy", value: "price"), URLQueryItem(name: "order", value: "desc")]
        case .rating:
            [URLQueryItem(name: "sortBy", value: "rating"), URLQueryItem(name: "order", value: "desc")]
        }
    }
}
