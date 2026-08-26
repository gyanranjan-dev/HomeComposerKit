import Foundation

/// Builds a ``HomeRenderContext`` from host-provided JSON, providers, or models.
///
/// This is the primary Integration-layer entry point between the host app and
/// HomeComposerKit. It reuses ``HomePageDecoder`` and does not perform network I/O.
///
/// Typical host usage:
/// ```swift
/// // Host networking returns Data…
/// let context = try HomeRenderContextBuilder().makeContext(
///     from: data,
///     contentBySectionID: content
/// )
/// let sections = context.compose()
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
    /// - Returns: A context ready for composition and ``HomeComposerView``.
    public func makeContext(
        from data: Data,
        contentBySectionID: [String: HomeSectionContent] = [:]
    ) throws -> HomeRenderContext {
        let homePage = try decoder.decode(data)
        return HomeRenderContext(
            homePage: homePage,
            contentBySectionID: contentBySectionID
        )
    }

    /// Decodes a JSON string and pairs it with section content.
    public func makeContext(
        from json: String,
        contentBySectionID: [String: HomeSectionContent] = [:]
    ) throws -> HomeRenderContext {
        let homePage = try decoder.decode(json)
        return HomeRenderContext(
            homePage: homePage,
            contentBySectionID: contentBySectionID
        )
    }

    /// Creates a context from an already-decoded home page.
    public func makeContext(
        homePage: HomePage,
        contentBySectionID: [String: HomeSectionContent] = [:]
    ) -> HomeRenderContext {
        HomeRenderContext(
            homePage: homePage,
            contentBySectionID: contentBySectionID
        )
    }

    /// Builds a context from a host ``HomePageProviding`` implementation.
    public func makeContext(
        from provider: some HomePageProviding,
        contentBySectionID: [String: HomeSectionContent] = [:]
    ) throws -> HomeRenderContext {
        let homePage = try provider.makeHomePage()
        return makeContext(
            homePage: homePage,
            contentBySectionID: contentBySectionID
        )
    }

    /// Builds a context from a host ``HomePageDataProviding`` implementation.
    ///
    /// Decoding is delegated to ``HomePageDecoder`` (no duplicated decode logic).
    public func makeContext(
        fromDataProvider provider: some HomePageDataProviding,
        contentBySectionID: [String: HomeSectionContent] = [:]
    ) throws -> HomeRenderContext {
        let data = try provider.makeHomePageData()
        return try makeContext(
            from: data,
            contentBySectionID: contentBySectionID
        )
    }
}
