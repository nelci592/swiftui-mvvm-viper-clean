import Foundation

nonisolated extension Product {
    static let sample = Product(
        id: 121,
        title: "iPhone 5s",
        description: "The iPhone 5s is a classic smartphone known for its compact design and advanced features during its release.",
        category: "smartphones",
        price: Decimal(string: "199.99")!,
        discountPercentage: 12.91,
        rating: 2.83,
        stock: 25,
        brand: "Apple",
        thumbnailURL: URL(string: "https://cdn.dummyjson.com/product-images/smartphones/iphone-5s/thumbnail.webp"),
        imageURLs: [
            URL(string: "https://cdn.dummyjson.com/product-images/smartphones/iphone-5s/1.webp")!,
            URL(string: "https://cdn.dummyjson.com/product-images/smartphones/iphone-5s/2.webp")!,
        ],
        reviews: [
            Review(rating: 5, comment: "Highly recommended!", author: "Nolan Bryant", date: .now),
            Review(rating: 3, comment: "It's fine.", author: "Ava Harris", date: .now),
        ]
    )

    static let sampleWithoutBrand = Product(
        id: 26,
        title: "Green Chili Pepper",
        description: "Spicy green chili pepper, ideal for adding heat to your favorite recipes.",
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

    static let samples: [Product] = [sample, sampleWithoutBrand]
}
