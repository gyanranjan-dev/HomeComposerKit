import SwiftUI

/// Banner section driven by presentation configuration.
public struct BannerSectionView: View {
    let section: ComposedHomeSection

    @Environment(\.homeActionHandler) private var actionHandler
    @Environment(\.homeComposerTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var banners: [Banner] {
        guard case .banner(let payload) = section.content else { return [] }
        let items = payload.banners
        if let limit = section.configuration?.limit {
            return Array(items.prefix(limit))
        }
        return items
    }

    private var bannerHeight: CGFloat {
        HomeAdaptiveLayout.bannerHeight(dynamicTypeSize: dynamicTypeSize)
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
                isEmpty: banners.isEmpty,
                sectionType: section.type
            ) {
                bannerContent
            }
        }
    }

    @ViewBuilder
    private var bannerContent: some View {
        switch section.effectiveLayout {
        case .carousel:
            if banners.count == 1, let banner = banners.first {
                bannerCard(banner)
                    .padding(.horizontal, theme.horizontalContentPadding)
                    .frame(minHeight: bannerHeight)
            } else {
                HomeSectionItemsLayoutView(
                    layout: .carousel,
                    spacing: section.effectiveSpacing,
                    columns: 1,
                    items: banners,
                    carouselHeight: bannerHeight
                ) { banner in
                    bannerCard(banner)
                }
            }
        case .horizontal:
            HomeSectionItemsLayoutView(
                layout: .horizontal,
                spacing: section.effectiveSpacing,
                columns: 1,
                items: banners
            ) { banner in
                bannerCard(banner)
                    .frame(minHeight: bannerHeight)
            }
            .frame(minHeight: bannerHeight)
        case .vertical:
            HomeSectionItemsLayoutView(
                layout: .vertical,
                spacing: section.effectiveSpacing,
                columns: 1,
                items: banners
            ) { banner in
                bannerCard(banner)
                    .frame(minHeight: bannerHeight)
            }
        case .grid:
            HomeSectionItemsLayoutView(
                layout: .grid,
                spacing: section.effectiveSpacing,
                configuredColumns: section.configuredGridColumns,
                defaultColumns: 1,
                items: banners
            ) { banner in
                bannerCard(banner)
                    .frame(minHeight: bannerHeight * 0.8)
            }
        case .unknown:
            HomeSectionItemsLayoutView(
                layout: .carousel,
                spacing: section.effectiveSpacing,
                columns: 1,
                items: banners,
                carouselHeight: bannerHeight
            ) { banner in
                bannerCard(banner)
            }
        }
    }

    @ViewBuilder
    private func bannerCard(_ banner: Banner) -> some View {
        let card = bannerCardContent(banner)

        if let action = HomeAction.from(banner: banner) {
            Button {
                actionHandler.handle(action)
            } label: {
                card
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(HomeAccessibilityLabels.banner(banner)))
            .accessibilityHint("Opens banner action")
            .accessibilityAddTraits(.isButton)
        } else {
            card
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(HomeAccessibilityLabels.banner(banner)))
        }
    }

    private func bannerCardContent(_ banner: Banner) -> some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImageView(url: banner.imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: theme.spacing.compact + 2) {
                if let title = banner.title {
                    Text(title)
                        .font(theme.typography.sectionTitle)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let subtitle = banner.subtitle {
                    Text(subtitle)
                        .font(theme.typography.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let actionTitle = banner.action?.title {
                    Text(actionTitle)
                        .font(theme.typography.caption.weight(.semibold))
                        .padding(.horizontal, theme.spacing.medium)
                        .padding(.vertical, theme.spacing.compact + 2)
                        .background(.white.opacity(0.92))
                        .foregroundStyle(.primary)
                        .clipShape(Capsule())
                        .padding(.top, 2)
                        .accessibilityHidden(true)
                }
            }
            .padding(theme.spacing.large)
            .accessibilityHidden(true)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: theme.cornerRadius.large,
                style: .continuous
            )
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}
