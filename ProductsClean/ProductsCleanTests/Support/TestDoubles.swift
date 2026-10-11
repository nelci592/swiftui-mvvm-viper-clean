import Foundation
import Synchronization
@testable import ProductsClean

/// Repository stub: returns whatever the test asks for and records every request.
///
/// `Mutex` (Synchronization, iOS 18+) guards the recorded requests, so the class is
/// truly `Sendable` without `@unchecked`.
final class StubProductRepository: ProductRepository {
    struct Request: Equatable, Sendable {
        let query: String
        let sort: ProductSort
        let skip: Int
        let limit: Int
    }

    private let handler: @Sendable (Request) async throws -> ProductPage
    private let recordedRequests = Mutex<[Request]>([])

    init(handler: @escaping @Sendable (Request) async throws -> ProductPage) {
        self.handler = handler
    }

    var requests: [Request] {
        recordedRequests.withLock { $0 }
    }

    func fetchProducts(query: String, sort: ProductSort, skip: Int, limit: Int) async throws -> ProductPage {
        let request = Request(query: query, sort: sort, skip: skip, limit: limit)
        recordedRequests.withLock { $0.append(request) }
        return try await handler(request)
    }

    func fetchProduct(id: Product.ID) async throws -> Product {
        throw NetworkError.httpStatus(404)
    }
}

/// Lets a test hold an async operation at a precise moment
/// and release it later. That makes race conditions deterministic,
/// without `sleep` and without flaky tests.
actor Gate {
    private var hasEntered = false
    private var isReleased = false
    private var entryWaiters: [CheckedContinuation<Void, Never>] = []
    private var releaseWaiters: [CheckedContinuation<Void, Never>] = []

    /// Called by the code under test: signals that it has reached the gate, and waits for `release()`.
    func enterAndWait() async {
        hasEntered = true
        entryWaiters.forEach { $0.resume() }
        entryWaiters.removeAll()
        guard !isReleased else { return }
        await withCheckedContinuation { releaseWaiters.append($0) }
    }

    /// Called by the test: waits until the code under test reaches the gate.
    func waitUntilEntered() async {
        guard !hasEntered else { return }
        await withCheckedContinuation { entryWaiters.append($0) }
    }

    func release() {
        isReleased = true
        releaseWaiters.forEach { $0.resume() }
        releaseWaiters.removeAll()
    }
}

actor Counter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

/// Intercepts every `URLSession` request and returns predefined responses.
/// That lets us test the real `URLSessionHTTPClient` (status codes, decoding) without a network.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Stub: Sendable {
        let statusCode: Int
        let body: Data
    }

    /// The key is the URL path, so tests can run in parallel without interfering with each other.
    private static let stubs = Mutex<[String: Stub]>([:])

    static func stub(path: String, statusCode: Int, body: Data) {
        stubs.withLock { $0[path] = Stub(statusCode: statusCode, body: body) }
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard
            let url = request.url,
            let stub = Self.stubs.withLock({ $0[url.path()] }),
            let response = HTTPURLResponse(url: url, statusCode: stub.statusCode, httpVersion: nil, headerFields: nil)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - Fixtures

extension Product {
    static func fixture(
        id: Int,
        title: String? = nil,
        price: Decimal = 10,
        discountPercentage: Double = 0
    ) -> Product {
        Product(
            id: id,
            title: title ?? "Product \(id)",
            description: "",
            category: "test",
            price: price,
            discountPercentage: discountPercentage,
            rating: 4,
            stock: 1,
            brand: nil,
            thumbnailURL: nil,
            imageURLs: [],
            reviews: []
        )
    }
}

extension ProductPage {
    static func fixture(ids: some Sequence<Int>, total: Int, skip: Int = 0) -> ProductPage {
        ProductPage(items: ids.map { Product.fixture(id: $0) }, total: total, skip: skip)
    }
}
