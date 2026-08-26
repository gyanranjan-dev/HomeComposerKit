import SwiftUI

/// Popular products section that reuses the shared product card presentation.
public struct PopularProductSectionView: View {
    let section: ComposedHomeSection

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var products: [Product] {
        if case .popularProducts(let payload) = section.content {
            return payload.products
        }
        return []
    }

    public var body: some View {
        ProductStripSectionView(title: section.title, products: products)
    }
}

struct PopularProductSectionRenderer: HomeSectionRenderer {
    func canRender(_ type: HomeSectionType) -> Bool {
        type == .popularProducts
    }

    @MainActor
    func render(_ section: ComposedHomeSection) -> AnyView {
        AnyView(PopularProductSectionView(section: section))
    }
}
