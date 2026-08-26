import SwiftUI

/// Horizontal scrolling product cards for a standard products section.
public struct ProductSectionView: View {
    let section: ComposedHomeSection

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var products: [Product] {
        if case .products(let payload) = section.content {
            return payload.products
        }
        return []
    }

    public var body: some View {
        ProductStripSectionView(title: section.title, products: products)
    }
}

/// Shared horizontal product strip used by products / favorites / popular.
struct ProductStripSectionView: View {
    let title: String?
    let products: [Product]

    var body: some View {
        HomeSectionContainer(title: title) {
            if products.isEmpty {
                Text("No products")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(products) { product in
                            ProductCardView(product: product)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct ProductSectionRenderer: HomeSectionRenderer {
    func canRender(_ type: HomeSectionType) -> Bool {
        type == .products
    }

    @MainActor
    func render(_ section: ComposedHomeSection) -> AnyView {
        AnyView(ProductSectionView(section: section))
    }
}
