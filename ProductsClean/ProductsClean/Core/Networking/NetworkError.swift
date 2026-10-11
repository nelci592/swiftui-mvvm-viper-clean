import Foundation

/// Every error the networking layer can return.
///
/// Instead of letting raw `URLError` / `DecodingError` values bubble up,
/// we translate them into a small, controlled set. ViewModels then do not
/// depend on `URLSession` details and can show meaningful messages.
nonisolated enum NetworkError: Error, Equatable, Sendable {
    case invalidURL
    /// A connection problem (no internet, timeout, DNS…).
    case transport(URLError.Code)
    case invalidResponse
    /// The server responded, but with a status outside 200...299.
    case httpStatus(Int)
    case decoding(String)
    /// The request was cancelled (for example, the user left the screen).
    /// A separate case, because cancellation is NOT an error for the user — we do not show a message.
    case cancelled
}

nonisolated extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The request URL is invalid."
        case .transport(.notConnectedToInternet), .transport(.networkConnectionLost):
            "You appear to be offline. Check your connection and try again."
        case .transport(.timedOut):
            "The server took too long to respond."
        case .transport:
            "A network error occurred."
        case .invalidResponse:
            "The server returned an unexpected response."
        case .httpStatus(404):
            "The requested item was not found."
        case .httpStatus(let code) where (500...599).contains(code):
            "The server is having problems (\(code)). Please try again later."
        case .httpStatus(let code):
            "The request failed with status \(code)."
        case .decoding:
            "The data from the server could not be read."
        case .cancelled:
            "The request was cancelled."
        }
    }
}

nonisolated extension Error {
    /// Unifies the three ways Swift/Foundation signal cancellation.
    var isCancellation: Bool {
        if self is CancellationError { return true }
        if let networkError = self as? NetworkError, networkError == .cancelled { return true }
        if let urlError = self as? URLError, urlError.code == .cancelled { return true }
        return false
    }
}
