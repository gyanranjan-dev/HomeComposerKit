import Foundation

/// Host-prepared input for rendering a home page.
///
/// Architecture:
/// ```text
/// Host owns network / auth
///         ↓
///   JSON Data / HomePage
///         ↓
/// HomeRenderContextBuilder  (decode + attach content)
///         ↓
///   HomeRenderContext
///         ↓
/// HomeComposer → [ComposedHomeSection]
///         ↓
/// HomeComposerView (+ optional HomeSectionRendererRegistry)
/// ```
///
/// This type intentionally contains no networking or SwiftUI dependencies.
public struct HomeRenderContext: Sendable {

    /// Decoded home page configuration.
    public let homePage: HomePage

    /// Section payloads keyed by section `id`.
    public let contentBySectionID: [String: HomeSectionContent]

    /// Creates a render context.
    ///
    /// - Parameters:
    ///   - homePage: The configured home page.
    ///   - contentBySectionID: Optional payloads for each section `id`.
    public init(
        homePage: HomePage,
        contentBySectionID: [String: HomeSectionContent] = [:]
    ) {
        self.homePage = homePage
        self.contentBySectionID = contentBySectionID
    }

    /// Composes renderable sections using the injected content map.
    ///
    /// Presentation stays outside this method; callers pass the result (or this
    /// context) into ``HomeComposerView``.
    public func compose(
        using composer: HomeComposer = HomeComposer()
    ) -> [ComposedHomeSection] {
        composer.compose(homePage, contentBySectionID: contentBySectionID)
    }
}
