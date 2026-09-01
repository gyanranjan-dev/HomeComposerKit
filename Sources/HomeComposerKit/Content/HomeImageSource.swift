import Foundation

/// Describes where a HomeComposerKit image should be loaded from.
///
/// The framework describes the image source; the host's ``HomeImageProvider``
/// decides how to resolve it.
public enum HomeImageSource: Sendable, Hashable, Equatable {
    case remote(URL)
    case asset(name: String)
    case system(name: String)
    case none
    /// A backend image source type that this package version does not recognize.
    case unknown(String)

    /// Wire-format source discriminator.
    public var typeName: String {
        switch self {
        case .remote: return "remote"
        case .asset: return "asset"
        case .system: return "system"
        case .none: return "none"
        case .unknown(let value): return value
        }
    }

    /// Whether this source type is recognized by the current package version.
    public var isKnown: Bool {
        if case .unknown = self {
            return false
        }
        return true
    }

    /// Creates an image source from an optional URL.
    public init(url: URL?) {
        if let url {
            self = .remote(url)
        } else {
            self = .none
        }
    }
}

extension HomeImageSource: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case url
        case name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let type = try container.decodeIfPresent(String.self, forKey: .type) else {
            self = .none
            return
        }

        switch type {
        case "remote":
            if let urlString = try container.decodeIfPresent(String.self, forKey: .url),
               let url = URL(string: urlString),
               let scheme = url.scheme?.lowercased(),
               scheme == "http" || scheme == "https" {
                self = .remote(url)
            } else {
                self = .none
            }
        case "asset":
            if let name = try container.decodeIfPresent(String.self, forKey: .name),
               !name.isEmpty {
                self = .asset(name: name)
            } else {
                self = .none
            }
        case "system":
            if let name = try container.decodeIfPresent(String.self, forKey: .name),
               !name.isEmpty {
                self = .system(name: name)
            } else {
                self = .none
            }
        case "none":
            self = .none
        default:
            self = .unknown(type)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .remote(let url):
            try container.encode("remote", forKey: .type)
            try container.encode(url.absoluteString, forKey: .url)
        case .asset(let name):
            try container.encode("asset", forKey: .type)
            try container.encode(name, forKey: .name)
        case .system(let name):
            try container.encode("system", forKey: .type)
            try container.encode(name, forKey: .name)
        case .none:
            try container.encode("none", forKey: .type)
        case .unknown(let type):
            try container.encode(type, forKey: .type)
        }
    }
}
