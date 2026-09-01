import Foundation

/// Lightweight JSON-compatible value for custom or unknown action payloads.
public enum HomeActionValue: Codable, Sendable, Hashable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([HomeActionValue])
    case object([String: HomeActionValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([HomeActionValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: HomeActionValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported HomeActionValue."
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

/// A framework-agnostic user interaction emitted by the home UI layer.
///
/// ``HomeComposerKit`` describes actions; the host application decides how to
/// interpret them (navigation, analytics, business logic, etc.).
public enum HomeAction: Sendable, Hashable, Equatable {
    case openURL(url: String)
    case product(id: String)
    case category(id: String)
    case section(id: String)
    case custom(name: String, payload: [String: HomeActionValue]?)
    /// A backend action type that this package version does not recognize.
    case unknown(type: String, payload: [String: HomeActionValue]?)

    /// Wire-format action discriminator.
    public var typeName: String {
        switch self {
        case .openURL: return "openURL"
        case .product: return "product"
        case .category: return "category"
        case .section: return "section"
        case .custom: return "custom"
        case .unknown(let type, _): return type
        }
    }

    /// Whether this action type is recognized by the current package version.
    public var isKnown: Bool {
        if case .unknown = self {
            return false
        }
        return true
    }
}

extension HomeAction: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case url
        case id
        case name
        case payload
    }

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "openURL":
            self = .openURL(url: try container.decode(String.self, forKey: .url))
        case "product":
            self = .product(id: try container.decode(String.self, forKey: .id))
        case "category":
            self = .category(id: try container.decode(String.self, forKey: .id))
        case "section":
            self = .section(id: try container.decode(String.self, forKey: .id))
        case "custom":
            self = .custom(
                name: try container.decode(String.self, forKey: .name),
                payload: try container.decodeIfPresent([String: HomeActionValue].self, forKey: .payload)
            )
        default:
            let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKeys.self)
            if let nestedPayload = try dynamicContainer.decodeIfPresent(
                [String: HomeActionValue].self,
                forKey: DynamicCodingKeys(stringValue: "payload")!
            ) {
                self = .unknown(type: type, payload: nestedPayload)
                return
            }

            var payload: [String: HomeActionValue] = [:]
            for key in dynamicContainer.allKeys where key.stringValue != "type" {
                payload[key.stringValue] = try dynamicContainer.decode(
                    HomeActionValue.self,
                    forKey: key
                )
            }
            self = .unknown(type: type, payload: payload.isEmpty ? nil : payload)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .openURL(let url):
            try container.encode("openURL", forKey: .type)
            try container.encode(url, forKey: .url)
        case .product(let id):
            try container.encode("product", forKey: .type)
            try container.encode(id, forKey: .id)
        case .category(let id):
            try container.encode("category", forKey: .type)
            try container.encode(id, forKey: .id)
        case .section(let id):
            try container.encode("section", forKey: .type)
            try container.encode(id, forKey: .id)
        case .custom(let name, let payload):
            try container.encode("custom", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(payload, forKey: .payload)
        case .unknown(let type, let payload):
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(payload, forKey: .payload)
        }
    }
}

extension HomeAction {

    /// Maps an existing ``BannerAction`` into a ``HomeAction`` without duplicating
    /// banner-specific configuration models.
    public static func from(bannerAction: BannerAction, bannerID: String) -> HomeAction {
        if bannerAction.destination.lowercased().hasPrefix("http://")
            || bannerAction.destination.lowercased().hasPrefix("https://") {
            return .openURL(url: bannerAction.destination)
        }

        var payload: [String: HomeActionValue] = [
            "destination": .string(bannerAction.destination),
            "bannerID": .string(bannerID)
        ]
        if let title = bannerAction.title {
            payload["title"] = .string(title)
        }
        return .custom(name: "banner", payload: payload)
    }

    /// Maps a ``Banner`` tap into a ``HomeAction`` when banner action data exists.
    public static func from(banner: Banner) -> HomeAction? {
        guard let action = banner.action else { return nil }
        return from(bannerAction: action, bannerID: banner.id)
    }

    /// Maps a ``Brand`` tap into a ``HomeAction``.
    public static func from(brand: Brand) -> HomeAction {
        .custom(
            name: "brand",
            payload: [
                "id": .string(brand.id),
                "name": .string(brand.name)
            ]
        )
    }

    /// Maps a ``PromotionAction`` into a ``HomeAction``.
    public static func from(promotionAction: PromotionAction, promotionID: String) -> HomeAction {
        if promotionAction.destination.lowercased().hasPrefix("http://")
            || promotionAction.destination.lowercased().hasPrefix("https://") {
            return .openURL(url: promotionAction.destination)
        }

        var payload: [String: HomeActionValue] = [
            "destination": .string(promotionAction.destination),
            "promotionID": .string(promotionID)
        ]
        if let title = promotionAction.title {
            payload["title"] = .string(title)
        }
        return .custom(name: "promotion", payload: payload)
    }

    /// Maps a ``Promotion`` tap into a ``HomeAction`` when promotion action data exists.
    public static func from(promotion: Promotion) -> HomeAction? {
        guard let action = promotion.action else { return nil }
        return from(promotionAction: action, promotionID: promotion.id)
    }
}
