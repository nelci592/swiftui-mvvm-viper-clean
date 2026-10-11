import Foundation

// DTO (Data Transfer Object) = an exact copy of the JSON from the API.
// We decode only the fields we need — the rest are ignored automatically.

nonisolated struct ProductListResponseDTO: Decodable, Sendable {
    let products: [ProductDTO]
    let total: Int
    let skip: Int
    let limit: Int
}

nonisolated struct ProductDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Double
    let discountPercentage: Double
    let rating: Double
    let stock: Int
    /// About a third of the products have no `brand` in the JSON. If this were `String`
    /// (not optional), decoding the ENTIRE list would fail with `keyNotFound`.
    let brand: String?
    let thumbnail: String?
    let images: [String]?
    let reviews: [ReviewDTO]?
}

nonisolated struct ReviewDTO: Decodable, Sendable {
    let rating: Int
    let comment: String
    let date: Date
    let author: String

    /// `CodingKeys` maps JSON names to Swift names.
    /// (For a snake_case API, `decoder.keyDecodingStrategy = .convertFromSnakeCase` can be used instead.)
    private enum CodingKeys: String, CodingKey {
        case rating
        case comment
        case date
        case author = "reviewerName"
    }
}

// MARK: - Mapping DTO -> Domain

nonisolated extension ProductDTO {
    func toDomain() -> Product {
        Product(
            id: id,
            title: title,
            description: description,
            category: category,
            // `Decimal(price)` would carry over the Double error (e.g. 9.99 -> 9.9900000000000002).
            // Going through String gives the exact decimal value.
            price: Decimal(string: String(price)) ?? Decimal(price),
            discountPercentage: discountPercentage,
            rating: rating,
            stock: stock,
            brand: brand,
            thumbnailURL: thumbnail.flatMap(URL.init(string:)),
            imageURLs: (images ?? []).compactMap(URL.init(string:)),
            reviews: (reviews ?? []).map { $0.toDomain() }
        )
    }
}

nonisolated extension ReviewDTO {
    func toDomain() -> Review {
        Review(rating: rating, comment: comment, author: author, date: date)
    }
}

nonisolated extension ProductListResponseDTO {
    func toDomain() -> ProductPage {
        ProductPage(items: products.map { $0.toDomain() }, total: total, skip: skip)
    }
}
