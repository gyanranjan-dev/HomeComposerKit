import Foundation

/// Identifies the kind of content a home section displays.
///
/// Unknown backend values decode as ``unknown(_:)`` instead of failing the
/// entire home page payload. Host apps can register renderers for specific
/// unknown raw values via ``HomeSectionRendererRegistry``.
public enum HomeSectionType: Codable, Sendable, Hashable {
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
    /// A section type sent by the backend that this package version does not recognize.
    case unknown(String)

    /// Wire-format value used for JSON coding.
    public var rawValue: String {
        switch self {
        case .banner: return "banner"
        case .categories: return "categories"
        case .products: return "products"
        case .popularProducts: return "popularProducts"
        case .favoriteProducts: return "favoriteProducts"
        case .liveStream: return "liveStream"
        case .social: return "social"
        case .recentlyViewed: return "recentlyViewed"
        case .recommendations: return "recommendations"
        case .custom: return "custom"
        case .unknown(let value): return value
        }
    }

    /// Whether this type is recognized by the current package version.
    public var isKnown: Bool {
        if case .unknown = self {
            return false
        }
        return true
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = HomeSectionType.parse(raw)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// Parses a wire-format type string, preserving unknown values.
    public static func parse(_ raw: String) -> HomeSectionType {
        switch raw {
        case "banner": return .banner
        case "categories": return .categories
        case "products": return .products
        case "popularProducts": return .popularProducts
        case "favoriteProducts": return .favoriteProducts
        case "liveStream": return .liveStream
        case "social": return .social
        case "recentlyViewed": return .recentlyViewed
        case "recommendations": return .recommendations
        case "custom": return .custom
        default: return .unknown(raw)
        }
    }
}
