import Foundation

/// Abstraction over the network. Repositories depend on this protocol,
/// not on `URLSession` — so tests can pass in a fake client
/// (Dependency Inversion — the "D" in SOLID).
///
/// `Sendable`, because the instance is shared across concurrency domains.
nonisolated protocol HTTPClient: Sendable {
    func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as responseType: Response.Type
    ) async throws(NetworkError) -> Response
}

nonisolated struct URLSessionHTTPClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL, session: URLSession = .shared, decoder: JSONDecoder = .api) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    /// `@concurrent` (Swift 6.2): the function always runs on the global
    /// concurrent pool, NOT on the caller's actor (MainActor).
    /// That way decoding large JSON responses does not block the UI.
    /// Without the attribute, under "Approachable Concurrency", `nonisolated async`
    /// functions run on the caller's actor.
    @concurrent
    func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as responseType: Response.Type
    ) async throws(NetworkError) -> Response {
        let request = try endpoint.makeRequest(baseURL: baseURL)

        let data: Data
        let response: URLResponse
        do {
            // URLSession honors Task cancellation: if the Task is cancelled,
            // the request is aborted and URLError(.cancelled) is thrown.
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw error.code == .cancelled ? .cancelled : .transport(error.code)
        } catch {
            throw error.isCancellation ? .cancelled : .transport(.unknown)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw .httpStatus(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw .decoding(String(describing: error))
        }
    }
}
