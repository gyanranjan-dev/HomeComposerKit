import Foundation

/// The tap action associated with a promotion.
public struct PromotionAction: Codable, Equatable, Sendable {

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

/// A promotional offer displayed in a home page section.
///
/// `expiresAt` is display metadata only. The framework does not schedule or
/// hide promotions based on time — the host controls visibility.
public struct Promotion: Codable, Identifiable, Equatable, Sendable {

    public let id: String
    public let title: String
    public let subtitle: String?
    public let imageURL: URL?
    public let action: PromotionAction?
    public let expiresAt: Date?

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        imageURL: URL? = nil,
        action: PromotionAction? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.action = action
        self.expiresAt = expiresAt
    }
}

/// A promotion section containing a list of promotional offers.
public struct PromotionSection: Codable, Equatable, Sendable {

    public let promotions: [Promotion]

    public init(promotions: [Promotion]) {
        self.promotions = promotions
    }
}
