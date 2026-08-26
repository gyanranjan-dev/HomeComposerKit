import SwiftUI

/// Top-level SwiftUI entry point for rendering a dynamic home page.
///
/// Uses `HomeComposer` for ordering and filtering, then renders each
/// `ComposedHomeSection` through `HomeSectionView` and a renderer registry.
public struct HomeComposerView: View {

    public let homePage: HomePage

    private let contentBySectionID: [String: HomeSectionContent]
    private let composer: HomeComposer
    private let rendererRegistry: HomeSectionRendererRegistry

    /// Creates a home page view.
    ///
    /// - Parameters:
    ///   - homePage: The configured home page to compose and render.
    ///   - contentBySectionID: Optional section payloads keyed by section `id`.
    ///   - composer: Composer used to produce ordered renderable sections.
    ///   - rendererRegistry: Section renderer mappings. Defaults to built-in renderers.
    public init(
        homePage: HomePage,
        contentBySectionID: [String: HomeSectionContent] = [:],
        composer: HomeComposer = HomeComposer(),
        rendererRegistry: HomeSectionRendererRegistry = .makeDefault()
    ) {
        self.homePage = homePage
        self.contentBySectionID = contentBySectionID
        self.composer = composer
        self.rendererRegistry = rendererRegistry
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
    }
}

#if DEBUG
struct HomeComposerView_Previews: PreviewProvider {
    static var previews: some View {
        HomeComposerView(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )
    }
}
#endif
