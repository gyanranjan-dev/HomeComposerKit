import Foundation

/// Host-prepared input for rendering a home page.
///
/// Architecture:
/// ```text
/// Host owns network / auth
///         ↓
///   JSON Data / HomePage
///         ↓
/// Decode (HomePageDecoder) — unknown section types preserved
///         ↓
/// Validate (optional HomePageValidator + diagnostics)
///         ↓
/// HomeRenderContext
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

    /// Validates the decoded home page and optionally reports diagnostics.
    ///
    /// Validation is optional and never throws. Existing callers that skip
    /// validation remain unaffected.
    @discardableResult
    public func validate(
        using validator: HomePageValidator = HomePageValidator(),
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter()
    ) -> HomeValidationResult {
        let result = validator.validate(homePage)
        diagnosticReporter.report(result)
        return result
    }

    /// Composes renderable sections using the injected content map.
    ///
    /// Presentation stays outside this method; callers pass the result (or this
    /// context) into ``HomeComposerView``.
    public func compose(
        using composer: HomeComposer = HomeComposer(),
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter()
    ) -> [ComposedHomeSection] {
        composer.compose(
            homePage,
            contentBySectionID: contentBySectionID,
            diagnosticReporter: diagnosticReporter
        )
    }
}
