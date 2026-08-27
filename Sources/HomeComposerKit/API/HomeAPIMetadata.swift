import Foundation

/// Optional, ecommerce-agnostic metadata attached to a home API response.
///
/// Unknown backend keys are ignored by `Codable`. Hosts may use ``extras`` for
/// lightweight string attributes without coupling the kit to a specific backend.
public struct HomeAPIMetadata: Codable, Sendable, Equatable {

    public let locale: String?
    public let channel: String?
    public let tags: [String]?
    public let extras: [String: String]?

    public init(
        locale: String? = nil,
        channel: String? = nil,
        tags: [String]? = nil,
        extras: [String: String]? = nil
    ) {
        self.locale = locale
        self.channel = channel
        self.tags = tags
        self.extras = extras
    }
}
