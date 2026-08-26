import SwiftUI

/// Favorites section that reuses the shared product card presentation.
public struct FavoritesSectionView: View {
    let section: ComposedHomeSection

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var products: [Product] {
        if case .favoriteProducts(let payload) = section.content {
            return payload.products
        }
        return []
    }

    public var body: some View {
        ProductStripSectionView(title: section.title, products: products)
    }
}

struct FavoritesSectionRenderer: HomeSectionRenderer {
    func canRender(_ type: HomeSectionType) -> Bool {
        type == .favoriteProducts
    }

    @MainActor
    func render(_ section: ComposedHomeSection) -> AnyView {
        AnyView(FavoritesSectionView(section: section))
    }
}
