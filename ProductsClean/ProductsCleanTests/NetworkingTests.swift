import Foundation
import Testing
@testable import ProductsClean

struct EndpointTests {
    private let baseURL = URL(string: "https://dummyjson.com")!

    @Test func productListIncludesPaginationAndSort() throws {
        let request = try Endpoint.products(sort: .priceLowToHigh, skip: 40, limit: 20).makeRequest(baseURL: baseURL)

        #expect(request.url?.absoluteString == "https://dummyjson.com/products?limit=20&skip=40&sortBy=price&order=asc")
        #expect(request.httpMethod == "GET")
    }

    @Test func searchEncodesQuery() throws {
        let request = try Endpoint.searchProducts(query: "smart phone", sort: .relevance, skip: 0, limit: 10)
            .makeRequest(baseURL: baseURL)

        #expect(request.url?.absoluteString == "https://dummyjson.com/products/search?q=smart%20phone&limit=10&skip=0")
    }
}

struct URLSessionHTTPClientTests {
    private let client = URLSessionHTTPClient(
        baseURL: URL(string: "https://example.com")!,
        session: StubURLProtocol.makeSession()
    )

    @Test func decodesSuccessfulResponse() async throws {
        StubURLProtocol.stub(path: "/products/1", statusCode: 200, body: Data(Fixtures.productJSON.utf8))

        let dto = try await client.send(.product(id: 1), as: ProductDTO.self)

        #expect(dto.id == 1)
    }

    @Test(arguments: [404, 500, 503])
    func mapsHTTPErrorStatus(statusCode: Int) async {
        let path = "/status/\(statusCode)"
        StubURLProtocol.stub(path: path, statusCode: statusCode, body: Data())

        await #expect(throws: NetworkError.httpStatus(statusCode)) {
            try await client.send(Endpoint(path: path), as: ProductDTO.self)
        }
    }

    @Test func mapsInvalidJSONToDecodingError() async {
        StubURLProtocol.stub(path: "/broken", statusCode: 200, body: Data("{\"id\":".utf8))

        do {
            _ = try await client.send(Endpoint(path: "/broken"), as: ProductDTO.self)
            Issue.record("Expected decoding error")
        } catch {
            guard case .decoding = error else {
                Issue.record("Expected .decoding, got \(error)")
                return
            }
        }
    }
}
