import Foundation

/// A configurable section within a home page.
public struct HomeSection: Codable, Identifiable, Sendable {

    public let id: String
    public let type: HomeSectionType
    public let title: String?
    public let order: Int
    public let isEnabled: Bool
    public let configuration: SectionConfiguration?

    public init(
        id: String,
        type: HomeSectionType,
        title: String? = nil,
        order: Int,
        isEnabled: Bool = true,
        configuration: SectionConfiguration? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.order = order
        self.isEnabled = isEnabled
        self.configuration = configuration
    }
}
