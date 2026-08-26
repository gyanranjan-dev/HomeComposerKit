import SwiftUI

/// Renders a composed home section as a SwiftUI view.
///
/// Implementations stay focused on presentation. Business rules and
/// composition belong in the model and composition layers.
public protocol HomeSectionRenderer {
    /// Whether this renderer handles the given section type.
    func canRender(_ type: HomeSectionType) -> Bool

    /// Builds a SwiftUI view for the composed section.
    @MainActor
    func render(_ section: ComposedHomeSection) -> AnyView
}
