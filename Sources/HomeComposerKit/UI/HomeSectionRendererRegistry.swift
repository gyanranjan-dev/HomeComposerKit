import SwiftUI

/// Stores section-type → SwiftUI renderer mappings.
///
/// ## Built-in renderers
///
/// ``makeDefault()`` and ``default`` provide built-in renderers for standard
/// section types such as `.banner`, `.products`, and `.categories`.
///
/// ## Custom renderer registration
///
/// Host apps register custom renderers on a registry **instance** at startup.
/// Registration by raw backend type string is supported for unknown section
/// types decoded as ``HomeSectionType/unknown(_:)``:
///
/// ```swift
/// let registry = HomeSectionRendererRegistry.default
///     .registering(type: "flash_sale") { section in
///         FlashSaleSectionView(section: section)
///     }
///
/// HomeComposerView(context: context, rendererRegistry: registry)
/// ```
///
/// Protocol-based registration is also supported via ``HomeSectionRendering``.
///
/// ## Override behavior
///
/// Registering a renderer for an already-mapped type **replaces** the existing
/// mapping. Host overrides therefore take precedence over built-in renderers.
///
/// ## Fallback behavior
///
/// Unregistered section types (including unknown backend types) safely render
/// as `EmptyView` — they never crash the host application.
@MainActor
public struct HomeSectionRendererRegistry {

    private var renderers: [HomeSectionType: (ComposedHomeSection) -> AnyView] = [:]

    public init() {}

    /// Default registry with built-in section renderers.
    public static func makeDefault() -> HomeSectionRendererRegistry {
        var registry = HomeSectionRendererRegistry()
        registry.registerBuiltInRenderers()
        return registry
    }

    /// Default registry with built-in section renderers.
    public static var `default`: HomeSectionRendererRegistry {
        makeDefault()
    }

    // MARK: - Registration (HomeSectionType)

    /// Registers a renderer for a section type, replacing any existing mapping.
    ///
    /// Host registrations replace built-in mappings for the same type.
    public mutating func register<Content: View>(
        _ type: HomeSectionType,
        @ViewBuilder renderer: @escaping (ComposedHomeSection) -> Content
    ) {
        renderers[type] = { section in
            AnyView(renderer(section))
        }
    }

    /// Registers a ``HomeSectionRendering`` implementation for a section type.
    public mutating func register<R: HomeSectionRendering>(
        _ type: HomeSectionType,
        renderer: R
    ) {
        register(type) { section in
            renderer.render(section: section)
        }
    }

    // MARK: - Registration (raw backend type)

    /// Registers a renderer for a backend section type string.
    ///
    /// Known types resolve through ``HomeSectionType/parse(_:)``. Unknown values
    /// are stored as ``HomeSectionType/unknown(_:)`` using the original string.
    public mutating func register<Content: View>(
        type rawType: String,
        @ViewBuilder renderer: @escaping (ComposedHomeSection) -> Content
    ) {
        register(HomeSectionType.parse(rawType), renderer: renderer)
    }

    /// Registers a ``HomeSectionRendering`` implementation for a backend type string.
    public mutating func register<R: HomeSectionRendering>(
        type rawType: String,
        renderer: R
    ) {
        register(HomeSectionType.parse(rawType), renderer: renderer)
    }

    // MARK: - Fluent registration

    /// Returns a copy of this registry with an additional (or replacement) renderer.
    public func registering<Content: View>(
        _ type: HomeSectionType,
        @ViewBuilder renderer: @escaping (ComposedHomeSection) -> Content
    ) -> HomeSectionRendererRegistry {
        var copy = self
        copy.register(type, renderer: renderer)
        return copy
    }

    /// Returns a copy with a renderer registered for a backend type string.
    public func registering<Content: View>(
        type rawType: String,
        @ViewBuilder renderer: @escaping (ComposedHomeSection) -> Content
    ) -> HomeSectionRendererRegistry {
        var copy = self
        copy.register(type: rawType, renderer: renderer)
        return copy
    }

    /// Returns a copy with a ``HomeSectionRendering`` implementation registered.
    public func registering<R: HomeSectionRendering>(
        type rawType: String,
        renderer: R
    ) -> HomeSectionRendererRegistry {
        var copy = self
        copy.register(type: rawType, renderer: renderer)
        return copy
    }

    // MARK: - Resolution

    /// Whether a renderer is registered for the given section type.
    public func isRegistered(for type: HomeSectionType) -> Bool {
        renderers[type] != nil
    }

    /// Whether a renderer is registered for a backend section type string.
    public func isRegistered(for rawType: String) -> Bool {
        isRegistered(for: HomeSectionType.parse(rawType))
    }

    /// Returns the registered view, or `EmptyView` when no renderer exists.
    public func view(for section: ComposedHomeSection) -> AnyView {
        if let renderer = renderers[section.type] {
            return renderer(section)
        }
        return AnyView(EmptyView())
    }

    // MARK: - Built-ins

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
