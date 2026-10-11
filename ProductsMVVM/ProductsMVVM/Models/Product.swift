import Foundation

/// Model in MVVM: the data the UI shows.
///
/// Unlike the Clean app, there is no separate DTO. `Product` is decoded straight from JSON
/// (`CodingKeys` + custom `price` mapping) and also saved to UserDefaults.
nonisolated struct Product: Identifiable, Hashable, Codable, Sendable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Decimal
    let discountPercentage: Double
    let rating: Double
    let stock: Int
    let brand: String?
    let thumbnailURL: URL?
    let imageURLs: [URL]
    let reviews: [Review]

    var isInStock: Bool { stock > 0 }

    var discountedPrice: Decimal {
        let multiplier = Decimal(1) - Decimal(discountPercentage) / 100
        var result = price * multiplier
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, 2, .plain)
        return rounded
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, description, category, price, discountPercentage
        case rating, stock, brand, reviews
        case thumbnailURL = "thumbnail"
        case imageURLs = "images"
    }

    init(
        id: Int,
        title: String,
        description: String,
        category: String,
        price: Decimal,
        discountPercentage: Double,
        rating: Double,
        stock: Int,
        brand: String?,
        thumbnailURL: URL?,
        imageURLs: [URL],
        reviews: [Review]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.price = price
        self.discountPercentage = discountPercentage
        self.rating = rating
        self.stock = stock
        self.brand = brand
        self.thumbnailURL = thumbnailURL
        self.imageURLs = imageURLs
        self.reviews = reviews
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(String.self, forKey: .category)
        let rawPrice = try container.decode(Double.self, forKey: .price)
        price = Decimal(string: String(rawPrice)) ?? Decimal(rawPrice)
        discountPercentage = try container.decode(Double.self, forKey: .discountPercentage)
        rating = try container.decode(Double.self, forKey: .rating)
        stock = try container.decode(Int.self, forKey: .stock)
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        thumbnailURL = try container.decodeIfPresent(URL.self, forKey: .thumbnailURL)
        imageURLs = try container.decodeIfPresent([URL].self, forKey: .imageURLs) ?? []
        reviews = try container.decodeIfPresent([Review].self, forKey: .reviews) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode((price as NSDecimalNumber).doubleValue, forKey: .price)
        try container.encode(discountPercentage, forKey: .discountPercentage)
        try container.encode(rating, forKey: .rating)
        try container.encode(stock, forKey: .stock)
        try container.encodeIfPresent(brand, forKey: .brand)
        try container.encodeIfPresent(thumbnailURL, forKey: .thumbnailURL)
        try container.encode(imageURLs, forKey: .imageURLs)
        try container.encode(reviews, forKey: .reviews)
    }
}

nonisolated struct Review: Hashable, Codable, Sendable {
    let rating: Int
    let comment: String
    let author: String
    let date: Date

    private enum CodingKeys: String, CodingKey {
        case rating, comment, date
        case author = "reviewerName"
    }
}

nonisolated struct ProductPage: Equatable, Sendable {
    let items: [Product]
    let total: Int
    let skip: Int
}

nonisolated enum ProductSort: String, CaseIterable, Identifiable, Sendable {
    case relevance
    case priceLowToHigh
    case priceHighToLow
    case rating

    var id: Self { self }

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

nonisolated extension Product {
    static let sample = Product(
        id: 121,
        title: "iPhone 5s",
        description: "The iPhone 5s is a classic smartphone known for its compact design.",
        category: "smartphones",
        price: Decimal(string: "199.99")!,
        discountPercentage: 12.91,
        rating: 2.83,
        stock: 25,
        brand: "Apple",
        thumbnailURL: URL(string: "https://cdn.dummyjson.com/product-images/smartphones/iphone-5s/thumbnail.webp"),
        imageURLs: [URL(string: "https://cdn.dummyjson.com/product-images/smartphones/iphone-5s/1.webp")!],
        reviews: [Review(rating: 5, comment: "Highly recommended!", author: "Nolan Bryant", date: .now)]
    )

    static let sampleWithoutBrand = Product(
        id: 26,
        title: "Green Chili Pepper",
        description: "Spicy green chili pepper.",
        category: "groceries",
        price: Decimal(string: "0.99")!,
        discountPercentage: 0,
        rating: 3.66,
        stock: 0,
        brand: nil,
        thumbnailURL: URL(string: "https://cdn.dummyjson.com/product-images/groceries/green-chili-pepper/thumbnail.webp"),
        imageURLs: [],
        reviews: []
    )

    static let samples = [sample, sampleWithoutBrand]
}
