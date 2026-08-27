import Foundation

/// A section entry in a backend home configuration response.
///
/// Maps to ``HomeSection`` for composition. ``contentRef`` is an opaque host-side
/// reference (for example a cache key or content URL path) — the kit never fetches it.
public struct HomeAPISection: Codable, Sendable, Identifiable {

    public let id: String
    public let type: HomeSectionType
    public let title: String?
    public let order: Int
    /// When omitted by the backend, treated as `true`.
    public let isEnabled: Bool?
    public let configuration: SectionConfiguration?
    /// Opaque content reference for the host to resolve into ``HomeSectionContent``.
    public let contentRef: String?

    public init(
        id: String,
        type: HomeSectionType,
        title: String? = nil,
        order: Int,
        isEnabled: Bool? = true,
        configuration: SectionConfiguration? = nil,
        contentRef: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.order = order
        self.isEnabled = isEnabled
        self.configuration = configuration
        self.contentRef = contentRef
    }

    /// Converts this API section into the composition-layer ``HomeSection`` model.
    public func makeHomeSection() -> HomeSection {
        HomeSection(
            id: id,
            type: type,
            title: title,
            order: order,
            isEnabled: isEnabled ?? true,
            configuration: configuration
        )
    }
}
