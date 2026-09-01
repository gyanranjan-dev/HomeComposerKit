import SwiftUI

/// Banner section driven by presentation configuration.
public struct BannerSectionView: View {
    let section: ComposedHomeSection

    @Environment(\.homeActionHandler) private var actionHandler
    @Environment(\.homeComposerTheme) private var theme

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

            if banners.isEmpty {
                emptyPlaceholder
            } else {
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
                    .frame(height: 200)
            } else {
                HomeSectionItemsLayoutView(
                    layout: .carousel,
                    spacing: section.effectiveSpacing,
                    columns: 1,
                    items: banners,
                    carouselHeight: 200
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
                    .frame(width: 480, height: 200)
            }
            .frame(height: 200)
        case .vertical:
            HomeSectionItemsLayoutView(
                layout: .vertical,
                spacing: section.effectiveSpacing,
                columns: 1,
                items: banners
            ) { banner in
                bannerCard(banner)
                    .frame(height: 200)
            }
        case .grid:
            HomeSectionItemsLayoutView(
                layout: .grid,
                spacing: section.effectiveSpacing,
                columns: section.effectiveColumns(default: 1),
                items: banners
            ) { banner in
                bannerCard(banner)
                    .frame(height: 160)
            }
        case .unknown:
            HomeSectionItemsLayoutView(
                layout: .carousel,
                spacing: section.effectiveSpacing,
                columns: 1,
                items: banners,
                carouselHeight: 200
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
            .accessibilityLabel(Text(accessibilityLabel(for: banner)))
            .accessibilityAddTraits(.isButton)
        } else {
            card
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(accessibilityLabel(for: banner)))
        }
    }

    private func bannerCardContent(_ banner: Banner) -> some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImageView(url: banner.imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: theme.spacing.compact + 2) {
                if let title = banner.title {
                    Text(title)
                        .font(theme.typography.sectionTitle)
                        .foregroundStyle(.white)
                }
                if let subtitle = banner.subtitle {
                    Text(subtitle)
                        .font(theme.typography.body)
                        .foregroundStyle(.white.opacity(0.9))
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
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: theme.cornerRadius.large,
                style: .continuous
            )
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }

    private func accessibilityLabel(for banner: Banner) -> String {
        [banner.title, banner.subtitle, banner.action?.title]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private var emptyPlaceholder: some View {
        RoundedRectangle(
            cornerRadius: theme.cornerRadius.large,
            style: .continuous
        )
            .fill(theme.placeholderBackgroundColor)
            .frame(height: 160)
            .overlay {
                Text("No banners")
                    .font(theme.typography.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, theme.horizontalContentPadding)
            .accessibilityLabel("No banners available")
    }
}
