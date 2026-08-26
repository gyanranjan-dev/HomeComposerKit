import Foundation

/// Decodes host-provided JSON into a ``HomePage``.
///
/// Networking, authentication, and caching remain the host application's
/// responsibility. This type only converts `Data` / `String` into models.
public struct HomePageDecoder: Sendable {

    private let decoder: JSONDecoder

    /// Creates a decoder.
    ///
    /// - Parameter decoder: The `JSONDecoder` used for decoding. Defaults to a
    ///   standard `JSONDecoder` with no custom strategies.
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    /// Decodes a home page from UTF-8 JSON data.
    ///
    /// - Parameter data: Raw JSON bytes typically received from a host networking layer.
    /// - Returns: A decoded ``HomePage``.
    /// - Throws: `DecodingError` when the payload does not match the model schema.
    public func decode(_ data: Data) throws -> HomePage {
        try decoder.decode(HomePage.self, from: data)
    }

    /// Decodes a home page from a JSON string.
    ///
    /// Converts the string to UTF-8 `Data`, then uses the same decoding path as
    /// `decode(_ data: Data)`.
    ///
    /// - Parameter json: A JSON string.
    /// - Returns: A decoded ``HomePage``.
    /// - Throws: ``HomeDecodingError/invalidUTF8String`` when UTF-8 conversion fails,
    ///   or `DecodingError` when the payload does not match the model schema.
    public func decode(_ json: String) throws -> HomePage {
        guard let data = json.data(using: .utf8) else {
            throw HomeDecodingError.invalidUTF8String
        }
        return try decode(data)
    }
}
