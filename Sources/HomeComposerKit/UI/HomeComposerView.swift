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
public struct HomeComposerView: View {

    public let homePage: HomePage

    private let contentBySectionID: [String: HomeSectionContent]
    private let composer: HomeComposer
    private let rendererRegistry: HomeSectionRendererRegistry
    private let actionHandler: HomeActionHandler

    /// Creates a home page view.
    ///
    /// - Parameters:
    ///   - homePage: The configured home page to compose and render.
    ///   - contentBySectionID: Optional section payloads keyed by section `id`.
    ///   - composer: Composer used to produce ordered renderable sections.
    ///   - rendererRegistry: Section renderer mappings. Defaults to built-in renderers.
    ///   - onAction: Optional host callback for user interactions. When omitted,
    ///     interactions are safely ignored.
    public init(
        homePage: HomePage,
        contentBySectionID: [String: HomeSectionContent] = [:],
        composer: HomeComposer = HomeComposer(),
        rendererRegistry: HomeSectionRendererRegistry = .makeDefault(),
        onAction: ((HomeAction) -> Void)? = nil
    ) {
        self.homePage = homePage
        self.contentBySectionID = contentBySectionID
        self.composer = composer
        self.rendererRegistry = rendererRegistry
        self.actionHandler = onAction.map(HomeActionHandler.init) ?? .noop
    }

    /// Creates a home page view from a host-prepared ``HomeRenderContext``.
    ///
    /// Typical host flow:
    /// 1. Fetch JSON with the host networking stack
    /// 2. Build a context with ``HomeRenderContextBuilder``
    /// 3. Optionally customize ``HomeSectionRendererRegistry``
    /// 4. Create `HomeComposerView(context:rendererRegistry:onAction:)`
    public init(
        context: HomeRenderContext,
        composer: HomeComposer = HomeComposer(),
        rendererRegistry: HomeSectionRendererRegistry = .makeDefault(),
        onAction: ((HomeAction) -> Void)? = nil
    ) {
        self.init(
            homePage: context.homePage,
            contentBySectionID: context.contentBySectionID,
            composer: composer,
            rendererRegistry: rendererRegistry,
            onAction: onAction
        )
    }

    public var body: some View {
        let sections = composer.compose(
            homePage,
            contentBySectionID: contentBySectionID
        )

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if let title = homePage.title, !title.isEmpty {
                    Text(title)
                        .font(.largeTitle.bold())
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .accessibilityAddTraits(.isHeader)
                }

                ForEach(sections) { section in
                    HomeSectionView(section: section, registry: rendererRegistry)
                }
            }
            .padding(.bottom, 24)
        }
        .background(HomeUIColor.groupedBackground)
        .homeActionHandler(actionHandler)
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
