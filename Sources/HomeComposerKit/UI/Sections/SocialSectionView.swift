import SwiftUI

/// Social content section using a clean card layout. No social API integration.
public struct SocialSectionView: View {
    let section: ComposedHomeSection

    @Environment(\.homeActionHandler) private var actionHandler
    @Environment(\.homeComposerTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var posts: [SocialPost] {
        guard case .social(let payload) = section.content else { return [] }
        let items = payload.posts
        if let limit = section.configuration?.limit {
            return Array(items.prefix(limit))
        }
        return items
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: section.effectiveSpacing) {
            HomeSectionHeaderView(
                title: section.title,
                showTitle: section.effectiveShowTitle,
                showSeeAll: section.effectiveShowSeeAll,
                onSeeAll: section.effectiveShowSeeAll
                    ? { actionHandler.handle(.section(id: section.id)) }
                    : nil
            )

            HomeSectionBuiltInContent.emptyOrContent(
                isEmpty: posts.isEmpty,
                sectionType: section.type
            ) {
                HomeSectionItemsLayoutView(
                    layout: section.effectiveLayout,
                    spacing: section.effectiveSpacing,
                    configuredColumns: section.configuredGridColumns,
                    defaultColumns: 2,
                    items: posts,
                    carouselHeight: 220
                ) { post in
                    socialCard(post)
                }
            }
        }
    }

    private func socialCard(_ post: SocialPost) -> some View {
        VStack(alignment: .leading, spacing: theme.cardSpacing) {
            RemoteImageView(url: post.imageURL)
                .aspectRatio(4 / 3, contentMode: .fill)
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 160)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: theme.cornerRadius.small,
                        style: .continuous
                    )
                )
                .accessibilityHidden(true)

            Text(post.author)
                .font(theme.typography.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let content = post.content {
                Text(content)
                    .font(theme.typography.body)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(theme.cardPadding)
        .background(theme.cardBackgroundColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: theme.cornerRadius.medium,
                style: .continuous
            )
        )
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(HomeAccessibilityLabels.socialPost(post)))
    }
}
