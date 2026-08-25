import Foundation

/// Represents the complete configurable home page.
public struct HomePage: Codable, Identifiable, Sendable {

    public let id: String
    public let version: String
    public let title: String?
    public let sections: [HomeSection]

    public init(
        id: String,
        version: String,
        title: String? = nil,
        sections: [HomeSection]
    ) {
        self.id = id
        self.version = version
        self.title = title
        self.sections = sections
    }
}
