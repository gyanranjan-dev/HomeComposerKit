import Foundation

/// Builds a ``HomeRenderContext`` from host-provided JSON, providers, or models.
///
/// Primary Integration-layer entry point. Reuses ``HomePageDecoder`` and never
/// performs network I/O.
///
/// Recommended host flow:
/// ```swift
/// let response = try HomeAPIResponseDecoder().decode(data)
/// let context = HomeRenderContextBuilder().makeContext(
///     from: response,
///     contentBySectionID: content
/// )
/// let validation = context.validate(diagnosticReporter: hostReporter)
/// let view = HomeComposerView(context: context, rendererRegistry: registry)
/// ```
public struct HomeRenderContextBuilder: Sendable {

    private let decoder: HomePageDecoder

    /// Creates a builder.
    ///
    /// - Parameter decoder: Decoder used to turn JSON into ``HomePage``.
    public init(decoder: HomePageDecoder = HomePageDecoder()) {
        self.decoder = decoder
    }

    /// Decodes JSON data and pairs it with section content.
    ///
    /// - Parameters:
    ///   - data: UTF-8 JSON bytes from the host networking layer.
    ///   - contentBySectionID: Section payloads keyed by section `id`.
    ///   - validate: When `true`, runs ``HomePageValidator`` and reports diagnostics.
    ///   - diagnosticReporter: Host reporter used when `validate` is `true`.
    /// - Returns: A context ready for composition and ``HomeComposerView``.
    public func makeContext(
        from data: Data,
        contentBySectionID: [String: HomeSectionContent] = [:],
        validate: Bool = false,
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter()
    ) throws -> HomeRenderContext {
        let homePage = try decoder.decode(data)
        let context = HomeRenderContext(
            homePage: homePage,
            contentBySectionID: contentBySectionID
        )
        if validate {
            context.validate(diagnosticReporter: diagnosticReporter)
        }
        return context
    }

    /// Decodes a JSON string and pairs it with section content.
    public func makeContext(
        from json: String,
        contentBySectionID: [String: HomeSectionContent] = [:],
        validate: Bool = false,
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter()
    ) throws -> HomeRenderContext {
        let homePage = try decoder.decode(json)
        let context = HomeRenderContext(
            homePage: homePage,
            contentBySectionID: contentBySectionID
        )
        if validate {
            context.validate(diagnosticReporter: diagnosticReporter)
        }
        return context
    }

    /// Creates a context from an already-decoded home page.
    public func makeContext(
        homePage: HomePage,
        contentBySectionID: [String: HomeSectionContent] = [:],
        validate: Bool = false,
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter()
    ) -> HomeRenderContext {
        let context = HomeRenderContext(
            homePage: homePage,
            contentBySectionID: contentBySectionID
        )
        if validate {
            context.validate(diagnosticReporter: diagnosticReporter)
        }
        return context
    }

    /// Builds a context from a decoded ``HomeAPIResponse``.
    ///
    /// Converts the API envelope into ``HomePage`` and pairs it with host-resolved
    /// section content. Does not fetch ``HomeAPISection/contentRef`` values.
    public func makeContext(
        from response: HomeAPIResponse,
        contentBySectionID: [String: HomeSectionContent] = [:],
        validate: Bool = false,
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter()
    ) -> HomeRenderContext {
        makeContext(
            homePage: response.makeHomePage(),
            contentBySectionID: contentBySectionID,
            validate: validate,
            diagnosticReporter: diagnosticReporter
        )
    }

    /// Decodes a ``HomeAPIResponse`` envelope from data, then builds a render context.
    public func makeContext(
        fromAPIResponse data: Data,
        contentBySectionID: [String: HomeSectionContent] = [:],
        validate: Bool = false,
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter(),
        apiDecoder: HomeAPIResponseDecoder = HomeAPIResponseDecoder()
    ) throws -> HomeRenderContext {
        let response = try apiDecoder.decode(data)
        return makeContext(
            from: response,
            contentBySectionID: contentBySectionID,
            validate: validate,
            diagnosticReporter: diagnosticReporter
        )
    }

    /// Builds a context from a host ``HomePageProviding`` implementation.
    public func makeContext(
        from provider: some HomePageProviding,
        contentBySectionID: [String: HomeSectionContent] = [:],
        validate: Bool = false,
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter()
    ) throws -> HomeRenderContext {
        let homePage = try provider.makeHomePage()
        return makeContext(
            homePage: homePage,
            contentBySectionID: contentBySectionID,
            validate: validate,
            diagnosticReporter: diagnosticReporter
        )
    }

    /// Builds a context from a host ``HomePageDataProviding`` implementation.
    public func makeContext(
        fromDataProvider provider: some HomePageDataProviding,
        contentBySectionID: [String: HomeSectionContent] = [:],
        validate: Bool = false,
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter()
    ) throws -> HomeRenderContext {
        let data = try provider.makeHomePageData()
        return try makeContext(
            from: data,
            contentBySectionID: contentBySectionID,
            validate: validate,
            diagnosticReporter: diagnosticReporter
        )
    }
}
