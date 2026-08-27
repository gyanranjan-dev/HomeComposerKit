import Foundation

/// Presentation layout intent for a home section.
///
/// Unknown backend values decode as ``unknown(_:)`` instead of failing the
/// payload. Renderers resolve unknown layouts to section-type defaults.
public enum HomeSectionLayout: Sendable, Equatable, Hashable {
    case horizontal
    case vertical
    case grid
    case carousel
    /// A layout value sent by the backend that this package version does not recognize.
    case unknown(String)

    /// Wire-format value used for JSON coding.
    public var rawValue: String {
        switch self {
        case .horizontal: return "horizontal"
        case .vertical: return "vertical"
        case .grid: return "grid"
        case .carousel: return "carousel"
        case .unknown(let value): return value
        }
    }

    /// Whether this layout is recognized by the current package version.
    public var isKnown: Bool {
        if case .unknown = self {
            return false
        }
        return true
    }

    /// Parses a wire-format layout string, preserving unknown values.
    public static func parse(_ raw: String) -> HomeSectionLayout {
        switch raw.lowercased() {
        case "horizontal": return .horizontal
        case "vertical": return .vertical
        case "grid": return .grid
        case "carousel": return .carousel
        default: return .unknown(raw)
        }
    }
}

extension HomeSectionLayout: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = HomeSectionLayout.parse(raw)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
