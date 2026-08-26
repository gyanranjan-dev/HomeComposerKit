import Foundation

/// Converts a `HomePage` configuration into an ordered list of renderable sections.
///
/// The composer is domain-agnostic: it filters, sorts, and maps sections using
/// type and configuration only. It does not perform networking or UI work.
public struct HomeComposer: Sendable {

    public init() {}

    /// Composes an ordered list of sections ready for rendering.
    ///
    /// - Parameters:
    ///   - homePage: The configured home page to compose.
    ///   - contentBySectionID: Optional section payloads keyed by section `id`.
    /// - Returns: Enabled sections sorted by `order`. When two sections share
    ///   the same order, their relative position from the original API array is preserved.
    ///   Empty content does not prevent a section from being returned.
    public func compose(
        _ homePage: HomePage,
        contentBySectionID: [String: HomeSectionContent] = [:]
    ) -> [ComposedHomeSection] {
        homePage.sections
            .enumerated()
            .filter { _, section in
                section.canCompose
            }
            .sorted { lhs, rhs in
                if lhs.element.order != rhs.element.order {
                    return lhs.element.order < rhs.element.order
                }
                return lhs.offset < rhs.offset
            }
            .map { _, section in
                ComposedHomeSection(
                    section: section,
                    content: contentBySectionID[section.id]
                )
            }
    }
}
