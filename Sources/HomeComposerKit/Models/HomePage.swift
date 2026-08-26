import Foundation

/// Represents the complete configurable home page.
///
/// Backend-driven configuration may include optional schema and configuration
/// version metadata. Missing version fields decode as `nil` so existing
/// payloads remain compatible.
public struct HomePage: Codable, Identifiable, Sendable {

    public let id: String
    /// Legacy/content version string from the backend.
    public let version: String
    public let title: String?
    public let sections: [HomeSection]
    /// Optional schema version for the configuration document shape.
    public let schemaVersion: String?
    /// Optional configuration revision independent of ``version``.
    public let configurationVersion: String?

    public init(
        id: String,
        version: String,
        title: String? = nil,
        sections: [HomeSection],
        schemaVersion: String? = nil,
        configurationVersion: String? = nil
    ) {
        self.id = id
        self.version = version
        self.title = title
        self.sections = sections
        self.schemaVersion = schemaVersion
        self.configurationVersion = configurationVersion
    }
}
