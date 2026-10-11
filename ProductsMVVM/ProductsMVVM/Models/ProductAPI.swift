import Foundation

/// The Model's data access. ViewModels call this type directly — there is no repository protocol
/// and no Domain/Data split. That is "MVVM only", not Clean Architecture.
nonisolated final class ProductAPI: Sendable {
    enum Stub: Sendable {
        case none
        case success
        case empty
        case failure
    }

    static let live = ProductAPI()
    static let preview = ProductAPI(stub: .success)
    static let previewEmpty = ProductAPI(stub: .empty)
    static let previewFailure = ProductAPI(stub: .failure)

    private let baseURL = URL(string: "https://dummyjson.com")!
    private let session: URLSession
    private let decoder: JSONDecoder
    private let stub: Stub

    init(session: URLSession = .shared, stub: Stub = .none) {
        self.session = session
        self.stub = stub
        self.decoder = JSONDecoder.api
    }

    @concurrent
    func fetchProducts(query: String, sort: ProductSort, skip: Int, limit: Int) async throws -> ProductPage {
        if let stubPage = try await stubPage(skip: skip) { return stubPage }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var items = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "skip", value: String(skip)),
        ] + sort.queryItems
        let path = trimmed.isEmpty ? "products" : "products/search"
        if !trimmed.isEmpty {
            items.insert(URLQueryItem(name: "q", value: trimmed), at: 0)
        }
        let response: ListResponse = try await get(path: path, queryItems: items)
        return ProductPage(items: response.products, total: response.total, skip: response.skip)
    }

    @concurrent
    func fetchProduct(id: Product.ID) async throws -> Product {
        if stub == .failure { throw NetworkError.httpStatus(404) }
        if stub == .success, let product = Product.samples.first(where: { $0.id == id }) {
            try await Task.sleep(for: .milliseconds(150))
            return product
        }
        return try await get(path: "products/\(id)", queryItems: [])
    }

    private func stubPage(skip: Int) async throws -> ProductPage? {
        switch stub {
        case .none:
            return nil
        case .success:
            try await Task.sleep(for: .milliseconds(150))
            return ProductPage(items: Product.samples, total: Product.samples.count, skip: skip)
        case .empty:
            return ProductPage(items: [], total: 0, skip: skip)
        case .failure:
            throw NetworkError.transport(.notConnectedToInternet)
        }
    }

    private func get<T: Decodable & Sendable>(path: String, queryItems: [URLQueryItem]) async throws(NetworkError) -> T {
        guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
            throw .invalidURL
        }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else { throw .invalidURL }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw error.code == .cancelled ? .cancelled : .transport(error.code)
        } catch {
            throw error.isCancellation ? .cancelled : .transport(.unknown)
        }

        guard let http = response as? HTTPURLResponse else { throw .invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw .httpStatus(http.statusCode) }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw .decoding(String(describing: error))
        }
    }
}

private nonisolated struct ListResponse: Decodable, Sendable {
    let products: [Product]
    let total: Int
    let skip: Int
}

nonisolated enum NetworkError: Error, Equatable, Sendable {
    case invalidURL
    case transport(URLError.Code)
    case invalidResponse
    case httpStatus(Int)
    case decoding(String)
    case cancelled
}

nonisolated extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL: "The request URL is invalid."
        case .transport(.notConnectedToInternet), .transport(.networkConnectionLost):
            "You appear to be offline. Check your connection and try again."
        case .transport(.timedOut): "The server took too long to respond."
        case .transport: "A network error occurred."
        case .invalidResponse: "The server returned an unexpected response."
        case .httpStatus(404): "The requested item was not found."
        case .httpStatus(let code) where (500...599).contains(code):
            "The server is having problems (\(code)). Please try again later."
        case .httpStatus(let code): "The request failed with status \(code)."
        case .decoding: "The data from the server could not be read."
        case .cancelled: "The request was cancelled."
        }
    }
}

nonisolated extension Error {
    var isCancellation: Bool {
        if self is CancellationError { return true }
        if let networkError = self as? NetworkError, networkError == .cancelled { return true }
        if let urlError = self as? URLError, urlError.code == .cancelled { return true }
        return false
    }
}

nonisolated extension JSONDecoder {
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = try? Date(string, strategy: .iso8601WithFractionalSeconds) { return date }
            if let date = try? Date(string, strategy: .iso8601) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO 8601 date: \(string)")
        }
        return decoder
    }
}

nonisolated extension ParseStrategy where Self == Date.ISO8601FormatStyle {
    static var iso8601WithFractionalSeconds: Date.ISO8601FormatStyle {
        Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    }
}
