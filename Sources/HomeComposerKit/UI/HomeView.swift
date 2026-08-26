import SwiftUI

/// Renders a composed home page as a vertical stack of section views.
///
/// Uses `HomeComposer` for ordering/filtering and `HomeSectionRegistry`
/// for section-type rendering. Contains no networking or domain logic.
public struct HomeView: View {

    private let homePage: HomePage
    private let contentBySectionID: [String: HomeSectionContent]
    private let composer: HomeComposer
    private let registry: HomeSectionRegistry

    public init(
        homePage: HomePage,
        contentBySectionID: [String: HomeSectionContent] = [:],
        composer: HomeComposer = HomeComposer(),
        registry: HomeSectionRegistry = .makeDefault()
    ) {
        self.homePage = homePage
        self.contentBySectionID = contentBySectionID
        self.composer = composer
        self.registry = registry
    }

    public var body: some View {
        let sections = composer.compose(homePage, contentBySectionID: contentBySectionID)

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if let title = homePage.title {
                    Text(title)
                        .font(.largeTitle.bold())
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                ForEach(sections) { section in
                    registry.view(for: section)
                }
            }
            .padding(.bottom, 24)
        }
        .background(HomeUIColor.groupedBackground)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )
    }
}
#endif
