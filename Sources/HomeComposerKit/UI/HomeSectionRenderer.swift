import SwiftUI

/// Resolves a `ComposedHomeSection` through a ``HomeSectionRendererRegistry``.
///
/// Built-in mappings live in the default registry. Host apps should register
/// custom section types on a registry instance instead of modifying this type.
@MainActor
enum HomeSectionRenderer {

    /// Builds the SwiftUI representation for a composed section.
    static func view(
        for section: ComposedHomeSection,
        in registry: HomeSectionRendererRegistry
    ) -> AnyView {
        registry.view(for: section)
    }
}
