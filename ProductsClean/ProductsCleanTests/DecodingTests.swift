import Foundation
import Testing
@testable import ProductsClean

enum Fixtures {
    /// A real API response (trimmed): no `brand`, and a date with milliseconds.
    static let productJSON = """
    {
        "id": 1,
        "title": "Green Chili Pepper",
        "description": "Spicy green chili pepper.",
        "category": "groceries",
        "price": 9.99,
        "discountPercentage": 10,
        "rating": 3.66,
        "stock": 3,
        "tags": ["vegetables"],
        "thumbnail": "https://cdn.dummyjson.com/thumbnail.webp",
        "images": ["https://cdn.dummyjson.com/1.webp"],
        "reviews": [
            {
                "rating": 4,
                "comment": "Great product!",
                "date": "2025-04-30T09:41:02.053Z",
                "reviewerName": "Luna Russell",
                "reviewerEmail": "luna.russell@x.dummyjson.com"
            }
        ]
    }
    """
}

struct DecodingTests {
    @Test func decodesProductAndMapsToDomain() throws {
        let dto = try JSONDecoder.api.decode(ProductDTO.self, from: Data(Fixtures.productJSON.utf8))
        let product = dto.toDomain()

        #expect(product.brand == nil)
        #expect(product.price == Decimal(string: "9.99"))
        #expect(product.thumbnailURL == URL(string: "https://cdn.dummyjson.com/thumbnail.webp"))
        #expect(product.reviews.first?.author == "Luna Russell")
    }

    @Test func decodesDatesWithFractionalSeconds() throws {
        let dto = try JSONDecoder.api.decode(ProductDTO.self, from: Data(Fixtures.productJSON.utf8))
        let date = try #require(dto.reviews?.first?.date)

        let components = Calendar(identifier: .gregorian).dateComponents(in: .gmt, from: date)
        #expect(components.year == 2025)
        #expect(components.month == 4)
        #expect(components.hour == 9)
    }

    @Test(arguments: ["2025-04-30T09:41:02.053Z", "2025-04-30T09:41:02Z"])
    func acceptsDatesWithAndWithoutFractionalSeconds(dateString: String) throws {
        let json = #"{"rating": 5, "comment": "", "reviewerName": "A", "date": "\#(dateString)"}"#

        let review = try JSONDecoder.api.decode(ReviewDTO.self, from: Data(json.utf8))

        #expect(Calendar(identifier: .gregorian).component(.second, from: review.date) == 2)
    }

    @Test func invalidDateFailsDecoding() {
        let json = #"{"rating": 5, "comment": "", "reviewerName": "A", "date": "yesterday"}"#

        #expect(throws: DecodingError.self) {
            try JSONDecoder.api.decode(ReviewDTO.self, from: Data(json.utf8))
        }
    }

    @Test func discountedPriceUsesDecimalArithmetic() {
        let product = Product.fixture(id: 1, price: Decimal(string: "19.99")!, discountPercentage: 10)

        #expect(product.discountedPrice == Decimal(string: "17.99"))
    }
}
