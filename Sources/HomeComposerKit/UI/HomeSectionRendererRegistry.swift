import SwiftUI

/// Stores section-type → SwiftUI renderer mappings.
///
/// Built-in renderers are registered by ``makeDefault()``. Host apps can
/// register additional renderers for types such as `.custom` without
/// modifying framework internals.
@MainActor
public struct HomeSectionRendererRegistry {

    private var renderers: [HomeSectionType: (ComposedHomeSection) -> AnyView] = [:]

    public init() {}

    /// Registers a renderer for a section type, replacing any existing mapping.
    public mutating func register<Content: View>(
        _ type: HomeSectionType,
        @ViewBuilder renderer: @escaping (ComposedHomeSection) -> Content
    ) {
        renderers[type] = { section in
            AnyView(renderer(section))
        }
    }

    /// Whether a renderer is registered for the given section type.
    public func isRegistered(for type: HomeSectionType) -> Bool {
        renderers[type] != nil
    }

    /// Returns the registered view, or `EmptyView` when no renderer exists.
    public func view(for section: ComposedHomeSection) -> AnyView {
        if let renderer = renderers[section.type] {
            return renderer(section)
        }
        return AnyView(EmptyView())
    }

    /// Default registry with built-in section renderers.
    public static func makeDefault() -> HomeSectionRendererRegistry {
        var registry = HomeSectionRendererRegistry()
        registry.registerBuiltInRenderers()
        return registry
    }

    /// Returns a copy of this registry with an additional (or replacement) renderer.
    ///
    /// Useful for host apps that want a fluent customization style:
    ///
    /// ```swift
    /// let registry = HomeSectionRendererRegistry.makeDefault()
    ///     .registering(.custom) { MyCustomSectionView(section: $0) }
    /// ```
    public func registering<Content: View>(
        _ type: HomeSectionType,
        @ViewBuilder renderer: @escaping (ComposedHomeSection) -> Content
    ) -> HomeSectionRendererRegistry {
        var copy = self
        copy.register(type, renderer: renderer)
        return copy
    }

    private mutating func registerBuiltInRenderers() {
        register(.banner) { BannerSectionView(section: $0) }
        register(.categories) { CategorySectionView(section: $0) }
        register(.products) { ProductSectionView(section: $0) }
        register(.popularProducts) { ProductSectionView(section: $0) }
        register(.favoriteProducts) { ProductSectionView(section: $0) }
        register(.liveStream) { LiveSectionView(section: $0) }
        register(.social) { SocialSectionView(section: $0) }
    }
}
