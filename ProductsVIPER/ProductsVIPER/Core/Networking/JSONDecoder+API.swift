import Foundation

nonisolated extension JSONDecoder {
    /// A decoder configured for our API's format.
    ///
    /// The API returns dates like "2025-04-30T09:41:02.053Z" (with milliseconds).
    /// Whether the built-in `.iso8601` strategy accepts fractional seconds depends on the
    /// OS version (yes on iOS 26, no on macOS 15 and older, and then decoding
    /// the whole response fails). We set the format explicitly and accept both variants.
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = try? Date(string, strategy: .iso8601WithFractionalSeconds) {
                return date
            }
            if let date = try? Date(string, strategy: .iso8601) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO 8601 date: \(string)"
            )
        }
        return decoder
    }
}

nonisolated extension ParseStrategy where Self == Date.ISO8601FormatStyle {
    static var iso8601WithFractionalSeconds: Date.ISO8601FormatStyle {
        Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    }
}
