import Foundation

/// A brand displayed in a home page section.
public struct Brand: Codable, Identifiable, Equatable, Sendable {

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

/// A brand section containing a list of brands.
///
/// The host supplies brand content; HomeComposerKit does not fetch brand data.
public struct BrandSection: Codable, Equatable, Sendable {

    public let brands: [Brand]

    public init(brands: [Brand]) {
        self.brands = brands
    }
}
