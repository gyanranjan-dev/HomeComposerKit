import SwiftUI

/// Renders a composed home section as SwiftUI content.
///
/// Conform to this protocol to provide host-specific section renderers without
/// modifying HomeComposerKit internals. Custom renderers automatically receive
/// ``HomeComposerTheme``, ``HomeImageProvider``, and ``HomeAction`` handling
/// from the SwiftUI environment when rendered inside ``HomeComposerView``.
@MainActor
public protocol HomeSectionRendering {
    associatedtype Body: View

    /// Builds the SwiftUI representation for a composed section.
    @ViewBuilder
    func render(section: ComposedHomeSection) -> Body
}
