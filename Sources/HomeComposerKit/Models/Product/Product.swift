import Foundation

/// A product displayed in home page sections.
public struct Product: Codable, Identifiable, Sendable {

    public let id: String
    public let name: String
    public let description: String?
    public let imageURL: URL?
    public let price: Decimal
    public let currency: String
    public let isFavorite: Bool
    public let categoryID: String?

    public init(
        id: String,
        name: String,
        description: String? = nil,
        imageURL: URL? = nil,
        price: Decimal,
        currency: String,
        isFavorite: Bool = false,
        categoryID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.price = price
        self.currency = currency
        self.isFavorite = isFavorite
        self.categoryID = categoryID
    }
}
