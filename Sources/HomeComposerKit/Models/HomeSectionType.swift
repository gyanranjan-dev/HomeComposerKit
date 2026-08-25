import Foundation

/// Identifies the kind of content a home section displays.
public enum HomeSectionType: String, Codable, Sendable {
    case banner
    case categories
    case products
    case popularProducts
    case favoriteProducts
    case liveStream
    case social
    case recentlyViewed
    case recommendations
    case custom
}
