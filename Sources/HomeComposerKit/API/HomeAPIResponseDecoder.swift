import Foundation

/// Decodes host-provided JSON into a ``HomeAPIResponse`` envelope.
///
/// Does not perform networking. Unknown JSON keys are ignored by `Codable`.
public struct HomeAPIResponseDecoder: Sendable {

    private let decoder: JSONDecoder

    /// Creates a decoder.
    ///
    /// - Parameter decoder: Underlying `JSONDecoder`. Defaults to a standard decoder.
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    /// Decodes an API envelope from UTF-8 JSON data.
    public func decode(_ data: Data) throws -> HomeAPIResponse {
        try decoder.decode(HomeAPIResponse.self, from: data)
    }

    /// Decodes an API envelope from a JSON string.
    public func decode(_ json: String) throws -> HomeAPIResponse {
        guard let data = json.data(using: .utf8) else {
            throw HomeDecodingError.invalidUTF8String
        }
        return try decode(data)
    }
}
