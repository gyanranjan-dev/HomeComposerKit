import Foundation

/// A products section containing a list of products.
public struct ProductSection: Codable, Sendable {

    public let products: [Product]

    public init(products: [Product]) {
        self.products = products
    }
}
