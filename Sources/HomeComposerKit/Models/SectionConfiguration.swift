import Foundation

/// Layout and display options for a home section.
public struct SectionConfiguration: Codable, Equatable, Sendable {

    public let layout: HomeSectionLayout?
    public let limit: Int?
    public let columns: Int?
    public let spacing: Double?
    public let showTitle: Bool?
    public let showSeeAll: Bool?

    public init(
        layout: HomeSectionLayout? = nil,
        limit: Int? = nil,
        columns: Int? = nil,
        spacing: Double? = nil,
        showTitle: Bool? = nil,
        showSeeAll: Bool? = nil
    ) {
        self.layout = layout
        self.limit = limit
        self.columns = columns
        self.spacing = spacing
        self.showTitle = showTitle
        self.showSeeAll = showSeeAll
    }
}
