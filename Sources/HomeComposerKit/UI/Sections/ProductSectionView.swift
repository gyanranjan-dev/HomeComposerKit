import SwiftUI

/// Product strip used for products, popular products, and favorites.
public struct ProductSectionView: View {
    let section: ComposedHomeSection

    @Environment(\.homeActionHandler) private var actionHandler

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var products: [Product] {
        let items: [Product]
        switch section.content {
        case .products(let payload),
             .popularProducts(let payload),
             .favoriteProducts(let payload):
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

            if products.isEmpty {
                Text("No products")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .accessibilityLabel("No products available")
            } else {
                HomeSectionItemsLayoutView(
                    layout: section.effectiveLayout,
                    spacing: section.effectiveSpacing,
                    columns: section.effectiveColumns(default: 2),
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
