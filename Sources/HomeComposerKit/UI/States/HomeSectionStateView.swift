import SwiftUI

/// Generic state-aware section wrapper for built-in and custom sections.
///
/// When the host supplies an explicit ``HomeSectionState`` for `sectionID`,
/// this view renders loading, empty, or error presentation. Otherwise the
/// supplied content view is shown unchanged, preserving legacy behavior.
public struct HomeSectionStateView<Content: View>: View {

    public let sectionID: String
    public let sectionType: HomeSectionType
    public let sectionTitle: String?
    @ViewBuilder public let content: () -> Content

    @Environment(\.homeSectionStates) private var sectionStates
    @Environment(\.homeSectionStateConfiguration) private var stateConfiguration
    @Environment(\.homeComposerTheme) private var theme

    public init(
        sectionID: String,
        sectionType: HomeSectionType,
        sectionTitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.sectionID = sectionID
        self.sectionType = sectionType
        self.sectionTitle = sectionTitle
        self.content = content
    }

    public var body: some View {
        if let state = sectionStates[sectionID] {
            explicitStateView(state)
        } else {
            content()
        }
    }

    @ViewBuilder
    private func explicitStateView(_ state: HomeSectionState) -> some View {
        switch state {
        case .loading:
            loadingView
        case .loaded:
            content()
        case .empty:
            emptyView
        case .failed(let failure):
            errorView(failure)
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        let loading = stateConfiguration.loadingConfiguration(for: sectionType)

        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            switch loading.style {
            case .banner:
                BannerSectionSkeleton()
            case .horizontal(let itemCount):
                HorizontalSectionSkeleton(itemCount: itemCount, showsTitle: sectionTitle != nil)
            case .grid(let columns, let itemCount):
                GridSectionSkeleton(columns: columns, itemCount: itemCount, showsTitle: sectionTitle != nil)
            case .productCard:
                ProductCardSkeleton()
                    .padding(.horizontal, theme.horizontalContentPadding)
            }
        }
    }

    private var emptyView: some View {
        HomeSectionEmptyStateView(
            configuration: stateConfiguration.emptyConfiguration(for: sectionType)
        )
    }

    private func errorView(_ failure: HomeSectionFailure) -> some View {
        HomeSectionErrorStateView(
            configuration: stateConfiguration.errorConfiguration(forSectionID: sectionID),
            failure: failure
        )
    }
}
