import SwiftUI

/// Top-level SwiftUI entry point for rendering a dynamic home page.
///
/// Uses `HomeComposer` for ordering and filtering, then renders each
/// `ComposedHomeSection` through `HomeSectionView` and a renderer registry.
///
/// ## Action handling
///
/// ``HomeComposerKit`` emits ``HomeAction`` values when users interact with
/// built-in section views. The host application interprets those actions:
///
/// ```swift
/// HomeComposerView(
///     homePage: page,
///     onAction: { action in
///         switch action {
///         case .product(let id):
///             // host navigation
///         default:
///             break
///         }
///     }
/// )
/// ```
///
/// ## Theming
///
/// Pass a ``HomeComposerTheme`` to customize spacing, typography, and colors:
///
/// ```swift
/// HomeComposerView(homePage: page, theme: .default)
/// ```
public struct HomeComposerView: View {

    public let homePage: HomePage

    private let contentBySectionID: [String: HomeSectionContent]
    private let composer: HomeComposer
    private let rendererRegistry: HomeSectionRendererRegistry
    private let actionHandler: HomeActionHandler
    private let theme: HomeComposerTheme
    private let transformationPipeline: HomeSectionContentTransformerPipeline
    private let personalizationContext: HomePersonalizationContext

    /// Creates a home page view.
    ///
    /// - Parameters:
    ///   - homePage: The configured home page to compose and render.
    ///   - contentBySectionID: Optional section payloads keyed by section `id`.
    ///   - composer: Composer used to produce ordered renderable sections.
    ///   - rendererRegistry: Section renderer mappings. Defaults to built-in renderers.
    ///   - theme: Visual theme for built-in section renderers. Defaults to ``HomeComposerTheme/default``.
    ///   - transformationPipeline: Optional post-composition content transformers.
    ///   - personalizationContext: Optional host personalization signals for transformers.
    ///   - onAction: Optional host callback for user interactions. When omitted,
    ///     interactions are safely ignored.
    public init(
        homePage: HomePage,
        contentBySectionID: [String: HomeSectionContent] = [:],
        composer: HomeComposer = HomeComposer(),
        rendererRegistry: HomeSectionRendererRegistry = .makeDefault(),
        theme: HomeComposerTheme = .default,
        transformationPipeline: HomeSectionContentTransformerPipeline = .identity,
        personalizationContext: HomePersonalizationContext = .empty,
        onAction: ((HomeAction) -> Void)? = nil
    ) {
        self.homePage = homePage
        self.contentBySectionID = contentBySectionID
        self.composer = composer
        self.rendererRegistry = rendererRegistry
        self.theme = theme
        self.transformationPipeline = transformationPipeline
        self.personalizationContext = personalizationContext
        self.actionHandler = onAction.map(HomeActionHandler.init) ?? .noop
    }

    /// Creates a home page view from a host-prepared ``HomeRenderContext``.
    ///
    /// Typical host flow:
    /// 1. Fetch JSON with the host networking stack
    /// 2. Build a context with ``HomeRenderContextBuilder``
    /// 3. Optionally customize ``HomeSectionRendererRegistry``
    /// 4. Create `HomeComposerView(context:rendererRegistry:theme:onAction:)`
    public init(
        context: HomeRenderContext,
        composer: HomeComposer = HomeComposer(),
        rendererRegistry: HomeSectionRendererRegistry = .makeDefault(),
        theme: HomeComposerTheme = .default,
        transformationPipeline: HomeSectionContentTransformerPipeline = .identity,
        personalizationContext: HomePersonalizationContext = .empty,
        onAction: ((HomeAction) -> Void)? = nil
    ) {
        self.init(
            homePage: context.homePage,
            contentBySectionID: context.contentBySectionID,
            composer: composer,
            rendererRegistry: rendererRegistry,
            theme: theme,
            transformationPipeline: transformationPipeline,
            personalizationContext: personalizationContext,
            onAction: onAction
        )
    }

    public var body: some View {
        let renderContext = HomeRenderContext(
            homePage: homePage,
            contentBySectionID: contentBySectionID
        )
        let sections = composer.compose(
            homePage,
            contentBySectionID: contentBySectionID,
            transformationPipeline: transformationPipeline,
            context: renderContext,
            personalization: personalizationContext
        )

        ScrollView {
            LazyVStack(alignment: .leading, spacing: theme.sectionSpacing) {
                if let title = homePage.title, !title.isEmpty {
                    Text(title)
                        .font(theme.typography.pageTitle)
                        .padding(.horizontal, theme.horizontalContentPadding)
                        .padding(.top, theme.spacing.small)
                        .accessibilityAddTraits(.isHeader)
                }

                ForEach(sections) { section in
                    HomeSectionView(section: section, registry: rendererRegistry)
                }
            }
            .padding(.bottom, theme.sectionSpacing)
        }
        .background(theme.backgroundColor)
        .homeComposerTheme(theme)
        .homeActionHandler(actionHandler)
        .homeSectionContentTransformerPipeline(transformationPipeline)
        .homePersonalizationContext(personalizationContext)
    }
}

#if DEBUG
struct HomeComposerView_Previews: PreviewProvider {
    static var previews: some View {
        let context = HomeRenderContextBuilder().makeContext(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )
        return HomeComposerView(context: context)
    }
}
#endif
