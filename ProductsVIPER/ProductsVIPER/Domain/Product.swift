import Foundation

/// Domain model — what the app actually works with.
///
/// It is separate from `ProductDTO` (the API's shape). If the backend renames a field,
/// only the DTO and the mapping change, not every screen.
///
/// - `struct` (value semantics): copies are independent and safe to pass between threads.
/// - `Hashable`: required for `NavigationLink(value:)`, `Set`, and diffing in `List`.
/// - `Codable`: so we can persist favorites locally.
/// - `nonisolated`: the project uses `MainActor` as the default isolation (Xcode 26),
///   and models must also be usable off the main thread (decoding, cache).
nonisolated struct Product: Identifiable, Hashable, Codable, Sendable {
    let id: Int
    let title: String
    let description: String
    let category: String
    /// `Decimal`, not `Double` — money should not be represented with binary floating point
    /// (0.1 + 0.2 != 0.3 with `Double`).
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
}

nonisolated struct Review: Hashable, Codable, Sendable {
    let rating: Int
    let comment: String
    let author: String
    let date: Date
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
}
