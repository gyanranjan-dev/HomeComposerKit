import SwiftUI

/// Maps `HomeSectionType` values to SwiftUI renderers.
///
/// Host apps can register additional renderers without rewriting `HomeView`.
public struct HomeSectionRegistry {

    private var renderers: [HomeSectionType: any HomeSectionRenderer] = [:]

    public init() {}

    /// Registers a renderer for a section type, replacing any existing mapping.
    public mutating func register(_ renderer: some HomeSectionRenderer, for type: HomeSectionType) {
        renderers[type] = renderer
    }

    /// Returns a view for the section, or an empty view when no renderer is registered.
    @MainActor
    public func view(for section: ComposedHomeSection) -> AnyView {
        if let renderer = renderers[section.type], renderer.canRender(section.type) {
            return renderer.render(section)
        }
        return AnyView(EmptyView())
    }

    /// Default registry with built-in section renderers.
    public static func makeDefault() -> HomeSectionRegistry {
        var registry = HomeSectionRegistry()
        registry.register(BannerSectionRenderer(), for: .banner)
        registry.register(CategorySectionRenderer(), for: .categories)
        registry.register(ProductSectionRenderer(), for: .products)
        registry.register(PopularProductSectionRenderer(), for: .popularProducts)
        registry.register(FavoritesSectionRenderer(), for: .favoriteProducts)
        registry.register(LiveSectionRenderer(), for: .liveStream)
        registry.register(SocialSectionRenderer(), for: .social)
        return registry
    }
}
