import Foundation

nonisolated enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// A description of one request — *what* we want, without *how* it is sent.
///
/// Endpoint is a value type (struct): it is easy to compare in tests
/// and does not depend on `URLSession`. Concrete endpoints are defined
/// in the Data layer (see `ProductEndpoints.swift`), not here, so the
/// networking layer stays reusable for any API.
nonisolated struct Endpoint: Sendable, Equatable {
    var path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?

    /// `throws(NetworkError)` is typed throws (Swift 6) — the caller knows
    /// the exact error type, and the `catch` block is not `any Error`.
    func makeRequest(baseURL: URL) throws(NetworkError) -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        ) else {
            throw .invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw .invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
