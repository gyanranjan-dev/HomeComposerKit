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
///
/// ## Accessibility
///
/// Built-in views support Dynamic Type and derive VoiceOver labels from section
/// content. Explicit ``SectionConfiguration/columns`` values are always respected;
/// when columns are omitted, grid layouts adapt to available width. Custom host
/// renderers are responsible for their own accessibility semantics.
///
/// ## Performance
///
/// Large pages use ``LazyVStack`` for section lists and lazy item layouts inside
/// sections. Stable section and model IDs help SwiftUI diff efficiently. The
/// framework avoids global caches; identity transformation pipelines short-circuit
/// without per-section work.
///
/// ## Diagnostics
///
/// Diagnostics are developer observability only — not analytics or telemetry.
/// Pass a ``HomeComposerDiagnosticReporting`` implementation (or use
/// ``CollectingHomeDiagnosticReporter`` in tests). Default is silent no-op.
/// HomeComposerKit does not persist, transmit, or print diagnostics. Avoid
/// sensitive user identifiers in custom metadata; the host owns reporter behavior.
public struct HomeComposerView: View {

    public let homePage: HomePage

    private let contentBySectionID: [String: HomeSectionContent]
    private let composer: HomeComposer
    private let rendererRegistry: HomeSectionRendererRegistry
    private let actionHandler: HomeActionHandler
    private let theme: HomeComposerTheme
    private let transformationPipeline: HomeSectionContentTransformerPipeline
    private let personalizationContext: HomePersonalizationContext
    private let sectionStates: [String: HomeSectionState]
    private let sectionStateConfiguration: HomeSectionStateConfiguration
    private let diagnosticReporter: any HomeComposerDiagnosticReporting

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
    ///   - sectionStates: Optional host-provided presentation states keyed by section `id`.
    ///   - sectionStateConfiguration: Customizable loading, empty, and error presentation.
    ///   - diagnosticReporter: Optional host reporter for composition, rendering,
    ///     transformation, and state diagnostics. Defaults to silent no-op.
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
        sectionStates: [String: HomeSectionState] = [:],
        sectionStateConfiguration: HomeSectionStateConfiguration = .default,
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter(),
        onAction: ((HomeAction) -> Void)? = nil
    ) {
        self.homePage = homePage
        self.contentBySectionID = contentBySectionID
        self.composer = composer
        self.rendererRegistry = rendererRegistry
        self.theme = theme
        self.transformationPipeline = transformationPipeline
        self.personalizationContext = personalizationContext
        self.sectionStates = sectionStates
        self.sectionStateConfiguration = sectionStateConfiguration
        self.diagnosticReporter = diagnosticReporter
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
        sectionStates: [String: HomeSectionState] = [:],
        sectionStateConfiguration: HomeSectionStateConfiguration = .default,
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter(),
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
            sectionStates: sectionStates,
            sectionStateConfiguration: sectionStateConfiguration,
            diagnosticReporter: diagnosticReporter,
            onAction: onAction
        )
    }

    public var body: some View {
        let sections = composer.compose(
            homePage,
            contentBySectionID: contentBySectionID,
            diagnosticReporter: diagnosticReporter,
            transformationPipeline: transformationPipeline,
            context: transformationPipeline.hasTransformers
                ? HomeRenderContext(homePage: homePage, contentBySectionID: contentBySectionID)
                : nil,
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
        .homeSectionStates(sectionStates)
        .homeSectionStateConfiguration(sectionStateConfiguration)
        .homeDiagnosticReporter(diagnosticReporter)
        .background {
            HomeSectionStateDiagnosticObserver(
                sectionStates: sectionStates,
                sections: sections,
                reporter: diagnosticReporter
            )
        }
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
