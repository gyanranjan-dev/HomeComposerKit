import Foundation

/// The tap action associated with a banner.
public struct BannerAction: Codable, Equatable, Sendable {

    public let title: String?
    public let destination: String

    public init(
        title: String? = nil,
        destination: String
    ) {
        self.title = title
        self.destination = destination
    }
}

/// A promotional banner displayed in a home page section.
public struct Banner: Codable, Identifiable, Equatable, Sendable {

    public let id: String
    public let title: String?
    public let subtitle: String?
    public let imageURL: URL
    public let action: BannerAction?

    public init(
        id: String,
        title: String? = nil,
        subtitle: String? = nil,
        imageURL: URL,
        action: BannerAction? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.action = action
    }
}

/// A banner carousel section containing a list of banners.
public struct BannerSection: Codable, Equatable, Sendable {

    public let banners: [Banner]

    public init(banners: [Banner]) {
        self.banners = banners
    }
}
