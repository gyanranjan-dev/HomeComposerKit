import SwiftUI

/// Product strip used for products, popular products, favorites,
/// recently viewed, and recommendations.
public struct ProductSectionView: View {
    let section: ComposedHomeSection

    @Environment(\.homeActionHandler) private var actionHandler
    @Environment(\.homeComposerTheme) private var theme

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var products: [Product] {
        let items: [Product]
        switch section.content {
        case .products(let payload),
             .popularProducts(let payload),
             .favoriteProducts(let payload),
             .recentlyViewed(let payload),
             .recommendations(let payload):
            items = payload.products
        default:
            items = []
        }

        if let limit = section.configuration?.limit {
            return Array(items.prefix(limit))
        }
        return items
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: section.effectiveSpacing) {
            HomeSectionHeaderView(
                title: section.title,
                showTitle: section.effectiveShowTitle,
                showSeeAll: section.effectiveShowSeeAll,
                onSeeAll: section.effectiveShowSeeAll
                    ? { actionHandler.handle(.section(id: section.id)) }
                    : nil
            )

            HomeSectionBuiltInContent.emptyOrContent(
                isEmpty: products.isEmpty,
                sectionType: section.type
            ) {
                HomeSectionItemsLayoutView(
                    layout: section.effectiveLayout,
                    spacing: section.effectiveSpacing,
                    configuredColumns: section.configuredGridColumns,
                    defaultColumns: 2,
                    items: products
                ) { product in
                    ProductCardView(product: product) {
                        actionHandler.handle(.product(id: product.id))
                    }
                }
            }
        }
    }
}
