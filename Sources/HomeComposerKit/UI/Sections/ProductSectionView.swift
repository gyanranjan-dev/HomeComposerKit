import SwiftUI

/// Product strip used for products, popular products, and favorites.
public struct ProductSectionView: View {
    let section: ComposedHomeSection

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

    private var spacing: CGFloat {
        CGFloat(section.configuration?.spacing ?? 12)
    }

    private var usesGridLayout: Bool {
        section.configuration?.layout?.lowercased() == "grid"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HomeSectionHeaderView(
                title: section.title,
                showTitle: shouldShowTitle,
                showSeeAll: false
            )

            if products.isEmpty {
                Text("No products")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .accessibilityLabel("No products available")
            } else if usesGridLayout {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 148), spacing: spacing)
                    ],
                    spacing: spacing
                ) {
                    ForEach(products) { product in
                        ProductCardView(product: product)
                    }
                }
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: spacing) {
                        ForEach(products) { product in
                            ProductCardView(product: product)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var shouldShowTitle: Bool {
        !(section.title ?? "").isEmpty
    }
}
