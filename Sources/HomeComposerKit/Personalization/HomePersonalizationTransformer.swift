import Foundation

/// Deterministic personalization utility for product sections.
///
/// This type does not implement a recommendation engine. It filters and reorders
/// products already present in section content using opaque host-provided IDs.
public struct HomePersonalizationTransformer: HomeSectionContentTransforming, Sendable {

    /// Personalization behavior applied to product sections.
    public enum Strategy: Sendable, Equatable {
        /// Keeps only products whose id appears in personalization product IDs.
        case filterMatchingProducts
        /// Reorders products placing recommendation IDs first.
        case reorderByRecommendations
        /// Hides the section when no products match personalization IDs.
        case hideWhenNoMatches
    }

    public let strategy: Strategy

    public init(strategy: Strategy) {
        self.strategy = strategy
    }

    public func transform(
        section: ComposedHomeSection,
        context: HomeRenderContext?
    ) -> HomeSectionContentTransformation {
        transform(
            section: section,
            context: HomeSectionTransformationContext(renderContext: context)
        )
    }

    public func transform(
        section: ComposedHomeSection,
        context: HomeSectionTransformationContext
    ) -> HomeSectionContentTransformation {
        guard let products = productPayload(from: section.content) else {
            return .unchanged(section)
        }

        let personalizedIDs = context.personalization.personalizedProductIDs
        if personalizedIDs.isEmpty {
            return .unchanged(section)
        }

        let allowed = Set(personalizedIDs)

        switch strategy {
        case .filterMatchingProducts:
            let filtered = filterProducts(products, allowed: allowed)
            return replaceProducts(filtered, in: section)

        case .reorderByRecommendations:
            let recommendationOrder = context.personalization.recommendationIDs
            let ordered = reorder(products, using: recommendationOrder)
            return replaceProducts(ordered, in: section)

        case .hideWhenNoMatches:
            let matched = filterProducts(products, allowed: allowed)
            if matched.isEmpty {
                return .hidden
            }
            return replaceProducts(matched, in: section)
        }
    }

    private func productPayload(from content: HomeSectionContent?) -> [Product]? {
        switch content {
        case .products(let payload),
             .popularProducts(let payload),
             .favoriteProducts(let payload),
             .recentlyViewed(let payload),
             .recommendations(let payload):
            return payload.products
        default:
            return nil
        }
    }

    private func replaceProducts(
        _ products: [Product],
        in section: ComposedHomeSection
    ) -> HomeSectionContentTransformation {
        let content: HomeSectionContent
        switch section.content {
        case .popularProducts:
            content = .popularProducts(ProductSection(products: products))
        case .favoriteProducts:
            content = .favoriteProducts(ProductSection(products: products))
        case .recentlyViewed:
            content = .recentlyViewed(ProductSection(products: products))
        case .recommendations:
            content = .recommendations(ProductSection(products: products))
        default:
            content = .products(ProductSection(products: products))
        }
        return .replace(section.replacing(content: content))
    }

    private func reorder(_ products: [Product], using recommendationOrder: [String]) -> [Product] {
        guard !recommendationOrder.isEmpty else {
            return products
        }

        let rank = Dictionary(
            uniqueKeysWithValues: recommendationOrder.enumerated().map { ($1, $0) }
        )

        return products.sorted { lhs, rhs in
            let lhsRank = rank[lhs.id] ?? Int.max
            let rhsRank = rank[rhs.id] ?? Int.max
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            return lhs.id < rhs.id
        }
    }

    private func filterProducts(_ products: [Product], allowed: Set<String>) -> [Product] {
        guard !allowed.isEmpty else {
            return []
        }
        return products.filter { allowed.contains($0.id) }
    }
}
