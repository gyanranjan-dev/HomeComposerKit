import Foundation

/// Errors produced by ``HomePageDecoder`` when input cannot be prepared for decoding.
///
/// Standard `DecodingError` values from `JSONDecoder` are rethrown as-is so
/// hosts retain detailed coding-path diagnostics.
public enum HomeDecodingError: Error, Equatable, Sendable {
    /// The JSON string could not be converted to UTF-8 `Data`.
    case invalidUTF8String
}
