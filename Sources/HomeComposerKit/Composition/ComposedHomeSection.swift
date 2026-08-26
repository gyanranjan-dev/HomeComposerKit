import Foundation

/// A home section prepared for a future renderer.
///
/// Contains only the data and configuration a UI layer needs to decide
/// how to present the section. It does not include SwiftUI views.
public struct ComposedHomeSection: Identifiable, Sendable, Equatable {

    public let id: String
    public let type: HomeSectionType
    public let title: String?
    public let order: Int
    public let configuration: SectionConfiguration?
    public let content: HomeSectionContent?

    public init(
        id: String,
        type: HomeSectionType,
        title: String? = nil,
        order: Int,
        configuration: SectionConfiguration? = nil,
        content: HomeSectionContent? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.order = order
        self.configuration = configuration
        self.content = content
    }

    /// Creates a composed section from a configured home section.
    public init(section: HomeSection, content: HomeSectionContent? = nil) {
        self.id = section.id
        self.type = section.type
        self.title = section.title
        self.order = section.order
        self.configuration = section.configuration
        self.content = content
    }
}
