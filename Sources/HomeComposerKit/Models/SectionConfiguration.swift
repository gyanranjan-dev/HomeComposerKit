import Foundation

/// Layout and display options for a home section.
public struct SectionConfiguration: Codable, Equatable, Sendable {

    public let layout: String?
    public let limit: Int?
    public let columns: Int?
    public let spacing: Double?

    public init(
        layout: String? = nil,
        limit: Int? = nil,
        columns: Int? = nil,
        spacing: Double? = nil
    ) {
        self.layout = layout
        self.limit = limit
        self.columns = columns
        self.spacing = spacing
    }
}
