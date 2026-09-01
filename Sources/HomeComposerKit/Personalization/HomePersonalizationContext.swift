import Foundation

/// Host-provided personalization signals for section content transformation.
///
/// HomeComposerKit does not collect, store, or transmit user data. The host
/// application supplies opaque identifiers and controls what information is
/// included. Avoid placing sensitive personal information in this type.
public struct HomePersonalizationContext: Sendable, Hashable, Equatable {

    /// Opaque customer reference supplied by the host application.
    public var customerReference: String?

    /// Preferred category identifiers for personalization-aware transformers.
    public var preferredCategoryIDs: [String]

    /// Favorite product identifiers already known to the host.
    public var favoriteProductIDs: [String]

    /// Recently viewed product identifiers supplied by the host.
    public var recentlyViewedProductIDs: [String]

    /// Recommendation identifiers used for ordering or filtering.
    public var recommendationIDs: [String]

    /// Optional locale identifier (for example `"en_US"`).
    public var localeIdentifier: String?

    /// Optional region identifier (for example `"US"`).
    public var regionIdentifier: String?

    /// Opaque experiment identifiers keyed by experiment name.
    public var experimentIdentifiers: [String: String]

    /// An empty personalization context.
    public static let empty = HomePersonalizationContext()

    public init(
        customerReference: String? = nil,
        preferredCategoryIDs: [String] = [],
        favoriteProductIDs: [String] = [],
        recentlyViewedProductIDs: [String] = [],
        recommendationIDs: [String] = [],
        localeIdentifier: String? = nil,
        regionIdentifier: String? = nil,
        experimentIdentifiers: [String: String] = [:]
    ) {
        self.customerReference = customerReference
        self.preferredCategoryIDs = preferredCategoryIDs
        self.favoriteProductIDs = favoriteProductIDs
        self.recentlyViewedProductIDs = recentlyViewedProductIDs
        self.recommendationIDs = recommendationIDs
        self.localeIdentifier = localeIdentifier
        self.regionIdentifier = regionIdentifier
        self.experimentIdentifiers = experimentIdentifiers
    }

    /// Union of product identifiers commonly used for personalization filtering.
    public var personalizedProductIDs: [String] {
        var seen = Set<String>()
        var ordered: [String] = []

        for id in recommendationIDs + favoriteProductIDs + recentlyViewedProductIDs {
            if seen.insert(id).inserted {
                ordered.append(id)
            }
        }

        return ordered
    }
}
