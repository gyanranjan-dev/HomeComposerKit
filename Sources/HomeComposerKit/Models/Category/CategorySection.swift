import Foundation

/// A product category displayed in home page sections.
public struct Category: Codable, Identifiable, Sendable {

    public let id: String
    public let name: String
    public let imageURL: URL?

    public init(
        id: String,
        name: String,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
    }
}

/// A categories section containing a list of categories.
public struct CategorySection: Codable, Sendable {

    public let categories: [Category]

    public init(categories: [Category]) {
        self.categories = categories
    }
}
